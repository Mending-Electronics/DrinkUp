allprojects {
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            // This will be applied to all Android library modules, including the Wear plugin
            namespace = "dev.flutter.plugins.wear"
        }
    }
}
