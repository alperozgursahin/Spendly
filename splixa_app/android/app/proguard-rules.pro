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
