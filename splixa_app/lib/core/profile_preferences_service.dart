import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePreferencesService {
  const ProfilePreferencesService._();

  static Future<void> syncTimezone() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null || kIsWeb) return;
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      await client.rpc(
        'set_profile_timezone_v1',
        params: {'p_timezone': timezone.identifier},
      );
    } catch (error) {
      debugPrint('Timezone sync deferred: $error');
    }
  }
}
