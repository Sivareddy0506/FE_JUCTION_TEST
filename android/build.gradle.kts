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
