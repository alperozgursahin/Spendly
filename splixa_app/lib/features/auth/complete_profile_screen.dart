import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_strings.dart';
import '../../core/splixa_design.dart';
import 'auth_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isSaving = false;
  bool _isSigningOut = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _prefillExistingUsername();
  }

  Future<void> _prefillExistingUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();
      final username = profile?['username']?.toString().trim() ?? '';
      if (!mounted || username.isEmpty || _usernameController.text.isNotEmpty) {
        return;
      }
      _usernameController.text = username;
    } catch (_) {
      // Profile creation is handled by the save action. Prefill failure should
      // never prevent the user from choosing a username.
    }
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    if (!RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(username)) {
      setState(() => _usernameError = tr(ref, 'register_username_too_short'));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _usernameError = null;
    });

    try {
      await ref
          .read(authControllerProvider)
          .completeGoogleProfile(username: username);
      if (mounted) context.go('/dashboard');
    } on UsernameSetupException catch (error) {
      if (!mounted) return;
      setState(() => _usernameError = _messageFor(error.failure));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _messageFor(UsernameSetupFailure failure) {
    return switch (failure) {
      UsernameSetupFailure.invalid => tr(ref, 'register_username_too_short'),
      UsernameSetupFailure.taken => tr(ref, 'profile_setup_username_taken'),
      UsernameSetupFailure.unauthorized => tr(
        ref,
        'profile_setup_session_expired',
      ),
      UsernameSetupFailure.timedOut => tr(ref, 'profile_setup_timeout'),
      UsernameSetupFailure.failed => tr(ref, 'profile_setup_failed'),
    };
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await ref.read(authControllerProvider).signOut();
      if (mounted) context.go('/login');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isSigningOut;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SplixaLogo(compact: true),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.alternate_email_rounded,
                        size: 54,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tr(ref, 'profile_setup_title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr(ref, 'profile_setup_subtitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _usernameController,
                        enabled: !isBusy,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newUsername],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9_]'),
                          ),
                          LengthLimitingTextInputFormatter(30),
                        ],
                        onSubmitted: (_) => isBusy ? null : _save(),
                        onChanged: (_) {
                          if (_usernameError != null) {
                            setState(() => _usernameError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: tr(ref, 'profile_setup_username_label'),
                          hintText: tr(ref, 'profile_setup_username_hint'),
                          prefixText: '@',
                          errorText: _usernameError,
                          helperText: tr(ref, 'profile_setup_username_helper'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SplixaPrimaryButton(
                        label: tr(ref, 'profile_setup_continue'),
                        icon: Icons.arrow_forward_rounded,
                        loading: _isSaving,
                        onPressed: isBusy ? null : _save,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isBusy ? null : _signOut,
                        child: Text(tr(ref, 'profile_setup_use_other_account')),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
