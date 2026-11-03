import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties().apply {
    if (releaseKeyPropertiesFile.exists()) {
        releaseKeyPropertiesFile.inputStream().use(::load)
    }
}
val releaseStoreFile = releaseKeyProperties.getProperty("storeFile")
val releaseSigningConfigured =
    !releaseKeyProperties.getProperty("keyAlias").isNullOrBlank() &&
        !releaseKeyProperties.getProperty("keyPassword").isNullOrBlank() &&
        !releaseKeyProperties.getProperty("storePassword").isNullOrBlank() &&
        !releaseStoreFile.isNullOrBlank() &&
        rootProject.file(releaseStoreFile).isFile

android {
    namespace = "com.geda.urjavatika.urja"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = releaseKeyProperties.getProperty("keyAlias")
                keyPassword = releaseKeyProperties.getProperty("keyPassword")
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseKeyProperties.getProperty("storePassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.geda.urjavatika.urja"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseArtifactRequested = allTasks.any {
        it.name == "assembleRelease" || it.name == "bundleRelease"
    }
    if (releaseArtifactRequested && !releaseSigningConfigured) {
        throw GradleException(
            "Release signing is not configured. Create mobile/android/key.properties " +
                "with valid keystore details before building a release APK or AAB.",
        )
    }
}

flutter {
    source = "../.."
}
