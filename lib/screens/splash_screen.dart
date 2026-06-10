import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'intro_screen.dart';
import 'shell/shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotCtrl;
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat();
    _dotCtrl.addListener(() {
      final d = (_dotCtrl.value * 3).floor().clamp(0, 2);
      if (d != _activeDot && mounted) setState(() => _activeDot = d);
    });
    _boot();
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final provider = context.read<AppProvider>();
    await Future.wait([
      provider.init(),
      Future.delayed(const Duration(milliseconds: 3000)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            provider.isLoggedIn ? const ShellScreen() : const IntroScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1DCC9), // cream
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // ── Logo ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            )
                .animate()
                .fadeIn(duration: 700.ms)
                .scale(
                    begin: const Offset(0.88, 0.88),
                    duration: 900.ms,
                    curve: Curves.easeOutBack),

            const Spacer(flex: 3),

            // ── Tagline ───────────────────────────────────────────────────
            const Text(
              'no filters. no names. just truth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5C3E22),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

            const SizedBox(height: 32),

            // ── Loading dots ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _activeDot;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF412D15)
                        : const Color(0xFF412D15).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
