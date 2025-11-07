plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Add this configuration for the wear plugin
subprojects {
    afterEvaluate {
        if (project.name == "wear") {
            configure<com.android.build.gradle.LibraryExtension> {
                namespace = "dev.flutter.plugins.wear"
            }
        }
    }
}

android {
    namespace = "com.example.drinkup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.drinkup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


// Configure the wearApp build type
android {
    buildTypes {
        getByName("debug") {
            // Ensure the wear module has the correct namespace
            project.afterEvaluate {
                project(":wear").afterEvaluate {
                    extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                        namespace = "dev.flutter.plugins.wear"
                        compileSdk = 33
                        defaultConfig {
                            minSdk = 23
                            targetSdk = 33
                        }
                    }
                }
            }
        }
    }
}

dependencies {
    implementation("androidx.wear:wear:1.3.0")
    implementation("com.google.android.support:wearable:2.9.0")
    compileOnly("com.google.android.wearable:wearable:2.9.0")
}

flutter {
    source = "../.."
}
