plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
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

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val keyAliasValue = keystoreProperties["keyAlias"] as String?
                val keyPasswordValue = keystoreProperties["keyPassword"] as String?
                val storeFileValue = keystoreProperties["storeFile"] as String?
                val storePasswordValue = keystoreProperties["storePassword"] as String?
                
                if (keyAliasValue != null && keyPasswordValue != null && 
                    storeFileValue != null && storePasswordValue != null) {
                    keyAlias = keyAliasValue
                    keyPassword = keyPasswordValue
                    // Resolve storeFile: storeFileValue is relative to android/app/ directory
                    // ../../junction.jks means: up from app/ to android/, then up to project root
                    val keystoreFile = file(storeFileValue)
                    // Verify file exists for better error message
                    if (!keystoreFile.exists()) {
                        throw GradleException("Keystore file not found: ${keystoreFile.absolutePath}\n" +
                            "Looking for: ${storeFileValue}\n" +
                            "Resolved to: ${keystoreFile.absolutePath}\n" +
                            "Project root: ${rootProject.projectDir.parentFile.absolutePath}\n" +
                            "Expected at: ${java.io.File(rootProject.projectDir.parentFile, "junction.jks").absolutePath}")
                    }
                    storeFile = keystoreFile
                    storePassword = storePasswordValue
                }
            }
        }
    }

    buildTypes {
        getByName("release") {
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig != null && releaseSigningConfig.storeFile != null) {
                signingConfig = releaseSigningConfig
            }
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
