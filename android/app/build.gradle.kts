plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.credit_cards"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.geo.credit_cards"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Ship only English resources; drops ~100 unused Material translation strings.
        resourceConfigurations += listOf("en")
    }

    buildTypes {
        release {
            // TODO: Replace debug signing with a real upload keystore before publishing.
            signingConfig = signingConfigs.getByName("debug")

            // R8 code shrinking + resource shrinking.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Use the UNBUNDLED ML Kit text-recognition (Latin): the ~16 MB native OCR
// engine is delivered by Google Play Services at runtime instead of being
// packaged in the APK. The other scripts are compileOnly, so they add no size.
configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "com.google.mlkit" && requested.name == "text-recognition") {
            useTarget("com.google.android.gms:play-services-mlkit-text-recognition:19.0.0")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
