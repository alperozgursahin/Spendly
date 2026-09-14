import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_strings.dart';
import '../../core/locale_provider.dart';
import 'premium_provider.dart';

const _appLockEnabledKey = 'pro_biometric_app_lock_enabled_v1';

final appLockProvider = ChangeNotifierProvider<AppLockController>((ref) {
  final controller = AppLockController(ref);
  unawaited(controller.initialize());
  ref.listen<bool>(premiumProvider, (previous, isPro) {
    if (previous == true && !isPro) {
      controller.disableBecauseEntitlementEnded();
    }
  });
  return controller;
});

class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController(this._ref);

  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _enabled = false;
  bool _locked = false;
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  bool get enabled => _enabled;
  bool get locked => _locked;
  bool get authenticating => _authenticating;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(_appLockEnabledKey) ?? false;
    _locked = _enabled;
    notifyListeners();
    if (_locked) unawaited(unlock());
  }

  Future<bool> setEnabled(bool value) async {
    if (value && !_ref.read(premiumProvider)) return false;
    if (value) {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final authenticated = await _authenticate();
      if (!authenticated) return false;
    }
    _enabled = value;
    _locked = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_appLockEnabledKey, value);
    notifyListeners();
    return true;
  }

  Future<bool> unlock() async {
    if (!_enabled || !_locked || _authenticating) return !_locked;
    _authenticating = true;
    notifyListeners();
    final success = await _authenticate();
    _authenticating = false;
    if (success) _locked = false;
    notifyListeners();
    return success;
  }

  Future<bool> _authenticate() async {
    try {
      final language = currentAppLanguage;
      return await _auth.authenticate(
        localizedReason: AppStrings.of('pro_app_lock_reason', language),
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      debugPrint('Local authentication unavailable: ${error.code}');
      return false;
    }
  }

  Future<void> disableBecauseEntitlementEnded() async {
    if (!_enabled) return;
    _enabled = false;
    _locked = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_appLockEnabledKey, false);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final elapsed = _backgroundedAt == null
          ? Duration.zero
          : DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (elapsed >= const Duration(seconds: 10)) {
        _locked = true;
        notifyListeners();
        unawaited(unlock());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class AppLockGate extends ConsumerWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    final isPro = ref.watch(premiumProvider);
    if (!isPro || !lock.locked) return child;

    // This sits in MaterialApp.builder, above the Navigator, so there is no
    // Material ancestor here. Without one, WidgetsApp's deliberately loud
    // fallback DefaultTextStyle (giant red monospace, yellow underline) applies
    // to every Text -- which is exactly what the lock screen used to show.
    // Material both supplies a sane text style and paints the black ground.
    return Material(
      color: Colors.black,
      child: GestureDetector(
        // No copy on this screen by design: the logo is the affordance. Tapping
        // anywhere retries, so cancelling the system prompt is never a dead end.
        behavior: HitTestBehavior.opaque,
        onTap: lock.authenticating ? null : lock.unlock,
        child: Center(child: _BreathingLogo(active: !lock.authenticating)),
      ),
    );
  }
}

/// Slow opacity breath on the Splixa mark. It is the only motion on the lock
/// screen and its job is to say "this is waiting for you, tap it" without a
/// single word that would need translating into twelve locales.
class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo({required this.active});

  final bool active;

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const logo = Image(
      image: AssetImage('assets/images/splixa_logo.png'),
      width: 140,
      filterQuality: FilterQuality.medium,
    );
    // While the system biometric sheet is up the logo holds steady; the breath
    // resumes only once the app is waiting on the user again.
    if (!widget.active) return const Opacity(opacity: 1.0, child: logo);
    return FadeTransition(opacity: _opacity, child: logo);
  }
}
