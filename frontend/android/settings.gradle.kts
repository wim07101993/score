pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Pinned to the 8 line of the Android Gradle Plugin, and not because anything
// here needs an older one.
//
// AGP 9 compiles Kotlin itself, and a plugin is meant to stop bringing its own
// compiler when it sees one. `file_picker` does that; `flutter_web_auth_2` does
// not, and applies the Kotlin plugin whatever it is built against. Under AGP 9
// there is no arrangement that suits both: turn the built-in compiler on and
// the second plugin collides with it, turn it off and the first one's Kotlin is
// never compiled at all.
//
// Under AGP 8 there is no built-in compiler to disagree about, both plugins
// bring their own, and both build. This goes back to 9 when
// `flutter_web_auth_2` learns to stand aside — see the README.
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
