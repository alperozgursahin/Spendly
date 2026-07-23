import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/friendly_error.dart';
import '../../core/splixa_design.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpRequested = false;
  String? _emailError;

  String get _email => _emailController.text.trim().toLowerCase();

  Future<void> _requestOtp() async {
    final isValidEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email);
    if (!isValidEmail) {
      setState(() => _emailError = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _emailError = null;
      _isLoading = true;
    });
    try {
      await ref.read(authControllerProvider).requestEmailOtp(_email);
      if (mounted) setState(() => _otpRequested = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length < 8) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .verifyEmailOtp(email: _email, token: _otpController.text.trim());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const Spacer(flex: 2),
              Text(
                _otpRequested ? 'Check your email' : 'Welcome to Splixa',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _otpRequested
                    ? 'Enter the 8-digit code sent to $_email.'
                    : 'Use your email to securely sign in or create your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (!_otpRequested) _emailField() else _otpField(),
              const SizedBox(height: 18),
              SplixaPrimaryButton(
                label: _otpRequested ? 'Verify & Continue' : 'Request OTP',
                icon: _otpRequested
                    ? Icons.verified_user_outlined
                    : Icons.sms_outlined,
                loading: _isLoading,
                onPressed: _otpRequested ? _verifyOtp : _requestOtp,
              ),
              if (_otpRequested) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                          _otpRequested = false;
                          _otpController.clear();
                        }),
                  child: const Text('Change email address'),
                ),
              ],
              const Spacer(flex: 3),
              Text(
                'By continuing, you agree to Splixa’s Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => _requestOtp(),
      onChanged: (_) {
        if (_emailError != null) setState(() => _emailError = null);
      },
      decoration: InputDecoration(
        hintText: 'you@example.com',
        errorText: _emailError,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
    );
  }

  Widget _otpField() {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 8,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 7,
      ),
      decoration: const InputDecoration(hintText: '00000000', counterText: ''),
    );
  }
}
