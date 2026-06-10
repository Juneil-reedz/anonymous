import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../models/prompt_model.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: Stack(
        children: [
          // Full-page scrollable content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Hero(),
                      _PromptTypeSection(),
                      _HowItWorks(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _BottomCTA(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AnonTheme.surface,
      child: Stack(
        children: [
          // Grain texture
          const Positioned.fill(child: _GrainTexture()),

          // Big "?" background watermark
          Positioned(
            right: -20,
            top: 20,
            child: Text(
              '?',
              style: TextStyle(
                color: AnonTheme.primaryLight.withValues(alpha: 0.06),
                fontSize: 280,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AnonTheme.primaryLight.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ANONYMOUS.',
                      style: TextStyle(
                        color: AnonTheme.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),

                  // Headline
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Find out',
                        style: TextStyle(
                          color: AnonTheme.primary,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -1.5,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AnonTheme.primary, AnonTheme.primaryLight],
                        ).createShader(b),
                        child: const Text(
                          'what they',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                      const Text(
                        'really think.',
                        style: TextStyle(
                          color: AnonTheme.primaryLight,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 600.ms)
                      .slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  // Thin amber rule
                  Container(
                    height: 1.5,
                    width: 64,
                    color: AnonTheme.primaryLight.withValues(alpha: 0.6),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),

                  const SizedBox(height: 16),

                  // Subline
                  const Text(
                    'Post a prompt link. Share it. Get unfiltered\nanonymous responses — no app required.',
                    style: TextStyle(
                      color: AnonTheme.subtext,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Prompt type horizontal scroll ────────────────────────────────────────────

class _PromptTypeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Skip the custom prompt type in the intro scroll
    final templates = PromptTemplate.all
        .where((t) => t.type != PromptType.customPrompt)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = templates[i];
              return _PromptTypeChip(template: t)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 80 * i))
                  .slideX(begin: 0.15);
            },
          ),
        ),
      ],
    );
  }
}

class _PromptTypeChip extends StatelessWidget {
  final PromptTemplate template;

  const _PromptTypeChip({required this.template});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(minWidth: 90),
          decoration: BoxDecoration(
            color: AnonTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(width: 3, color: template.color),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(template.icon, color: template.color, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        template.title,
                        style: const TextStyle(
                          color: AnonTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── How it works ─────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  static const _steps = [
    (
      '01',
      'Pick a Prompt',
      'Choose from Roast Me, Vibe Check, Fake Award, or make your own.',
      AnonTheme.primaryLight,
    ),
    (
      '02',
      'Share the Link',
      'Post on Facebook, Instagram, TikTok — anywhere.',
      Color(0xFF059669),
    ),
    (
      '03',
      'Get Responses',
      'Friends answer anonymously. No names. No accounts needed.',
      Color(0xFFDC2626),
    ),
    (
      '04',
      'Post the Best',
      'Turn responses into story cards. Reply and share the chaos.',
      Color(0xFF7C3AED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('HOW IT WORKS'),
          const SizedBox(height: 20),
          ..._steps.asMap().entries.map((e) {
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: _StepRow(
                number: s.$1,
                title: s.$2,
                subtitle: s.$3,
                color: s.$4,
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 + 80 * e.key))
                  .slideX(begin: 0.1),
            );
          }),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        decoration: BoxDecoration(
          color: AnonTheme.surface,
          border: Border(
            bottom: BorderSide(color: AnonTheme.cardBorder, width: 1),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left rule
              Container(width: 3, color: color),
              // Number
              Container(
                width: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  number,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Divider
              Container(
                  width: 1,
                  color: AnonTheme.cardBorder),
              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AnonTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AnonTheme.subtext,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom CTA ───────────────────────────────────────────────────────────────

class _BottomCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AnonTheme.surface,
        border: Border(top: BorderSide(color: AnonTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Tagline above button
          const Text(
            'no filters. no names. just truth.',
            style: TextStyle(
              color: AnonTheme.subtext,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AnonTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OPEN YOUR VAULT',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: Colors.black),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.black),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text(
              'Already have an account? Sign in',
              style: TextStyle(color: AnonTheme.primaryLight, fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08);
  }
}

// ─── Shared label widget ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          color: AnonTheme.primaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AnonTheme.primaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Grain texture painter ────────────────────────────────────────────────────

class _GrainTexture extends StatelessWidget {
  const _GrainTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GrainPainter());
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.022);
    for (int i = 0; i < 1200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
