import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bitirme/provider/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _speak(BuildContext context, String key) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final flutterTts = FlutterTts();

    await flutterTts
        .setLanguage(settings.ocrLanguage == 'Türkçe' ? 'tr-TR' : 'en-US');
    await flutterTts.setSpeechRate(settings.ttsSpeed);

    final Map<String, Map<String, String>> localizedTexts = {
      'tts_hizi': {
        'tr': 'Okuma hızı ayarlandı',
        'en': 'Reading speed set',
      },
      'dil_degisti_tr': {
        'tr': 'Tanıma dili Türkçe olarak ayarlandı',
        'en': 'Recognition language set to Turkish',
      },
      'dil_degisti_en': {
        'tr': 'Tanıma dili İngilizce olarak ayarlandı',
        'en': 'Recognition language set to English',
      },
      'flash_acik': {
        'tr': 'Otomatik fener açıldı',
        'en': 'Auto flash enabled',
      },
      'flash_kapali': {
        'tr': 'Otomatik fener kapatıldı',
        'en': 'Auto flash disabled',
      },
      'speech_start': {
        'tr': 'Sesli komut dinleme başlatıldı',
        'en': 'Voice command listening started',
      },
      'speech_stop': {
        'tr': 'Sesli komut dinleme durduruldu',
        'en': 'Voice command listening stopped',
      },
    };

    String langCode = settings.ocrLanguage == 'Türkçe' ? 'tr' : 'en';
    String toSpeak = localizedTexts[key]?[langCode] ?? key;

    await flutterTts.speak(toSpeak);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ayarlar",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo.shade600,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Uygulama Ayarları",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          /// TTS Okuma Hızı
          ListTile(
            title: const Text("TTS Okuma Hızı"),
            subtitle: Slider(
              value: settings.ttsSpeed,
              onChanged: (value) {
                settings.setTtsSpeed(value);
                _speak(context, 'tts_hizi');
              },
              min: 0.2,
              max: 1.0,
              divisions: 4,
              label: settings.ttsSpeed.toStringAsFixed(1),
            ),
          ),
          const Divider(),

          /// Dil Seçimi
          ListTile(
            title: const Text("Tanıma Dili"),
            subtitle: Text(settings.ocrLanguage),
            trailing: const Icon(Icons.translate),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Tanıma Dili Seçin"),
                  children: [
                    SimpleDialogOption(
                      child: const Text("Türkçe"),
                      onPressed: () => Navigator.pop(context, 'Türkçe'),
                    ),
                    SimpleDialogOption(
                      child: const Text("İngilizce"),
                      onPressed: () => Navigator.pop(context, 'İngilizce'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                settings.setOcrLanguage(result);
                _speak(context,
                    result == 'Türkçe' ? 'dil_degisti_tr' : 'dil_degisti_en');
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Sürekli Sesli Komut Dinleme"),
            subtitle: const Text("Uygulama sürekli dinlemede kalsın mı?"),
            value: settings.continuousListening,
            onChanged: (value) {
              settings.setContinuousListening(value);
              _speak(context, value ? 'dinleme acık' : 'dinleme kapalı');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Sesli dinleme ayarı güncellendi.")),
              );
            },
            secondary: const Icon(Icons.hearing),
          ),
          const Divider(),

          /// Hakkında
          ListTile(
            title: const Text("Hakkında"),
            subtitle: const Text(
                "Bu uygulama görme engelliler için geliştirilmiştir."),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              _speak(
                  context,
                  settings.ocrLanguage == 'Türkçe'
                      ? 'Bu uygulama görme engelliler için geliştirilmiştir.'
                      : 'This app was developed for visually impaired users.');
            },
          ),
        ],
      ),
    );
  }
}
