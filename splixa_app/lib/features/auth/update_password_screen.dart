import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/friendly_error.dart';
import '../../core/app_strings.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _passwordError;

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();

    setState(() {
      _passwordError = newPassword.length < 6
          ? tr(ref, 'update_password_too_short')
          : null;
    });
    if (_passwordError != null) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'update_password_success')),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'update_password_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ref, 'update_password_prompt'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: tr(ref, 'update_password_new_label'),
                errorText: _passwordError,
              ),
              obscureText: true,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(tr(ref, 'update_password_submit')),
            ),
          ],
        ),
      ),
    );
  }
}
