import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Applied below only when google-services.json is present (gitignored; copy from *.example).
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
}

// Real Firebase config stays out of git. Local/CI provide the file via *.example copy or secrets.
val googleServicesJson = file("google-services.json")
if (googleServicesJson.exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

// Release signing uses android/key.properties only. Never fall back to debug keys.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireKeystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)
        ?: throw org.gradle.api.GradleException("Missing '$name' in android/key.properties for release signing.")

// Meta SDK: env (CI) ou android/local.properties (gitignored). "0" mantém o SDK
// inicializado sem enviar nada — sem App ID o plugin derruba o app na abertura.
val localProperties = Properties()
rootProject.file("local.properties").takeIf { it.exists() }?.let {
    localProperties.load(FileInputStream(it))
}
fun metaConfig(env: String, local: String): String =
    System.getenv(env)?.takeIf { it.isNotBlank() }
        ?: localProperties.getProperty(local)?.takeIf { it.isNotBlank() }
        ?: "0"
val facebookAppId = metaConfig("FACEBOOK_APP_ID", "facebook.appId")
val facebookClientToken = metaConfig("FACEBOOK_CLIENT_TOKEN", "facebook.clientToken")

// Intercom: env (CI) ou android/local.properties (gitignored). Vazio deixa o debug
// subir sem Intercom; o build de release exige as duas chaves (ver tasks abaixo).
fun intercomConfig(env: String, local: String): String =
    System.getenv(env)?.takeIf { it.isNotBlank() }
        ?: localProperties.getProperty(local)?.takeIf { it.isNotBlank() }
        ?: ""
val intercomAppId = intercomConfig("INTERCOM_APP_ID", "intercom.appId")
val intercomAndroidApiKey = intercomConfig("INTERCOM_ANDROID_API_KEY", "intercom.androidApiKey")

android {
    namespace = "com.focux.focux_app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = requireKeystoreProperty("keyAlias")
                keyPassword = requireKeystoreProperty("keyPassword")
                storeFile = file(requireKeystoreProperty("storeFile"))
                storePassword = requireKeystoreProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.focux.focux_app"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        buildConfigField("String", "INTERCOM_APP_ID", "\"$intercomAppId\"")
        buildConfigField("String", "INTERCOM_ANDROID_API_KEY", "\"$intercomAndroidApiKey\"")
    }

    buildFeatures {
        resValues = true
        buildConfig = true
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            ndk {
                // SYMBOL_TABLE inclui tabela de símbolos dentro do .so (Crashlytics pode ler).
                // FULL gerava arquivo externo e o Flutter tools rejeitava o AAB.
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

tasks.configureEach {
    if (name.contains("Release", ignoreCase = true)) {
        doFirst {
            if (!keystorePropertiesFile.exists()) {
                throw org.gradle.api.GradleException(
                    "Release signing requires android/key.properties with keyAlias, keyPassword, storeFile, and storePassword. Debug signing fallback is disabled."
                )
            }
            if (intercomAppId.isBlank() || intercomAndroidApiKey.isBlank()) {
                throw org.gradle.api.GradleException(
                    "Release builds require Intercom keys: set INTERCOM_APP_ID and INTERCOM_ANDROID_API_KEY (env) or intercom.appId and intercom.androidApiKey in android/local.properties."
                )
            }
            if (!googleServicesJson.exists()) {
                throw org.gradle.api.GradleException(
                    "Release builds require android/app/google-services.json (Firebase push/Crashlytics). Copy it from the Firebase console; never commit it."
                )
            }
        }
    }
}

dependencies {
    // FocuxApplication chama Intercom.initialize; o plugin declara o SDK como
    // `implementation`, então o app precisa da dependência própria (mesma versão do plugin
    // intercom_flutter 9.6.x).
    implementation("io.intercom.android:intercom-sdk:18.10.0")
}

flutter {
    source = "../.."
}