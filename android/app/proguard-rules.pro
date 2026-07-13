# The Flutter ML Kit bridge supports optional OCR scripts. Pundi deliberately
# bundles only the Latin recognizer, so references to the other script modules
# are absent and safe to ignore during R8 shrinking.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
