import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';

class StoryInviteScreen extends StatefulWidget {
  final PromptLink link;

  const StoryInviteScreen({super.key, required this.link});

  @override
  State<StoryInviteScreen> createState() => _StoryInviteScreenState();
}

class _StoryInviteScreenState extends State<StoryInviteScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  bool _saving = false;

  String get _url =>
      'https://anonymous-backend-0nnv.onrender.com/r/${widget.link.shareCode}';

  Future<Uint8List> _renderCard() async {
    final boundary = _cardKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveToDevice() async {
    setState(() => _saving = true);
    try {
      final bytes = await _renderCard();
      await Gal.putImageBytes(bytes,
          name: 'anon_invite_${widget.link.shareCode}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to gallery! Open Photos to post it.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndShare() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _renderCard();
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/anon_invite_${widget.link.shareCode}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Anonymous prompt — ${widget.link.template.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not export card: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied — paste it as a link sticker!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.link.template;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 48).clamp(0.0, 380.0);
    final cardH = cardW * (16 / 9);

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Story Card',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          children: [
            const Text(
              'PREVIEW',
              style: TextStyle(
                  color: AnonTheme.subtext,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // ── Card preview (also the captured widget) ──────────────────
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: _InviteCard(
                  template: template,
                  link: widget.link,
                  width: cardW,
                  height: cardH,
                  url: _url,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 32),

            // ── Tips ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AnonTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AnonTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to post on Facebook My Day',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    ('1.', 'Tap "Save & Share" below → choose Facebook'),
                    ('2.', 'Add as your Facebook My Day background'),
                    ('3.', 'Tap the link icon 🔗 and paste your link'),
                    ('4.', 'Friends tap → respond anonymously — no app needed'),
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1,
                                style: TextStyle(
                                    color: template.color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item.$2,
                                  style: const TextStyle(
                                      color: AnonTheme.subtext,
                                      fontSize: 13,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // ── Buttons ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveToDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AnonTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.download_rounded,
                        size: 20, color: Colors.black),
                label: Text(
                  _saving ? 'Saving…' : 'Save to Device',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _saveAndShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: template.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.ios_share_rounded,
                        size: 18, color: Colors.white),
                label: Text(
                  _sharing ? 'Sharing…' : 'Share Card',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
            ).animate().fadeIn(delay: 265.ms),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _copyLink,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AnonTheme.primaryLight),
                  foregroundColor: AnonTheme.primaryLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Copy Link (for link sticker)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ).animate().fadeIn(delay: 280.ms),
          ],
        ),
      ),
    );
  }
}

// ─── The actual card widget ──────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  final PromptTemplate template;
  final PromptLink link;
  final double width;
  final double height;
  final String url;

  const _InviteCard({
    required this.template,
    required this.link,
    required this.width,
    required this.height,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF050212),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: template.color.withValues(alpha: 0.5),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background glow blob — top center
            Positioned(
              top: -height * 0.15,
              left: width * 0.1,
              right: width * 0.1,
              child: Container(
                height: height * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      template.color.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom subtle glow
            Positioned(
              bottom: -height * 0.1,
              left: -width * 0.2,
              right: -width * 0.2,
              child: Container(
                height: height * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      template.color.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Decorative grid lines (subtle)
            CustomPaint(
              size: Size(width, height),
              painter: _GridPainter(),
            ),

            // Content — uses Positioned sections so the link zone is
            // anchored to the exact center of the card.
            // Top third: branding + icon
            Positioned(
              top: height * 0.06,
              left: width * 0.07,
              right: width * 0.07,
              child: Column(
                children: [
                  // Branding row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: template.color.withValues(alpha: 0.6),
                              width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'anonymous.',
                          style: TextStyle(
                            color: template.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '@${link.username}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.06),

                  // Big icon
                  Container(
                    width: width * 0.32,
                    height: width * 0.32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: template.color.withValues(alpha: 0.12),
                      border: Border.all(
                          color: template.color.withValues(alpha: 0.35),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: template.color.withValues(alpha: 0.45),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      template.icon,
                      color: template.color,
                      size: width * 0.15,
                    ),
                  ),

                  SizedBox(height: height * 0.035),

                  // Title
                  Text(
                    template.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.getFont(
                      template.fontFamily,
                      color: Colors.white,
                      fontSize: width * 0.09,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ),

                  SizedBox(height: height * 0.015),

                  // Question
                  Text(
                    template.question,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.getFont(
                      template.fontFamily,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── PASTE LINK HERE — pinned to CENTER of card ──────────────
            Positioned(
              // Center it: top = 50% height minus half of zone height (~height*0.11)
              top: height * 0.5 - height * 0.055,
              left: width * 0.07,
              right: width * 0.07,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05, vertical: height * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: template.color.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_rounded,
                            color: template.color.withValues(alpha: 0.9),
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PASTE LINK HERE',
                          style: TextStyle(
                            color: template.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.008),
                    Text(
                      'tap the link sticker & paste your link',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom tagline ─────────────────────────────────────────
            Positioned(
              bottom: height * 0.04,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'no names. no traces. just truth.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subtle grid lines background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
