plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.junction"
    compileSdk = 36

  defaultConfig {
    applicationId = "com.junction"
    minSdk = 23        // ✅ Kotlin DSL syntax
    targetSdk = 34     // ✅ Kotlin DSL syntax
    versionCode = 30
    versionName = "1.0.3"
    multiDexEnabled = true
}
configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.google.firebase") {
                println("Forcing minSdk 23 for Firebase")
            }
        }
    }


    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true // Allowed because minify is enabled
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false // Avoids your current error
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.android.support:multidex:1.0.3")
}
