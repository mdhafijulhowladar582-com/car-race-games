@tool
extends EditorPlugin

var export_plugin: FirebaseGoogleSignInExport

func _enter_tree() -> void:
    export_plugin = FirebaseGoogleSignInExport.new()
    add_export_plugin(export_plugin)

func _exit_tree() -> void:
    if export_plugin:
        remove_export_plugin(export_plugin)
        export_plugin = null

class FirebaseGoogleSignInExport extends EditorExportPlugin:
    var plugin_name := "FirebaseGoogleSignIn"

    func _supports_platform(platform: EditorExportPlatform) -> bool:
        return platform is EditorExportPlatformAndroid

    func _get_name() -> String:
        return plugin_name

    func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        if debug:
            return PackedStringArray(["res://addons/firebase_google_signin/bin/debug/FirebaseGoogleSignIn-debug.aar"])
        return PackedStringArray(["res://addons/firebase_google_signin/bin/release/FirebaseGoogleSignIn-release.aar"])

    func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        return PackedStringArray(["com.google.android.gms:play-services-auth:21.4.0"])
