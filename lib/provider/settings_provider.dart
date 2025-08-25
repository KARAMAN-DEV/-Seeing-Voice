import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _ttsSpeed = 0.5;
  String _ocrLanguage = 'Türkçe';

  bool _continuousListening = false;

  double get ttsSpeed => _ttsSpeed;
  String get ocrLanguage => _ocrLanguage;

  bool get continuousListening => _continuousListening;

  SettingsProvider() {
    _loadSettings(); // Başlangıçta ayarları yükle
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsSpeed = prefs.getDouble('ttsSpeed') ??
        0.5; //kayıtlı değer varmı diye bakar yoksa 0.5 atar.
    _ocrLanguage = prefs.getString('ocrLanguage') ?? 'Türkçe';
    _continuousListening = prefs.getBool('continuousListening') ?? false;
    notifyListeners();
  }

  void setTtsSpeed(double value) async {
    _ttsSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ttsSpeed', value);
    notifyListeners();
  }

  void setOcrLanguage(String language) async {
    _ocrLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ocrLanguage', language);
    notifyListeners();
  }

  void setContinuousListening(bool value) async {
    _continuousListening = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('continuousListening', value);
    notifyListeners();
  }
}
