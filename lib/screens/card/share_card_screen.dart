import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';
import '../story/story_invite_screen.dart';

class ShareCardScreen extends StatefulWidget {
  final AnonResponse response;
  final PromptLink link;

  const ShareCardScreen({
    super.key,
    required this.response,
    required this.link,
  });

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final _cardKey = GlobalKey();
  bool _saving = false;
  bool _sharing = false;

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
          name: 'anon_response_${widget.response.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to gallery! Open Photos to post it.'),
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

  Future<void> _saveAndShare() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _renderCard();
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/anon_response_${widget.response.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Anonymous — ${widget.link.template.title}',
      );
    } catch (e) {
      if (mounted) _showError('Could not share: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.link.template;

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AnonTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Response Card',
            style: TextStyle(
                color: AnonTheme.primary, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'PREVIEW',
              style: TextStyle(
                  color: AnonTheme.subtext,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700),
            ).animate().fadeIn(),
            const SizedBox(height: 16),

            // Card wrapped in RepaintBoundary for export
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _StoryCard(
                    template: template,
                    link: widget.link,
                    response: widget.response,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 150.ms)
                .scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 28),

            // ── Primary: Save to Device ───────────────────────────────────
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
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 10),

            // ── Secondary: Share ──────────────────────────────────────────
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
            ).animate().fadeIn(delay: 220.ms),

            const SizedBox(height: 20),

            const Text(
              'MORE OPTIONS',
              style: TextStyle(
                  color: AnonTheme.subtext,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _ShareOption(
              icon: Icons.copy_rounded,
              label: 'Copy response text',
              subtitle: 'Paste anywhere you like',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text:
                      '${template.emoji} "${widget.response.message}"\n\n— Anonymous response to "${template.question}"',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard!')),
                );
              },
            ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),

            const SizedBox(height: 10),

            _ShareOption(
              icon: Icons.auto_awesome_rounded,
              label: 'Make a Story Invite Card',
              subtitle: 'Get more anonymous responses',
              color: AnonTheme.primaryLight,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StoryInviteScreen(link: widget.link)),
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

            const SizedBox(height: 10),

            _ShareOption(
              icon: Icons.link_rounded,
              label: 'Copy invite link',
              subtitle: 'Share to get more responses',
              color: AnonTheme.primary,
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text:
                      'https://anonymous-backend-0nnv.onrender.com/r/${widget.link.shareCode}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Link copied! Share it with more friends.')),
                );
              },
            ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

// ─── Response card widget ─────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final PromptTemplate template;
  final PromptLink link;
  final AnonResponse response;

  const _StoryCard({
    required this.template,
    required this.link,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(response.createdAt);
    final r = BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: r,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              template.color,
              Color.lerp(template.color, const Color(0xFF0A0716), 0.6)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: template.color.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(template.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Anonymous',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '"${response.message}"',
              style: TextStyle(
                color: template.textColor,
                fontSize: response.message.length > 80 ? 18 : 22,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${link.username}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '# ${link.shareCode}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Share option tile ────────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AnonTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AnonTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
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
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AnonTheme.subtext, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AnonTheme.subtext, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
