plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "it.pietrodefilippis.tkpietro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // le notifiche locali usano le API java.time anche sui telefoni vecchi
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "it.pietrodefilippis.tkpietro"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // chiave delle app TK, FUORI dal repo: in CI arriva dal segreto ANDROID_KEYSTORE_B64 (percorso nella variabile
    // ANDROID_KEYSTORE). Senza la variabile (rami senza segreto, chi compila dal sorgente) = chiave di debug di Flutter.
    val chiaveTk = System.getenv("ANDROID_KEYSTORE")?.takeIf { it.isNotBlank() && file(it).exists() }
    signingConfigs {
        if (chiaveTk != null) {
            create("tk") {
                storeFile = file(chiaveTk)
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("tk") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
