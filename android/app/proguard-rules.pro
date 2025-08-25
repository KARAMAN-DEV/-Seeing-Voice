# ML Kit Latin OCR kullanımı için
-keep class com.google.mlkit.vision.text.latin.** { *; }

# TensorFlow Lite kullanımı için
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Kullanılmayan ML Kit dilleri (uygulamada yoksa)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
