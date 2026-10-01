import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox<dynamic>('app_settings');
  final token = settingsBox.get('auth.accessToken')?.toString();
  final hasToken = token != null && token.isNotEmpty;
  if (hasToken) {
    debugPrint('[AUTH] Credential restored');
    final rawProfile = settingsBox.get('auth.profile');
    if (rawProfile != null) {
      debugPrint('[AUTH] Current user restored');
    }
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HostelGharApp());
}
