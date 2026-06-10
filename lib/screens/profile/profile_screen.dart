import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../intro_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user!;

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: CustomScrollView(
        slivers: [
          // â”€â”€ Profile header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, provider: provider),
          ),

          // â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _StatsRow(provider: provider)
                  .animate()
                  .fadeIn(delay: 200.ms),
            ),
          ),

          // â”€â”€ Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'SETTINGS',
                style: TextStyle(
                    color: AnonTheme.subtext,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 250.ms),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: _settingItems.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = _settingItems[i];
                return _SettingTile(
                  icon: item.$1,
                  label: item.$2,
                  subtitle: item.$3,
                  iconColor: item.$4,
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 280 + i * 50))
                    .slideX(begin: 0.06);
              },
            ),
          ),

          // â”€â”€ Sign out â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const IntroScreen()),
                        (_) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(delay: 450.ms),
            ),
          ),
        ],
      ),
    );
  }

  static const _settingItems = [
    (
      Icons.lock_outline_rounded,
      'Privacy',
      'Your identity is always anonymous to responders',
      AnonTheme.primaryLight,
    ),
    (
      Icons.notifications_none_rounded,
      'Notifications',
      'Coming soon',
      Color(0xFFF59E0B),
    ),
    (
      Icons.palette_outlined,
      'Theme',
      'Warm dark â€” anonymous. exclusive',
      AnonTheme.primary,
    ),
    (
      Icons.info_outline_rounded,
      'About Anonymous',
      'no filters. no names. just truth. â€” v1.0.0',
      AnonTheme.primaryLight,
    ),
  ];
}

// â”€â”€â”€ Profile header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProfileHeader extends StatefulWidget {
  final dynamic user;
  final AppProvider provider;

  const _ProfileHeader({required this.user, required this.provider});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _saving = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() => _saving = true);
    await widget.provider.updateProfile(avatarBase64: base64Encode(bytes));
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _editDisplayName() async {
    final controller =
        TextEditingController(text: widget.user.displayName as String);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AnonTheme.surface,
        title: const Text('Edit Display Name',
            style: TextStyle(
                color: AnonTheme.primary, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          style: const TextStyle(color: AnonTheme.primary),
          decoration: InputDecoration(
            hintText: 'Your display name',
            hintStyle: const TextStyle(color: AnonTheme.subtext),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AnonTheme.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AnonTheme.primaryLight),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AnonTheme.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save',
                style: TextStyle(
                    color: AnonTheme.primaryLight,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    setState(() => _saving = true);
    await widget.provider.updateProfile(displayName: result);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final String? avatarBase64 = user.avatarBase64 as String?;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AnonTheme.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              // Wordmark
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'anonymous.',
                  style: TextStyle(
                    color: AnonTheme.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Avatar with camera overlay
              Stack(
                children: [
                  if (avatarBase64 != null)
                    ClipOval(
                      child: Image.memory(
                        base64Decode(avatarBase64),
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    WaxSealAvatar(
                      letter: (user.displayName as String)[0].toUpperCase(),
                      username: user.username as String,
                      size: 110,
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _saving ? null : _pickAvatar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AnonTheme.primaryLight,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AnonTheme.surface, width: 2),
                        ),
                        child: _saving
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                color: Colors.black, size: 16),
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.7, 0.7))
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Display name with edit pencil
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.displayName as String,
                    style: const TextStyle(
                      color: AnonTheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _saving ? null : _editDisplayName,
                    child: const Icon(Icons.edit_rounded,
                        color: AnonTheme.subtext, size: 18),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 6),

              // Username chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AnonTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AnonTheme.primaryLight.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alternate_email_rounded,
                        color: AnonTheme.primaryLight, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      user.username as String,
                      style: const TextStyle(
                        color: AnonTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 12),

              // Vault tagline
              const Text(
                'Your vault. Your truth.',
                style: TextStyle(
                    color: AnonTheme.subtext,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Wax Seal Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class WaxSealAvatar extends StatelessWidget {
  final String letter;
  final String username;
  final double size;

  const WaxSealAvatar({
    super.key,
    required this.letter,
    required this.username,
    required this.size,
  });

  /// Pick a color deterministically from the username
  Color _sealColor() {
    const colors = [
      Color(0xFFDC2626),
      Color(0xFF059669),
      Color(0xFF7C3AED),
      Color(0xFFD97706),
      Color(0xFFBE185D),
      Color(0xFF0369A1),
      Color(0xFF065F46),
      Color(0xFF9A3412),
      Color(0xFF6D28D9),
      Color(0xFF0E7490),
    ];
    final hash =
        username.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WaxSealPainter(
        letter: letter,
        sealColor: _sealColor(),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  final String letter;
  final Color sealColor;

  _WaxSealPainter({required this.letter, required this.sealColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = size.width / 2;

    // â”€â”€ Outer glow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = sealColor.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(cx, cy), R * 0.85, glowPaint);

    // â”€â”€ Scalloped seal edge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const notches = 20;
    const outerR = 1.0;
    const innerR = 0.87;

    final sealPath = Path();
    for (int i = 0; i <= notches * 2; i++) {
      final angle = (i / (notches * 2)) * 2 * pi - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + R * r * cos(angle);
      final y = cy + R * r * sin(angle);
      if (i == 0) sealPath.moveTo(x, y);
      else sealPath.lineTo(x, y);
    }
    sealPath.close();

    final sealPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(sealColor, Colors.white, 0.25)!,
          sealColor,
          Color.lerp(sealColor, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.5, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: R));
    canvas.drawPath(sealPath, sealPaint);

    // â”€â”€ Inner ring â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.04;
    canvas.drawCircle(Offset(cx, cy), R * 0.68, ringPaint);

    // â”€â”€ Dark inner circle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final innerPaint = Paint()
      ..color = Color.lerp(sealColor, Colors.black, 0.5)!;
    canvas.drawCircle(Offset(cx, cy), R * 0.62, innerPaint);

    // â”€â”€ Letter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: const Color(0xFFE1DCC9),
          fontSize: R * 0.55,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );

    // â”€â”€ Small decorative dots around the ring â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3);
    for (int i = 0; i < notches; i++) {
      final angle = (i / notches) * 2 * pi;
      final dx = cx + R * 0.79 * cos(angle);
      final dy = cy + R * 0.79 * sin(angle);
      canvas.drawCircle(Offset(dx, dy), R * 0.025, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_WaxSealPainter old) =>
      old.letter != letter || old.sealColor != sealColor;
}

// â”€â”€â”€ Stats row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatsRow extends StatelessWidget {
  final AppProvider provider;

  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.link_rounded,
            value: provider.links.length.toString(),
            label: 'Prompts',
            color: AnonTheme.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.chat_bubble_rounded,
            value: provider.totalResponses.toString(),
            label: 'Responses',
            color: AnonTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AnonTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AnonTheme.subtext, fontSize: 13)),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Setting tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnonTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AnonTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AnonTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        color: AnonTheme.subtext, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AnonTheme.subtext, size: 20),
        ],
      ),
    );
  }
}
