import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../shell/shell_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final provider = context.read<AppProvider>();
    provider.clearError();
    final ok = await provider.login(
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShellScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((AppProvider p) => p.isLoading);

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AnonTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AnonTheme.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AnonTheme.primary, size: 20),
                ),
              ),

              const SizedBox(height: 40),

              // Headline
              const Text(
                'anonymous.',
                style: TextStyle(
                  color: AnonTheme.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 10),
              const Text(
                'Welcome\nback.',
                style: TextStyle(
                  color: AnonTheme.primary,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
              const SizedBox(height: 10),
              const Text(
                'Sign in to open your vault.',
                style: TextStyle(color: AnonTheme.subtext, fontSize: 15),
              ).animate().fadeIn(delay: 140.ms),

              const SizedBox(height: 48),

              // Fields
              _Field(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'yourname',
                icon: Icons.alternate_email_rounded,
              ).animate().fadeIn(delay: 180.ms).slideX(begin: 0.08),
              const SizedBox(height: 14),
              _Field(
                controller: _passwordCtrl,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                onToggleObscure: () =>
                    setState(() => _obscure = !_obscure),
              ).animate().fadeIn(delay: 220.ms).slideX(begin: 0.08),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black),
                        )
                      : const Text('SIGN IN',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.5)),
                ),
              ).animate().fadeIn(delay: 260.ms),

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text(
                    "No account yet? Create one",
                    style: TextStyle(
                        color: AnonTheme.primaryLight, fontSize: 14),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AnonTheme.primary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AnonTheme.primaryLight, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AnonTheme.subtext,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
    );
  }
}
