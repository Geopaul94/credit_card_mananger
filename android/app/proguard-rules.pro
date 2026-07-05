# ---- Flutter ----
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# ---- Google Play Core (deferred components / split install) ----
# Referenced by Flutter's embedding but not bundled (app has no deferred
# components). Tell R8 to ignore the missing classes instead of failing.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---- Google ML Kit text recognition ----
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-dontwarn com.google.mlkit.**

# ---- local_auth (biometrics) ----
-keep class androidx.biometric.** { *; }

# ---- flutter_local_notifications ----
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-dontwarn com.dexterous.**

# ---- image_picker ----
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Keep annotations / generics metadata used via reflection
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
