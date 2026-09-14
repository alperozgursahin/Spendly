# google_mlkit_text_recognition ships only the Latin recognizer, but its Android
# side references the Chinese, Devanagari, Japanese and Korean option classes in
# a when-branch over the requested script. R8 sees those classes as missing and
# fails the release build.
#
# lib/features/subscriptions/receipt_service.dart constructs exactly one
# recognizer — TextRecognizer(script: TextRecognitionScript.latin) — so those
# branches are unreachable. Suppressing the warnings is the correct fix here;
# adding the other recognizer artifacts would ship code the app can never run.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# With minification now on, the deferred-components support in Flutter's
# embedding references Play Core split-install classes that this app does not
# ship, and R8 treats the missing references as errors rather than warnings.
# Splixa has no dynamic feature modules, so nothing here is reachable.
-dontwarn com.google.android.play.core.**

# The embedding instantiates the engine, the plugin registrant and every
# registered plugin reflectively by name, so shrinking must not rename or
# remove them.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
