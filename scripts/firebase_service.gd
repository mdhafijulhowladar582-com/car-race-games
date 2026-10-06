extends Node

signal leaderboard_loaded(entries: Array)
signal leaderboard_failed(message: String)
signal auth_changed(authenticated: bool, display_name: String)
signal auth_failed(message: String)
signal score_saved
signal score_failed(message: String)
signal rank_loaded(rank: int)
signal rank_failed(message: String)

const FIREBASE_PROJECT_ID := "carres-8d409"
const FIRESTORE_BASE_URL := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % FIREBASE_PROJECT_ID
const LEADERBOARD_PATH := "/leaderboard"
const FIREBASE_API_KEY := "AIzaSyAhvuZL5GDJuq3NedLMAGPt7XujpZRow"
const AUTH_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=%s" % FIREBASE_API_KEY

var http: HTTPRequest
var id_token := ""
var refresh_token := ""
var user_id := ""
var display_name := ""
var last_submitted_time := 0.0

func _ready() -> void:
    http = HTTPRequest.new()
    http.name = "FirebaseHTTP"
    add_child(http)
    http.request_completed.connect(_on_request_completed)

func set_id_token(token: String) -> void:
    id_token = token.strip_edges()

func clear_id_token() -> void:
    id_token = ""

func is_authenticated() -> bool:
    return not id_token.is_empty()

func continue_as_guest() -> void:
    sign_out()

func sign_in_with_google_id_token(google_id_token: String) -> void:
    var token := google_id_token.strip_edges()
    if token.is_empty():
        auth_failed.emit("Google ID token is empty.")
        return

    var auth_http := HTTPRequest.new()
    auth_http.name = "FirebaseAuthHTTP"
    add_child(auth_http)
    auth_http.request_completed.connect(_on_google_auth_completed.bind(auth_http))

    var headers := PackedStringArray(["Content-Type: application/json"])
    var payload := {
        "postBody": "id_token=%s&providerId=google.com" % token.uri_encode(),
        "requestUri": "https://localhost",
        "returnIdpCredential": true,
        "returnSecureToken": true
    }
    var error := auth_http.request(AUTH_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if error != OK:
        auth_failed.emit("Firebase Authentication request could not start.")
        auth_http.queue_free()

func sign_out() -> void:
    id_token = ""
    refresh_token = ""
    user_id = ""
    display_name = ""
    auth_changed.emit(false, "")

func _on_google_auth_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, auth_http: HTTPRequest) -> void:
    var response = JSON.parse_string(body.get_string_from_utf8())
    auth_http.queue_free()

    if result != HTTPRequest.RESULT_SUCCESS:
        auth_failed.emit("Firebase Authentication network connection failed.")
        return

    if response_code < 200 or response_code >= 300 or not (response is Dictionary):
        var message := "Firebase Authentication failed (%d)." % response_code
        if response is Dictionary and response.has("error"):
            var error_data: Dictionary = response["error"]
            if error_data.has("message"):
                message = str(error_data["message"])
        auth_failed.emit(message)
        return

    id_token = str(response.get("idToken", ""))
    refresh_token = str(response.get("refreshToken", ""))
    user_id = str(response.get("localId", ""))
    display_name = str(response.get("displayName", ""))
    if id_token.is_empty() or user_id.is_empty():
        auth_failed.emit("Firebase Authentication returned incomplete credentials.")
        return

    auth_changed.emit(true, display_name)

func save_best_score(race_time: float, map_name: String, car_name: String) -> void:
    if not is_authenticated() or user_id.is_empty():
        score_failed.emit("Guest mode: online score upload is disabled.")
        return
    if race_time < 3.0 or race_time > 3600.0:
        score_failed.emit("Race time is outside the allowed range.")
        return

    last_submitted_time = race_time
    var url := FIRESTORE_BASE_URL + LEADERBOARD_PATH + "/" + user_id.uri_encode()
    var headers := PackedStringArray([
        "Accept: application/json",
        "Authorization: Bearer " + id_token
    ])
    var request := HTTPRequest.new()
    request.name = "FirebaseScoreRead"
    add_child(request)
    request.request_completed.connect(_on_score_read_completed.bind(request, race_time, map_name, car_name))
    var error := request.request(url, headers, HTTPClient.METHOD_GET)
    if error != OK:
        request.queue_free()
        score_failed.emit("Could not start score check.")

func _on_score_read_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest, race_time: float, map_name: String, car_name: String) -> void:
    request.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS:
        score_failed.emit("Firebase score check failed.")
        return

    var existing_time := INF
    var update_time := ""
    if response_code >= 200 and response_code < 300:
        var data = JSON.parse_string(body.get_string_from_utf8())
        if data is Dictionary:
            var fields: Dictionary = data.get("fields", {})
            existing_time = _field_number(fields, "time", INF)
            update_time = str(data.get("updateTime", ""))
    elif response_code != 404:
        score_failed.emit("Firebase score check failed (%d)." % response_code)
        return

    if race_time >= existing_time:
        last_best_time = existing_time
        score_saved.emit()
        return

    _commit_best_score(race_time, map_name, car_name, update_time)

func _commit_best_score(race_time: float, map_name: String, car_name: String, update_time: String) -> void:
    var headers := PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + id_token
    ])
    var write := {
        "update": {
            "name": "projects/%s/databases/(default)/documents/leaderboard/%s" % [FIREBASE_PROJECT_ID, user_id],
            "fields": {
                "userId": {"stringValue": user_id},
                "name": {"stringValue": display_name if not display_name.is_empty() else "Player"},
                "time": {"doubleValue": race_time},
                "map": {"stringValue": map_name},
                "car": {"stringValue": car_name}
            }
        },
        "updateTransforms": [{
            "fieldPath": "timestamp",
            "setToServerValue": "REQUEST_TIME"
        }]
    }
    if update_time.is_empty():
        write["currentDocument"] = {"exists": false}
    else:
        write["currentDocument"] = {"updateTime": update_time}

    var commit_url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:commit" % FIREBASE_PROJECT_ID
    var request := HTTPRequest.new()
    request.name = "FirebaseScoreCommit"
    add_child(request)
    request.request_completed.connect(_on_score_commit_completed.bind(request, race_time, map_name, car_name))
    var error := request.request(commit_url, headers, HTTPClient.METHOD_POST, JSON.stringify({"writes": [write]}))
    if error != OK:
        request.queue_free()
        score_failed.emit("Could not start atomic score upload.")

func _on_score_commit_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest, race_time: float, map_name: String, car_name: String) -> void:
    request.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS:
        score_failed.emit("Firebase score upload failed.")
        return
    if response_code >= 200 and response_code < 300:
        last_best_time = race_time
        score_saved.emit()
        return

    var data = JSON.parse_string(body.get_string_from_utf8())
    if response_code == 409 or response_code == 400:
        _retry_score_after_conflict(race_time, map_name, car_name)
        return

    var message := "Firebase score upload failed (%d)." % response_code
    if data is Dictionary and data.has("error") and data["error"] is Dictionary and data["error"].has("message"):
        message = str(data["error"]["message"])
    score_failed.emit(message)

func _retry_score_after_conflict(race_time: float, map_name: String, car_name: String) -> void:
    var headers := PackedStringArray([
        "Accept: application/json",
        "Authorization: Bearer " + id_token
    ])
    var request := HTTPRequest.new()
    request.name = "FirebaseScoreRetryRead"
    add_child(request)
    request.request_completed.connect(_on_score_retry_read_completed.bind(request, race_time, map_name, car_name))
    var url := FIRESTORE_BASE_URL + LEADERBOARD_PATH + "/" + user_id.uri_encode()
    var error := request.request(url, headers, HTTPClient.METHOD_GET)
    if error != OK:
        request.queue_free()
        score_failed.emit("Could not retry atomic score upload.")

func _on_score_retry_read_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest, race_time: float, map_name: String, car_name: String) -> void:
    request.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS:
        score_failed.emit("Firebase score retry check failed.")
        return

    if response_code == 404:
        _commit_best_score(race_time, map_name, car_name, "")
        return
    if response_code < 200 or response_code >= 300:
        score_failed.emit("Firebase score retry check failed (%d)." % response_code)
        return

    var data = JSON.parse_string(body.get_string_from_utf8())
    if not (data is Dictionary):
        score_failed.emit("Firebase returned invalid score data.")
        return

    var current_time := _field_number(data.get("fields", {}), "time", INF)
    var update_time := str(data.get("updateTime", ""))
    if race_time < current_time:
        _commit_best_score(race_time, map_name, car_name, update_time)
        return

    last_best_time = current_time
    score_saved.emit()

func load_public_leaderboard() -> void:
    if not http:
        leaderboard_failed.emit("Firebase HTTP service is not ready.")
        return

    var url := FIRESTORE_BASE_URL + LEADERBOARD_PATH + "?pageSize=100&orderBy=time"
    var headers := PackedStringArray(["Accept: application/json"])
    if not id_token.is_empty():
        headers.append("Authorization: Bearer " + id_token)

    var error := http.request(url, headers, HTTPClient.METHOD_GET)
    if error != OK:
        leaderboard_failed.emit("Firebase request could not start.")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        leaderboard_failed.emit("Firebase network connection failed.")
        return

    var text_body := body.get_string_from_utf8()
    var json := JSON.new()
    if json.parse(text_body) != OK:
        leaderboard_failed.emit("Firebase returned invalid JSON.")
        return

    if response_code < 200 or response_code >= 300:
        var message := "Firebase request failed (%d)." % response_code
        if json.data is Dictionary and json.data.has("error"):
            var error_data: Dictionary = json.data["error"]
            if error_data.has("message"):
                message = str(error_data["message"])
        leaderboard_failed.emit(message)
        return

    if not (json.data is Dictionary):
        leaderboard_failed.emit("Firebase returned an unexpected response.")
        return

    var documents: Array = json.data.get("documents", [])
    var entries: Array = []
    for document in documents:
        if not (document is Dictionary):
            continue
        var fields: Dictionary = document.get("fields", {})
        if not (fields is Dictionary):
            continue
        var entry := {
            "name": _field_string(fields, "name", "Player"),
            "time": _field_number(fields, "time", 0.0),
            "map": _field_string(fields, "map", "CITY"),
            "car": _field_string(fields, "car", "SPORTS"),
            "userId": _field_string(fields, "userId", "")
        }
        if float(entry["time"]) > 0.0:
            entries.append(entry)

    entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["time"]) < float(b["time"])
    )
    leaderboard_loaded.emit(entries)

func _field_string(fields: Dictionary, key: String, fallback: String) -> String:
    if not fields.has(key) or not (fields[key] is Dictionary):
        return fallback
    var value: Dictionary = fields[key]
    if value.has("stringValue"):
        return str(value["stringValue"])
    return fallback

func _field_number(fields: Dictionary, key: String, fallback: float) -> float:
    if not fields.has(key) or not (fields[key] is Dictionary):
        return fallback
    var value: Dictionary = fields[key]
    if value.has("doubleValue"):
        return float(value["doubleValue"])
    if value.has("integerValue"):
        return float(value["integerValue"])
    return fallback
