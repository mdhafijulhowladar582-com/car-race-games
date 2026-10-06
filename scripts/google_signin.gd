extends RefCounted

signal sign_in_success(id_token: String, display_name: String, email: String)
signal sign_in_failed(message: String)
signal signed_out

const PLUGIN_NAME := "FirebaseGoogleSignIn"

var plugin: Object

func _init() -> void:
    if Engine.has_singleton(PLUGIN_NAME):
        plugin = Engine.get_singleton(PLUGIN_NAME)
        plugin.google_sign_in_success.connect(_on_success)
        plugin.google_sign_in_failed.connect(_on_failed)
        plugin.google_sign_out_complete.connect(_on_signed_out)

func is_available() -> bool:
    return plugin != null

func sign_in() -> void:
    if plugin:
        plugin.signIn()
    else:
        sign_in_failed.emit("Google Sign-In is available only in the Android build.")

func sign_out() -> void:
    if plugin:
        plugin.signOut()
    else:
        sign_in_failed.emit("Google Sign-In is unavailable.")

func _on_success(id_token: String, display_name: String, email: String) -> void:
    sign_in_success.emit(id_token, display_name, email)

func _on_failed(message: String) -> void:
    sign_in_failed.emit(message)

func _on_signed_out() -> void:
    signed_out.emit()
