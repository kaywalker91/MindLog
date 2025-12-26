# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (Deferred Components) - 사용하지 않지만 Flutter에서 참조함
# R8에서 missing class 경고를 무시하도록 설정
-dontwarn com.google.android.play.core.**

# Google Generative AI (Gemini)
-keep class com.google.ai.** { *; }
-keepclassmembers class com.google.ai.** { *; }

# Groq API (HTTP client)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Gson (JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# SQLite / sqflite
-keep class io.flutter.plugins.sqflite.** { *; }

# Keep annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
