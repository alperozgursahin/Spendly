import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_design.dart';
import 'auth_provider.dart';

class LoginVerificationScreen extends ConsumerStatefulWidget {
  const LoginVerificationScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<LoginVerificationScreen> createState() =>
      _LoginVerificationScreenState();
}

class _LoginVerificationScreenState
    extends ConsumerState<LoginVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _codeError;

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    setState(() {
      _codeError = code.length == 8
          ? null
          : tr(ref, 'auth_code_eight_digits_required');
    });
    if (_codeError != null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .verifyLoginOtp(email: widget.email, code: code);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await ref
          .read(authControllerProvider)
          .resendLoginOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(ref, 'auth_code_resent'))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _backToLogin() async {
    await ref.read(authControllerProvider).cancelPendingAuthFlow();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToLogin();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _isLoading ? null : _backToLogin,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(tr(ref, 'login_verification_title')),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SplixaLogo(),
                    const SizedBox(height: 28),
                    Text(
                      tr(
                        ref,
                        'login_verification_prompt',
                      ).replaceFirst('{email}', widget.email),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      onSubmitted: (_) => _verifyCode(),
                      onChanged: (_) {
                        if (_codeError != null) {
                          setState(() => _codeError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: tr(ref, 'auth_code_label'),
                        errorText: _codeError,
                        prefixIcon: const Icon(Icons.password_rounded),
                        counterText: '',
                      ),
                      maxLength: 8,
                    ),
                    const SizedBox(height: 20),
                    SplixaPrimaryButton(
                      label: tr(ref, 'login_verification_submit'),
                      icon: Icons.verified_user_outlined,
                      loading: _isLoading,
                      onPressed: _verifyCode,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading || _isResending
                          ? null
                          : _resendCode,
                      child: Text(
                        _isResending
                            ? tr(ref, 'auth_code_resending')
                            : tr(ref, 'auth_code_resend'),
                      ),
                    ),
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
