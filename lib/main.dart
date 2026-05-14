import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // The app shows a setup hint if the .env file is not available yet.
  }

  if (!kIsWeb) {
    final stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    if (stripePublishableKey.isNotEmpty) {
      Stripe.publishableKey = stripePublishableKey;
      Stripe.merchantIdentifier = 'merchant.com.cinebook';
      await Stripe.instance.applySettings();
    } else {
      debugPrint(
        'Stripe publishable key is missing. Add STRIPE_PUBLISHABLE_KEY to .env to enable payments.',
      );
    }
  }

  await Supabase.initialize(
    url: dotenv.env['VITE_SUPABASE_URL'] ?? dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['VITE_SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const CineBookApp());
}
