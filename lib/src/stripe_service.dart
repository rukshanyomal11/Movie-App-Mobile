import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  static String get _secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  static Future<bool> makePayment({
    required double amount,
    required String currency,
  }) async {
    if (kIsWeb) {
      // The native Payment Sheet is NOT supported on Web by flutter_stripe.
      // For this demo, we will simulate a successful payment on Web.
      debugPrint('Stripe: Simulating successful payment for Web environment.');
      return true;
    }

    try {
      // Payment intents must be created by a trusted backend, not in the app.
      final paymentIntent = await _createPaymentIntent(amount, currency);
      final clientSecret =
          paymentIntent['client_secret'] ?? paymentIntent['clientSecret'];

      if (clientSecret is! String || clientSecret.isEmpty) {
        throw Exception('Failed to create payment intent');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CineBook',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFFF2D55),
              background: Color(0xFF1A1A1A),
              componentBackground: Color(0xFF262626),
              componentDivider: Color(0xFF333333),
              primaryText: Colors.white,
              secondaryText: Color(0xFF808080),
              placeholderText: Color(0xFF666666),
              icon: Color(0xFFFF2D55),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (e) {
      if (e is StripeException) {
        debugPrint('Stripe error: ${e.error.localizedMessage}');
      } else {
        debugPrint('General error: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>> _createPaymentIntent(
    double amount,
    String currency,
  ) async {
    if (_secretKey.isEmpty) {
      throw StateError(
        'Missing STRIPE_SECRET_KEY. Add it to your .env file.',
      );
    }

    final body = {
      'amount': (amount * 100).toInt().toString(),
      'currency': currency.toLowerCase(),
      'payment_method_types[]': 'card',
    };

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Stripe payment intent request failed (${response.statusCode}): ${response.body}',
      );
    }

    return jsonDecode(response.body);
  }
}
