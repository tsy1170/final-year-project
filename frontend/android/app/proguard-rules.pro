# Disable all shrinking, obfuscation, and optimization to prevent R8 from stripping
# critical runtime classes needed by Flutter, Firebase, and ML Kit during startup.
-dontshrink
-dontobfuscate
-dontoptimize

# Core Flutter and Android keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.mlkit.** { *; }

# Prevent warnings from missing ML Kit script modules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**

# Prevent warnings from missing Play Store split/deferred components
# We also ignore warnings from the Flutter engine classes that reference them
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# General ignore for any remaining missing class warnings to ensure the build completes
-ignorewarnings
