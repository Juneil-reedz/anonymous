import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/web_utils.dart';
import '../../models/prompt_model.dart';

enum _CardStyle { verdict, contrast, receipt }

class ReplyCardScreen extends StatefulWidget {
  final AnonResponse response;
  final PromptLink link;

  const ReplyCardScreen({
    super.key,
    required this.response,
    required this.link,
  });

  @override
  State<ReplyCardScreen> createState() => _ReplyCardScreenState();
}

class _ReplyCardScreenState extends State<ReplyCardScreen> {
  final _cardKey = GlobalKey();
  _CardStyle _style = _CardStyle.verdict;
  bool _sharing = false;
  bool _saving = false;

  /// Renders the card to PNG bytes at 3× pixel ratio.
  Future<Uint8List> _renderCard() async {
    final boundary = _cardKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveAndShare() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _renderCard();
      if (kIsWeb) {
        await shareImageOnWeb(bytes, 'anon_reply_${widget.response.id}.png');
        if (mounted) setState(() => _sharing = false);
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/anon_reply_${widget.response.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Anonymous reply — ${widget.link.template.title}',
      );
    } catch (e) {
      if (mounted) _showError('Could not export: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _saveToDevice() async {
    setState(() => _saving = true);
    try {
      final bytes = await _renderCard();
      if (kIsWeb) {
        await saveImageOnWeb(bytes, 'anon_reply_${widget.response.id}.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image opened — long-press it and tap Save to Photos.'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
        return;
      }
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImageBytes(bytes, name: 'anon_reply_${widget.response.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to gallery! Open your Photos to post it.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyLink() async {
    final url =
        'https://anonymous-backend-0nnv.onrender.com/r/${widget.link.shareCode}';
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Link copied — paste it as a link sticker!')),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.link.template;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 48).clamp(0.0, 400.0);

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AnonTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reply Story Card',
            style: TextStyle(
                color: AnonTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          children: [
            // ── Style picker ───────────────────────────────────────────
            const Text('PICK A STYLE',
                style: TextStyle(
                    color: AnonTheme.subtext,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: _CardStyle.values.map((s) {
                final selected = s == _style;
                final label = s.name[0].toUpperCase() + s.name.substring(1);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: s != _CardStyle.receipt ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _style = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? template.color.withValues(alpha: 0.2)
                              : AnonTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? template.color
                                : AnonTheme.cardBorder,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? AnonTheme.primary
                                : AnonTheme.subtext,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            const Text('PREVIEW',
                style: TextStyle(
                    color: AnonTheme.subtext,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            // ── Card preview ───────────────────────────────────────────
            // White padding behind the RepaintBoundary ensures rounded
            // corners are captured correctly (no bleed from boxShadow).
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildCard(cardW, template),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // ── Action buttons ─────────────────────────────────────────
            // Save to Device (primary)
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
                            strokeWidth: 2, color: Colors.black))
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
            ).animate().fadeIn(delay: 180.ms),

            const SizedBox(height: 10),

            // Share (secondary)
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
                            strokeWidth: 2, color: Colors.white))
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
            ).animate().fadeIn(delay: 200.ms),

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
                label: const Text('Copy Link (for sticker)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ).animate().fadeIn(delay: 220.ms),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AnonTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AnonTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded,
                      color: template.color, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Save to Device → open Photos → post as Facebook My Day → paste your link sticker on the "PASTE LINK" zone.',
                      style: TextStyle(
                          color: AnonTheme.subtext,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 240.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(double width, PromptTemplate template) {
    switch (_style) {
      case _CardStyle.verdict:
        return _VerdictCard(
            response: widget.response, link: widget.link, width: width);
      case _CardStyle.contrast:
        return _ContrastCard(
            response: widget.response, link: widget.link, width: width);
      case _CardStyle.receipt:
        return _ReceiptCard(
            response: widget.response, link: widget.link, width: width);
    }
  }
}

// ─── Style 1: VERDICT ────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  final AnonResponse response;
  final PromptLink link;
  final double width;

  const _VerdictCard(
      {required this.response, required this.link, required this.width});

  @override
  Widget build(BuildContext context) {
    final template = link.template;
    final color = template.color;
    final r = BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: r,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF060310),
          borderRadius: r,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 50,
                spreadRadius: 2)
          ],
        ),
        child: Stack(
          children: [
            // Glow top
            Positioned(
              top: -60,
              left: -40,
              right: -40,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    color.withValues(alpha: 0.25),
                    Colors.transparent
                  ]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(width * 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(template.icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        template.title.toUpperCase(),
                        style: GoogleFonts.getFont(template.fontFamily,
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                      const Spacer(),
                      Text('@${link.username}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11)),
                    ],
                  ),
                  SizedBox(height: width * 0.06),

                  // "THEY SAID" block
                  Text('THEY SAID',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(width * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      '"${response.message}"',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.5),
                    ),
                  ),

                  // Connector
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: width * 0.04,
                        horizontal: width * 0.44),
                    child: Column(
                      children: [
                        Container(
                            width: 2,
                            height: 12,
                            color: color.withValues(alpha: 0.5)),
                        Icon(Icons.arrow_drop_down_rounded,
                            color: color, size: 22),
                      ],
                    ),
                  ),

                  // "YOUR VERDICT" block
                  Text('YOUR VERDICT',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(width * 0.05),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Text(
                      response.reply!,
                      style: GoogleFonts.getFont(
                        template.fontFamily,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: width * 0.06),
                  Center(
                    child: Text('anonymous. • no names, no traces',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 9,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Style 2: CONTRAST ────────────────────────────────────────────────────────

class _ContrastCard extends StatelessWidget {
  final AnonResponse response;
  final PromptLink link;
  final double width;

  const _ContrastCard(
      {required this.response, required this.link, required this.width});

  @override
  Widget build(BuildContext context) {
    final template = link.template;
    final color = template.color;
    final r = BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: r,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 2)
          ],
        ),
        child: Column(
          children: [
            // Top — their message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(width * 0.07),
              color: const Color(0xFF0A0716),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('anonymous.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Icon(template.icon,
                          color: Colors.white.withValues(alpha: 0.2), size: 18),
                    ],
                  ),
                  SizedBox(height: width * 0.05),
                  Text(
                    '"${response.message}"',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  ),
                ],
              ),
            ),

            // Divider with username chip
            Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 2, color: color),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('@${link.username}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),

            // Bottom — your reply
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(width * 0.07),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.5)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.reply!,
                    style: GoogleFonts.getFont(
                      template.fontFamily,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Style 3: RECEIPT ─────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final AnonResponse response;
  final PromptLink link;
  final double width;

  const _ReceiptCard(
      {required this.response, required this.link, required this.width});

  @override
  Widget build(BuildContext context) {
    final template = link.template;
    final color = template.color;
    final r = BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: r,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF0E0B1E),
          borderRadius: r,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 1)
          ],
        ),
        child: Column(
          children: [
            // Header strip
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: width * 0.07),
              color: color,
              child: Row(
                children: [
                  Icon(template.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    template.title.toUpperCase(),
                    style: GoogleFonts.getFont(template.fontFamily,
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                  const Spacer(),
                  Text('RECEIPT',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            // Their message
            Padding(
              padding: EdgeInsets.all(width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM: ANONYMOUS',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 9,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    '"${response.message}"',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  ),
                ],
              ),
            ),

            // Perforated divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: Row(
                children: List.generate(
                  20,
                  (i) => Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: i.isEven
                          ? color.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cut_rounded,
                    color: color.withValues(alpha: 0.4), size: 14),
                const SizedBox(width: 4),
                Text('TEAR HERE',
                    style: TextStyle(
                        color: color.withValues(alpha: 0.4),
                        fontSize: 8,
                        letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 4),

            // Reply section
            Padding(
              padding: EdgeInsets.all(width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('TO: @${link.username}',
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('REPLIED',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 9,
                              letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.reply!,
                    style: GoogleFonts.getFont(
                      template.fontFamily,
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: width * 0.06),
                  Center(
                    child: Text('anonymous. • your truth, unfiltered',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

