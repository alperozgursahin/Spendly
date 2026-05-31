import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class ExchangeRateService with WidgetsBindingObserver {
  // Fallback/static rates to use if network fails
  final Map<String, double> _rates = {'₺': 1.0, '\$': 0.036, '€': 0.033};

  Timer? _timer;

  ExchangeRateService() {
    WidgetsBinding.instance.addObserver(this);
    _fetchLatest();
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  double rateFor(String currency) => _rates[currency] ?? 1.0;

  double convertFromTRY(double amount, String toCurrency) {
    final rate = rateFor(toCurrency);
    return amount * rate;
  }

  Future<bool> refresh() async {
    try {
      await _fetchLatest();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchLatest() async {
    const symbolMap = {'\$': 'USD', '€': 'EUR', '₺': 'TRY'};
    final symbols = symbolMap.values.where((c) => c != 'TRY').join(',');
    final uri = Uri.parse(
      'https://api.exchangerate.host/latest?base=TRY&symbols=$symbols',
    );

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
        final rates = (jsonBody['rates'] ?? {}) as Map<String, dynamic>;
        if (rates.isNotEmpty) {
          if (rates.containsKey('USD')) {
            _rates['\$'] = (rates['USD'] as num).toDouble();
          }
          if (rates.containsKey('EUR')) {
            _rates['€'] = (rates['EUR'] as num).toDouble();
          }
          _rates['₺'] = 1.0;
        }
      }
    } catch (e) {}
  }

  void dispose() {
    _stopTimer();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _fetchLatest();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      _fetchLatest();
    } else {
      _stopTimer();
    }
  }
}

final exchangeRateProvider = Provider<ExchangeRateService>((ref) {
  final svc = ExchangeRateService();
  ref.onDispose(() {
    svc.dispose();
  });
  return svc;
});
