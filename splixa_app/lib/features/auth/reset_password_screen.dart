import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_design.dart';
import 'auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _codeError;
  String? _passwordError;

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;
    setState(() {
      _codeError = code.length == 8
          ? null
          : tr(ref, 'auth_code_eight_digits_required');
      _passwordError = newPassword.length >= 6
          ? null
          : tr(ref, 'update_password_too_short');
    });
    if (_codeError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider)
          .recoverPassword(
            email: widget.email,
            code: code,
            newPassword: newPassword,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'update_password_success')),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _backToLogin() async {
    await ref.read(authControllerProvider).cancelPendingAuthFlow();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
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
          title: Text(tr(ref, 'reset_password_code_title')),
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
                    Text(
                      tr(
                        ref,
                        'reset_password_code_prompt',
                      ).replaceFirst('{email}', widget.email),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _resetPassword(),
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: tr(ref, 'update_password_new_label'),
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
                    const SizedBox(height: 24),
                    SplixaPrimaryButton(
                      label: tr(ref, 'reset_password_code_submit'),
                      icon: Icons.lock_reset_rounded,
                      loading: _isLoading,
                      onPressed: _resetPassword,
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
