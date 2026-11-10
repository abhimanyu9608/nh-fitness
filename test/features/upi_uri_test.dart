import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/data/models/app_settings.dart';
import 'package:nh_fitness/features/checkout/upi_block.dart';

void main() {
  final settings = AppSettings.defaults.copyWith(
    upiId: 'nhfitness@okhdfcbank',
    upiName: 'NH Fitness',
  );

  group('buildUpiUri (PRD section 7.4)', () {
    test('matches the format the PRD specifies', () {
      final uri = buildUpiUri(
        settings: settings,
        total: 20500,
        planName: 'Yearly',
      );

      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
      expect(uri.queryParameters['pa'], 'nhfitness@okhdfcbank');
      expect(uri.queryParameters['pn'], 'NH Fitness');
      expect(uri.queryParameters['am'], '20500');
      expect(uri.queryParameters['cu'], 'INR');
      expect(uri.queryParameters['tn'], 'NH Fitness Yearly');
    });

    test('sends a plain rupee amount, with no symbol or grouping', () {
      // UPI apps reject "₹20,500"; the amount has to be bare digits.
      final uri = buildUpiUri(settings: settings, total: 120000, planName: 'X');
      expect(uri.queryParameters['am'], '120000');
    });

    test('percent-encodes a payee name containing punctuation', () {
      final uri = buildUpiUri(
        settings: settings.copyWith(upiName: "Gold's Gym & Fitness"),
        total: 1500,
        planName: 'Monthly plan',
      );

      // Round-tripping is what matters: the UPI app must read back the
      // original text.
      expect(uri.queryParameters['pn'], "Gold's Gym & Fitness");
      expect(uri.queryParameters['tn'], 'NH Fitness Monthly plan');
      // The raw string must not contain a bare '&' inside a value, which would
      // split the query.
      expect(uri.toString().contains('& Fitness'), isFalse);
      expect(Uri.parse(uri.toString()).queryParameters['pn'],
          "Gold's Gym & Fitness");
    });
  });
}
