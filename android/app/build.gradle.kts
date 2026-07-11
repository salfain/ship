import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localEnv = Properties().apply {
    val envFile = rootProject.file("../.env")
    if (envFile.exists()) {
        envFile.inputStream().use { stream -> load(stream) }
    }
}

val keystoreProperties = Properties().apply {
    val keyPropertiesFile = rootProject.file("key.properties")
    if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use { stream -> load(stream) }
    }
}
val hasReleaseSigning = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
).all { keystoreProperties.getProperty(it)?.isNotBlank() == true }

android {
    namespace = "id.ksop.shipmonitoring"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    val mapsApiKey = (project.findProperty("MAPS_API_KEY") as String?)
        ?.takeIf { it.isNotBlank() }
        ?: localEnv.getProperty("GOOGLE_MAPS_API_KEY", "")
    val debugMapsApiKey = (project.findProperty("MAPS_API_DEBUG_KEY") as String?)
        ?.takeIf { it.isNotBlank() }
        ?: localEnv.getProperty("GOOGLE_MAPS_ANDROID_DEBUG_KEY", mapsApiKey)
    val releaseMapsApiKey = (project.findProperty("MAPS_API_RELEASE_KEY") as String?)
        ?.takeIf { it.isNotBlank() }
        ?: localEnv.getProperty("GOOGLE_MAPS_ANDROID_RELEASE_KEY", mapsApiKey)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "id.ksop.shipmonitoring"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["MAPS_API_KEY"] = debugMapsApiKey
        }
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            manifestPlaceholders["MAPS_API_KEY"] = releaseMapsApiKey
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
