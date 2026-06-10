import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/update_service.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class ShellScreen extends StatefulWidget {
  final int initialTab;

  const ShellScreen({super.key, this.initialTab = 0});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) UpdateService.checkAndPrompt(context);
      });
    });
  }

  final _tabs = const [
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: _VaultNavBar(
        selected: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ─── Custom "Vault" nav bar ───────────────────────────────────────────────────

class _VaultNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _VaultNavBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 68 + bottom,
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: AnonTheme.surface,
        border: Border(top: BorderSide(color: AnonTheme.cardBorder)),
      ),
      child: Stack(
        children: [
          // Grain
          const Positioned.fill(child: _NavGrain()),

          Row(
            children: [
              _NavItem(
                index: 0,
                selected: selected,
                icon: Icons.grid_view_rounded,
                label: 'VAULT',
                code: 'V-01',
                onTap: onTap,
              ),
              // Center divider
              Container(width: 1, color: AnonTheme.cardBorder),
              _NavItem(
                index: 1,
                selected: selected,
                icon: Icons.fingerprint_rounded,
                label: 'DOSSIER',
                code: 'D-02',
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selected;
  final IconData icon;
  final String label;
  final String code;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.label,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: active
                    ? AnonTheme.primaryLight
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? AnonTheme.primaryLight : AnonTheme.subtext,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? AnonTheme.primaryLight : AnonTheme.subtext,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    code,
                    style: TextStyle(
                      color: active
                          ? AnonTheme.primaryLight.withValues(alpha: 0.5)
                          : AnonTheme.subtext.withValues(alpha: 0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavGrain extends StatelessWidget {
  const _NavGrain();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _NavGrainPainter());
}

class _NavGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.015);
    for (int i = 0; i < 400; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
