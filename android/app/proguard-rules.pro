# -------- Flutter ----------
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# -------- Firebase ----------
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Firebase Messaging classes
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**
# -------- TensorFlow Lite ----------
# Core TFLite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# GPU Delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# NNAPI Delegate
-keep class org.tensorflow.lite.nnapi.** { *; }
-dontwarn org.tensorflow.lite.nnapi.**

# -------- Gson ----------
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# -------- General ----------
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
