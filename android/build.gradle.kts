buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Required for Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.2.0") // Use your current Android Gradle Plugin version
        // Required for Kotlin Gradle Plugin (if using Kotlin)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0") // Use your current Kotlin version
        // ⭐ REQUIRED FOR GOOGLE SERVICES (FIREBASE) ⭐
        classpath("com.google.gms:google-services:4.4.4") // ⭐ USE THE LATEST VERSION ⭐
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Task to create a new keystore
tasks.register<Exec>("createKeystore") {
    group = "build"
    description = "Creates a new Android keystore for app signing"
    
    val keystoreFile = file("../../junction_new.jks")
    val keyAlias = "junction_key"
    val storePassword = "junction123"
    val keyPassword = "junction123"
    
    // Try to find keytool
    val keytoolPath = System.getenv("JAVA_HOME")?.let { 
        file("$it/bin/keytool").takeIf { it.exists() }?.absolutePath
    } ?: "keytool"
    
    commandLine(
        keytoolPath,
        "-genkey",
        "-v",
        "-keystore", keystoreFile.absolutePath,
        "-alias", keyAlias,
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", "10000",
        "-storepass", storePassword,
        "-keypass", keyPassword,
        "-dname", "CN=Junction, OU=Development, O=Junction, L=City, ST=State, C=US"
    )
    
    doLast {
        // Create key.properties file
        val keyPropertiesFile = file("key.properties")
        keyPropertiesFile.writeText("""
storeFile=../../junction_new.jks
keyAlias=$keyAlias
storePassword=$storePassword
keyPassword=$keyPassword
""".trimIndent())
        
        println("✅ Keystore created: ${keystoreFile.absolutePath}")
        println("✅ key.properties created")
        println("⚠️  IMPORTANT: Save these credentials securely!")
    }
}
