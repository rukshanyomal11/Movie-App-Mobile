import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // The app shows a setup hint if the .env file is not available yet.
  }

  await Supabase.initialize(
    url: dotenv.env['VITE_SUPABASE_URL'] ?? dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['VITE_SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const CineBookApp());
}