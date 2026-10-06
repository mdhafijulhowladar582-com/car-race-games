plugins {
    id("com.android.library")
}

val pluginName = "FirebaseGoogleSignIn"
val pluginPackageName = "com.hafijulnovalabs.firebasegooglesignin"

android {
    namespace = pluginPackageName
    compileSdk = 35

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = pluginName
        manifestPlaceholders["godotPluginPackageName"] = pluginPackageName
        buildConfigField("String", "GODOT_PLUGIN_NAME", "\"$pluginName\"")
        setProperty("archivesBaseName", pluginName)
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("org.godotengine:godot:4.7.0.stable")
    compileOnly("com.google.android.gms:play-services-auth:21.4.0")
}

tasks.register<Copy>("copyAarToProject") {
    from(layout.buildDirectory.dir("outputs/aar"))
    include("FirebaseGoogleSignIn-debug.aar", "FirebaseGoogleSignIn-release.aar")
    into(layout.projectDirectory.dir("../addons/firebase_google_signin/bin"))
}

tasks.named("assemble") {
    finalizedBy("copyAarToProject")
}
