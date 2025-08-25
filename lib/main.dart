import 'package:flutter/material.dart';
import 'package:bitirme/provider/settings_provider.dart';
import 'package:camera/camera.dart';
import 'package:bitirme/pages/splash_page.dart';
import 'package:provider/provider.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        // İleride başka provider'lar da buraya eklenebilir.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Görsel Tanıma Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashScreen(), // başlangıçta splash gösterilir
    );
  }
}
