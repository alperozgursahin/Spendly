import 'package:shared_preferences/shared_preferences.dart';

class PaywallFrequencyService {
  const PaywallFrequencyService._();

  static Future<bool> claimPostOnboarding(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'post_onboarding_paywall_v1_$userId';
    final previous = DateTime.tryParse(preferences.getString(key) ?? '');
    final now = DateTime.now().toUtc();
    if (previous != null &&
        now.difference(previous) < const Duration(days: 30)) {
      return false;
    }
    await preferences.setString(key, now.toIso8601String());
    return true;
  }
}
