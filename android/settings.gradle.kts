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

// Include the wear module
val userHome = System.getProperty("user.home")
val wearPluginPath = "$userHome/.pub-cache/hosted/pub.dev/wear-1.1.0/android"
include(":wear")
project(":wear").projectDir = file(wearPluginPath)

// Apply the patch to the wear module using a different approach
gradle.projectsLoaded {
    rootProject.childProjects["wear"]?.afterEvaluate {
        apply(from = "${'$'}{rootProject.projectDir}/wear-patch.gradle")
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
include(":wear")
