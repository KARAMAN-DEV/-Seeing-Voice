import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'settings_page.dart';
import '../main.dart'; // kameraların tanımlandığı dosya
import 'package:bitirme/provider/settings_provider.dart';
import 'package:bitirme/detector/money_detector.dart';
import 'package:bitirme/detector/fruit_detector.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _cameraController;
  late FlutterTts flutterTts;
  late MoneyDetector _moneyDetector;
  String moneyResultText = '';
  late FruitDetector _fruitDetector;
  String fruitResultText = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;

  String recognizedText = '';
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  String selectedMode = 'Gören Ses';

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initializeCamera();
    _moneyDetector = MoneyDetector();
    _moneyDetector.loadModel();
    _fruitDetector = FruitDetector();
    _fruitDetector.loadModel();
    _speech = stt.SpeechToText();
    _startListening();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    await _cameraController.initialize();

    //  final settings = Provider.of<SettingsProvider>(context, listen: false);
    //  await _cameraController.setFlashMode(
    //    settings.autoFlashEnabled ? FlashMode.auto : FlashMode.off,
    //  );

    if (mounted) {
      setState(() => isCameraInitialized = true);
    }
  }

  // Kamera flaşını açıp kapatan fonksiyon.
  Future<void> toggleFlash() async {
    if (_cameraController.value.isInitialized) {
      isFlashOn = !isFlashOn;
      await _cameraController.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
      await _speakMode(isFlashOn ? 'El feneri açıldı' : 'El feneri kapandı');
    }
  }

  // Verilen anahtara göre uygun metni seçip sesli okuyan fonksiyon.
  Future<void> _speakMode(String key) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await flutterTts
        .setLanguage(settings.ocrLanguage == 'Türkçe' ? 'tr-TR' : 'en-US');
    await flutterTts.setSpeechRate(settings.ttsSpeed);

    // Dil destekli metin haritası
    final Map<String, Map<String, String>> localizedTexts = {
      'Meyve tanıma modu': {
        'tr': 'Meyve tanıma modu',
        'en': 'Fruit recognition mode',
      },
      'Para tanıma modu': {
        'tr': 'Para tanıma modu',
        'en': 'Money recognition mode',
      },
      'metin okuyucu modu': {
        'tr': 'Metin okuyucu modu',
        'en': 'Text reader mode',
      },
      'Ayarlar sayfası': {
        'tr': 'Ayarlar sayfası',
        'en': 'Settings page',
      },
      'El feneri açıldı': {
        'tr': 'El feneri açıldı',
        'en': 'Flash turned on',
      },
      'El feneri kapandı': {
        'tr': 'El feneri kapandı',
        'en': 'Flash turned off',
      },
    };

    final langCode = settings.ocrLanguage == 'Türkçe' ? 'tr' : 'en';
    final textToSpeak = localizedTexts[key]?[langCode] ?? key;

    await flutterTts.speak(textToSpeak);
  }

  // Kameradan bir fotoğraf çekip metin tanıma (OCR) yapan fonksiyon.
  Future<void> _captureAndRecognizeText() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Kameradan fotoğraf çek
    final image = await _cameraController.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    // OCR işlemi
    final recognized = await textRecognizer.processImage(inputImage);
    final rawText = recognized.text;

    // Metni temizle (NLP ön işlemesi)
    String cleanedText = _cleanText(rawText);

    // Özetleme (ilk anlamlı cümle)
    String summary = _summarizeText(cleanedText);

    // Ekrana yaz ve seslendir
    setState(() => recognizedText = summary);

    if (summary.isNotEmpty) {
      await flutterTts
          .setLanguage(settings.ocrLanguage == 'Türkçe' ? 'tr-TR' : 'en-US');
      await flutterTts.setSpeechRate(settings.ttsSpeed);
      await flutterTts.speak(summary);
    }
  }

// Metni sadeleştirme (basit temizlik)
  String _cleanText(String rawText) {
    return rawText
        .replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçİĞÜŞÖÇ\s.,!?]'),
            '') // Alfasayısal ve noktalama dışındakileri sil
        .replaceAll(RegExp(r'\s+'), ' ') // Fazla boşlukları tek boşluğa indir
        .trim();
  }

// Basit özetleme: ilk cümleyi alma
  String _summarizeText(String text) {
    List<String> sentences = text.split(RegExp(r'[.!?]'));
    for (var sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        return sentence.trim() + '.'; // İlk anlamlı cümleyi dön
      }
    }
    return text;
  }

  Future<void> _handleMoneyDetection() async {
    if (!_cameraController.value.isInitialized) return;
    final XFile file = await _cameraController.takePicture();
    final result1 = await _moneyDetector.detect(file);
    setState(() => moneyResultText = result1);
  }

  Future<void> _handleFruitDetection() async {
    if (!_cameraController.value.isInitialized) return;
    final XFile file = await _cameraController.takePicture();
    final result2 = await _fruitDetector.detect(file);
    setState(() => fruitResultText = result2);
  }

  Timer? _listenDebounceTimer;

  Future<void> _startListening() async {
    if (_listenDebounceTimer?.isActive ?? false) return;

    _listenDebounceTimer = Timer(const Duration(milliseconds: 300), () {});

    final available = await _speech.initialize();

    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (val) {
          final spoken = val.recognizedWords.toLowerCase();

          if (spoken.contains('meyve')) {
            setState(() => selectedMode = 'Meyve Tanıma');
            _speakMode('Meyve tanıma modu');
          } else if (spoken.contains('para')) {
            setState(() => selectedMode = 'Para Tanıma');
            _speakMode('Para tanıma modu');
          } else if (spoken.contains('metin')) {
            setState(() => selectedMode = 'Metin Okuyucu');
            _speakMode('Metin okuyucu modu');
          } else if (spoken.contains('ayarlar')) {
            _speakMode('Ayarlar sayfası');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          } else if (spoken.contains('feneri aç')) {
            if (!isFlashOn) toggleFlash();
          } else if (spoken.contains('feneri kapat')) {
            if (isFlashOn) toggleFlash();
          }

          setState(() => _isListening = false); // Dinleme bitti
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _cameraController.dispose();
    flutterTts.stop();
    _moneyDetector.close();
    _fruitDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade600,
        elevation: 4,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                  70), // 20 px köşe yarıçapı, istediğin gibi ayarla
              child: Image.asset(
                'assets/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedMode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.mic,
              color: _isListening ? Colors.red : Colors.white,
            ),
            onPressed: _startListening,
          ),
/*          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: toggleFlash,
          ),*/
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.white,
            onPressed: () {
              _speakMode('Ayarlar sayfası');
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isCameraInitialized
                ? CameraPreview(_cameraController)
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Butonlar (Meyve, Para, Metin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: "meyve",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          selectedMode = 'Meyve Tanıma';
                          recognizedText =
                              ''; //Eskiden kalma text değerini sıfırlar.
                        });
                        _speakMode('Meyve tanıma modu');
                      },
                      backgroundColor: selectedMode == 'Meyve Tanıma'
                          ? Colors.indigo
                          : Colors.indigo.shade100,
                      child: const Icon(Icons.apple, color: Colors.black),
                    ),
                    FloatingActionButton(
                      heroTag: "para",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          selectedMode = 'Para Tanıma';
                          recognizedText =
                              ''; //Eskiden kalma text değerini sıfırlar.
                        });
                        _speakMode('Para tanıma modu');
                      },
                      backgroundColor: selectedMode == 'Para Tanıma'
                          ? Colors.indigo
                          : Colors.indigo.shade100,
                      child: const Icon(Icons.money, color: Colors.black),
                    ),
                    FloatingActionButton(
                      heroTag: "metin",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          selectedMode = 'Metin Okuyucu';
                          moneyResultText =
                              ''; //Eskiden kalma text değerini sıfırlar.
                          fruitResultText =
                              ''; //Eskiden kalma text değerini sıfırlar.
                        });
                        _speakMode('metin okuyucu modu');
                      },
                      backgroundColor: selectedMode == 'Metin Okuyucu'
                          ? Colors.indigo
                          : Colors.indigo.shade100,
                      child: const Icon(Icons.text_fields, color: Colors.black),
                    ),
                  ],
                ),

                // 🔽 Para Tanıma moduna özel buton ve sonuç
                if (selectedMode == 'Para Tanıma') ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Parayı Tanı'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _handleMoneyDetection();
                      _speakMode('Para tanıma yapılıyor');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    moneyResultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (selectedMode == 'Meyve Tanıma') ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Meyveyi Tanı'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _handleFruitDetection();
                      _speakMode('Meyve tanıma yapılıyor');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fruitResultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (selectedMode == 'Metin Okuyucu') ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Metin:'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _captureAndRecognizeText();
                      _speakMode('Metin okunuyor');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recognizedText.isNotEmpty ? recognizedText : ' ',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
