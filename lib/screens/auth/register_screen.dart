import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../shell/shell_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final provider = context.read<AppProvider>();
    provider.clearError();
    final ok = await provider.register(
      username: _usernameCtrl.text,
      displayName: _displayNameCtrl.text.trim().isEmpty
          ? _usernameCtrl.text
          : _displayNameCtrl.text,
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
        SnackBar(content: Text(provider.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((AppProvider p) => p.isLoading);

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AnonTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'anonymous.',
              style: TextStyle(
                  color: AnonTheme.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5),
            ).animate().fadeIn(),
            const SizedBox(height: 10),
            const Text(
              'Open\nyour vault.',
              style: TextStyle(
                  color: AnonTheme.primary,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5),
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
            const SizedBox(height: 10),
            const Text(
              'Free. Anonymous. Unfiltered.',
              style: TextStyle(color: AnonTheme.subtext, fontSize: 15),
            ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 40),
            _field(
              controller: _usernameCtrl,
              label: 'Username',
              hint: 'e.g. chaotic_angel',
              icon: Icons.alternate_email_rounded,
              helper: 'Only letters, numbers, underscores. Min 3 chars.',
            ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1),
            const SizedBox(height: 16),
            _field(
              controller: _displayNameCtrl,
              label: 'Display Name (optional)',
              hint: 'e.g. Angel',
              icon: Icons.person_outline_rounded,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            const SizedBox(height: 16),
            _field(
              controller: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
            ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black),
                      )
                    : const Text('CREATE ACCOUNT',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1)),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  'Already have an account? Sign in',
                  style:
                      TextStyle(color: AnonTheme.primaryLight, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? helper,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AnonTheme.primary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperStyle: const TextStyle(color: AnonTheme.subtext, fontSize: 12),
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
