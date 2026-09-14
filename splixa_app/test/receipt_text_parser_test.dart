import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/features/subscriptions/receipt_service.dart';

void main() {
  group('ReceiptTextParser', () {
    test('prefers a localized total line over earlier item prices', () {
      final result = ReceiptTextParser.parse('''
SPLIXA MARKET
Coffee 45,50
Bread 20,00
TOPLAM 1.234,56 TL
''');

      expect(result.description, 'SPLIXA MARKET');
      expect(result.amount, 1234.56);
      expect(result.confidence, 0.9);
    });

    test('parses dot-decimal totals and ignores dates without cents', () {
      final result = ReceiptTextParser.parse('''
Corner Store
2026-09-14
Grand Total 42.75
''');

      expect(result.description, 'Corner Store');
      expect(result.amount, 42.75);
      expect(result.confidence, 0.9);
    });

    test('uses the last monetary candidate with lower confidence', () {
      final result = ReceiptTextParser.parse('''
Cafe Roma
Tea 3,50
7,25
''');

      expect(result.amount, 7.25);
      expect(result.confidence, 0.55);
    });

    test('returns no amount for unusable OCR output', () {
      final result = ReceiptTextParser.parse('Thank you');

      expect(result.amount, isNull);
      expect(result.confidence, 0);
    });
  });
}
