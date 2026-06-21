import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'auth_providers.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'driver';

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).register({
      'username': email,
      'email': email,
      'password': _passwordController.text,
    }, _selectedRole);

    if (mounted) {
      if (success) {
        if (_selectedRole == 'landowner') {
          // Store email for verification pre-fill
          ref.read(registrationEmailProvider.notifier).state = email;

          // Dispatch OTP email from backend
          final otpSent = await ref.read(authControllerProvider.notifier).sendOtp(email);
          if (otpSent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OTP verification code sent to $email'), backgroundColor: AppTheme.success),
            );
            context.push('/otp');
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created. Could not dispatch OTP automatically. Please request resend on OTP screen.'), backgroundColor: AppTheme.warning),
            );
            context.push('/otp');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: AppTheme.success));
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed. Username/email may already be registered.'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  dropdownColor: AppTheme.bgPanel,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'driver', child: Text('I want to park (Driver)')),
                    DropdownMenuItem(value: 'landowner', child: Text('I want to list a spot (Landowner)')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  decoration: const InputDecoration(labelText: 'Account Type'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || val.isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _register,
                  child: authState.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
