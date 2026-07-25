import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_design.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;

  bool _validate() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _identifierError = identifier.isEmpty
          ? tr(ref, 'login_identifier_required')
          : null;
      _passwordError = password.isEmpty
          ? tr(ref, 'login_password_required')
          : null;
    });
    return _identifierError == null && _passwordError == null;
  }

  Future<void> _signIn() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(authControllerProvider)
          .beginTwoStepSignIn(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (result.requiresOtp) {
        context.go('/verify-login', extra: result.email);
      } else {
        context.go('/dashboard');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 36,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/onboarding'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        const SplixaLogo(compact: true),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      tr(ref, 'login_welcome'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(ref, 'login_identifier_subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) {
                        if (_identifierError != null) {
                          setState(() => _identifierError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: tr(ref, 'login_identifier_label'),
                        hintText: tr(ref, 'login_identifier_hint'),
                        errorText: _identifierError,
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _signIn(),
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: tr(ref, 'login_password_label'),
                        errorText: _passwordError,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(tr(ref, 'login_forgot_password')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SplixaPrimaryButton(
                      label: tr(ref, 'login_submit'),
                      icon: Icons.login_rounded,
                      loading: _isLoading,
                      onPressed: _signIn,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.go('/register'),
                      child: Text(tr(ref, 'login_no_account')),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
