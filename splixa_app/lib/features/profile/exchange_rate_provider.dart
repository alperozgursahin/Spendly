import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService extends ChangeNotifier with WidgetsBindingObserver {
  static const _endpoint = 'https://open.er-api.com/v6/latest/TRY';
  static const _cacheKey = 'exchange_rates_try_v1';
  static const _cacheTimestampKey = 'exchange_rates_try_updated_at_v1';
  static const _maxRateAge = Duration(hours: 26);
  static const _maxCachedRateAge = Duration(days: 7);

  // Used for rendering only until the network/cache initialization completes.
  // Non-TRY writes are blocked unless a verified API response or cache exists.
  final Map<String, double> _rates = {'₺': 1.0, r'$': 0.021, '€': 0.018};

  Timer? _timer;
  DateTime? _lastUpdatedAt;
  Future<bool>? _refreshInFlight;
  late final Future<void> _initialization;

  ExchangeRateService() {
    WidgetsBinding.instance.addObserver(this);
    _initialization = _initialize();

    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  bool get hasVerifiedRates => _lastUpdatedAt != null;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  double rateFor(String currency) => _rates[currency] ?? 1.0;

  double convertFromTRY(double amount, String toCurrency) {
    return amount * rateFor(toCurrency);
  }

  double convertToTRY(double amount, String fromCurrency) {
    final rate = rateFor(fromCurrency);
    if (rate <= 0) {
      throw StateError('Invalid exchange rate for $fromCurrency');
    }
    return amount / rate;
  }

  Future<bool> ensureFresh() async {
    await _initialization;

    final updatedAt = _lastUpdatedAt;
    final age = updatedAt == null
        ? null
        : DateTime.now().toUtc().difference(updatedAt);
    if (age != null && age < _maxRateAge) {
      return true;
    }

    final refreshed = await _fetchLatest();
    if (refreshed) return true;

    return age != null && age < _maxCachedRateAge;
  }

  Future<bool> refresh() async {
    await _initialization;
    return _fetchLatest();
  }

  Future<void> _initialize() async {
    await _loadCachedRates();
    await _fetchLatest();
  }

  Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawRates = prefs.getString(_cacheKey);
      final rawTimestamp = prefs.getString(_cacheTimestampKey);
      if (rawRates == null || rawTimestamp == null) return;

      final decoded = jsonDecode(rawRates) as Map<String, dynamic>;
      final usd = decoded['USD'];
      final eur = decoded['EUR'];
      final timestamp = DateTime.tryParse(rawTimestamp)?.toUtc();

      if (usd is! num ||
          eur is! num ||
          usd <= 0 ||
          eur <= 0 ||
          timestamp == null) {
        return;
      }

      _rates[r'$'] = usd.toDouble();
      _rates['€'] = eur.toDouble();
      _rates['₺'] = 1.0;
      _lastUpdatedAt = timestamp;
      notifyListeners();
    } catch (_) {
      // A corrupt cache is ignored; the network refresh below remains primary.
    }
  }

  Future<bool> _fetchLatest() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final request = _performFetch();
    _refreshInFlight = request;
    return request.whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performFetch() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return false;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['result'] != 'success' || body['base_code'] != 'TRY') {
        return false;
      }

      final rates = body['rates'];
      if (rates is! Map<String, dynamic>) return false;

      final usd = rates['USD'];
      final eur = rates['EUR'];
      if (usd is! num || eur is! num || usd <= 0 || eur <= 0) {
        return false;
      }

      final apiTimestamp = body['time_last_update_unix'];
      final updatedAt = apiTimestamp is num
          ? DateTime.fromMillisecondsSinceEpoch(
              apiTimestamp.toInt() * 1000,
              isUtc: true,
            )
          : DateTime.now().toUtc();

      _rates[r'$'] = usd.toDouble();
      _rates['€'] = eur.toDouble();
      _rates['₺'] = 1.0;
      _lastUpdatedAt = updatedAt;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({'USD': usd.toDouble(), 'EUR': eur.toDouble()}),
      );
      await prefs.setString(_cacheTimestampKey, updatedAt.toIso8601String());

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      _fetchLatest();
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

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final exchangeRateProvider = ChangeNotifierProvider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});
