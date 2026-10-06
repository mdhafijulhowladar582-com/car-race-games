@tool
extends EditorPlugin

class FirebaseGoogleSignInExport extends EditorExportPlugin:
    var plugin_name := "FirebaseGoogleSignIn"

    func _supports_platform(platform: EditorExportPlatform) -> bool:
        return platform is EditorExportPlatformAndroid

    func _get_name() -> String:
        return plugin_name

    func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        if debug:
            return PackedStringArray(["firebase_google_signin/bin/debug/FirebaseGoogleSignIn-debug.aar"])
        return PackedStringArray(["firebase_google_signin/bin/release/FirebaseGoogleSignIn-release.aar"])

    func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
        return PackedStringArray(["com.google.android.gms:play-services-auth:21.4.0"])
