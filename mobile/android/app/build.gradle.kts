import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The one place the store's facts live (mobile/brand.yaml).
val brand: Map<String, String> =
    rootProject.file("../brand.yaml").readLines()
        .filter { it.matches(Regex("""^\w+: .+""")) }
        .associate { it.substringBefore(":") to it.substringAfter(":").trim().trim('"') }

// The upload key stays outside the repository. Without it a release is signed for testing only.
val keys = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use(::load)
}

android {
    namespace = "tz.mfano.news_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = brand.getValue("android_id")
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "${brand.getValue("name")} Dev"
            manifestPlaceholders["webHost"] = brand.getValue("host_dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            manifestPlaceholders["appName"] = "${brand.getValue("name")} Staging"
            manifestPlaceholders["webHost"] = brand.getValue("host_staging")
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appName"] = brand.getValue("name")
            manifestPlaceholders["webHost"] = brand.getValue("host_prod")
        }
    }

    signingConfigs {
        if (keys.containsKey("storeFile")) {
            create("upload") {
                storeFile = file(keys.getProperty("storeFile"))
                storePassword = keys.getProperty("storePassword")
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
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
