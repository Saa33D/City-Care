plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // AJOUT: Le plugin Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.city_care"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.city_care"
        
        // Firebase nécessite souvent un minSdk de 21 au minimum.
        // Si tu as une erreur plus tard, remplace flutter.minSdkVersion par 21
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// AJOUT: Section dépendances pour gérer les versions Firebase
dependencies {
    // Import du Firebase BOM (Bill of Materials) pour gérer les versions automatiquement
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
}
