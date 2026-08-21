# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Mantém modelos de dados JSON (Dio + json_serializable)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Evita warning de classes do Android SDK
-dontwarn android.support.**
-dontwarn androidx.**

# ML Kit text recognition — scripts opcionais não bundled no APK
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
