import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  const assets = [
    'assets/lottie/personal_shared.json',
    'assets/lottie/clear_splits.json',
    'assets/lottie/trusted_currency.json',
    'assets/lottie/pro_value.json',
  ];

  for (final asset in assets) {
    test('$asset is a valid, animated Lottie composition', () async {
      final bytes = await File(asset).readAsBytes();
      final composition = await LottieComposition.fromBytes(bytes);

      expect(composition.bounds.width, greaterThan(0));
      expect(composition.bounds.height, greaterThan(0));
      expect(composition.durationFrames, greaterThan(1));
      expect(bytes.length, lessThan(20 * 1024));
    });
  }
}
