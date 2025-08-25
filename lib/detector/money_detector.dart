import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';

class MoneyDetector {
  final FlutterTts _tts = FlutterTts();
  Interpreter? _interpreter;

  final List<String> moneyNames = [
    '5 TL',
    '10 TL',
    '20 TL',
    '50 TL',
    '100 TL',
    '200 TL',
  ];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/yolopara.tflite');
  }

  Future<void> close() async {
    _interpreter?.close();
  }

  Future<String> detect(XFile file) async {
    if (_interpreter == null) return 'Model yüklenmedi';

    final bytes = await File(file.path).readAsBytes();
    final img.Image? raw = img.decodeImage(bytes);
    if (raw == null) return 'Görüntü okunamadı';

    final img.Image resized = img.copyResize(raw, width: 640, height: 640);

    final inputBuffer = Float32List(1 * 640 * 640 * 3);
    int idx = 0;
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = resized.getPixel(x, y);
        inputBuffer[idx++] = img.getRed(pixel) / 255.0;
        inputBuffer[idx++] = img.getGreen(pixel) / 255.0;
        inputBuffer[idx++] = img.getBlue(pixel) / 255.0;
      }
    }

    final outputBuffer =
        List.generate(1, (_) => List.generate(300, (_) => List.filled(6, 0.0)));

    _interpreter!.run(inputBuffer.reshape([1, 640, 640, 3]), outputBuffer);

    double bestConf = 0;
    int bestClass = -1;

    for (int i = 0; i < 300; i++) {
      final detection = outputBuffer[0][i];
      final conf = detection[4];
      final cls = detection[5].toInt();

      if (conf > bestConf) {
        bestConf = conf;
        bestClass = cls;
      }
    }

    final result = (bestConf > 0.5 &&
            bestClass >= 0 &&
            bestClass < moneyNames.length)
        ? 'Para: ${moneyNames[bestClass]} (%${(bestConf * 100).toStringAsFixed(1)})'
        : 'Para algılanamadı';

    await _tts.speak(result);
    return result;
  }
}
