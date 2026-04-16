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
