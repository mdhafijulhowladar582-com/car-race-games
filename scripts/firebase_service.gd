extends Node

signal leaderboard_loaded(entries: Array)
signal leaderboard_failed(message: String)

const FIREBASE_PROJECT_ID := "carres-8d409"
const FIRESTORE_BASE_URL := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % FIREBASE_PROJECT_ID
const LEADERBOARD_PATH := "/leaderboard"

var http: HTTPRequest
var id_token := ""

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

func load_public_leaderboard() -> void:
    if not http:
        leaderboard_failed.emit("Firebase HTTP service is not ready.")
        return

    var url := FIRESTORE_BASE_URL + LEADERBOARD_PATH
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
