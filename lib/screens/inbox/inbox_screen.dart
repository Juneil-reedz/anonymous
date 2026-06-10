import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';
import '../../providers/app_provider.dart';
import '../card/reply_card_screen.dart';
import '../card/share_card_screen.dart';

class InboxScreen extends StatefulWidget {
  final PromptLink link;

  const InboxScreen({super.key, required this.link});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<AnonResponse> _responses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<AppProvider>();
    final responses = await provider.getResponses(widget.link.id);
    if (mounted) {
      setState(() {
        _responses = responses;
        _loading = false;
      });
    }
  }

  void _updateResponse(AnonResponse updated) {
    setState(() {
      final idx = _responses.indexWhere((r) => r.id == updated.id);
      if (idx != -1) _responses[idx] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.link.template;

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: Column(
        children: [
          _InboxHeader(template: template, link: widget.link),
          if (_loading)
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: AnonTheme.primary)),
            )
          else if (_responses.isEmpty)
            const Expanded(child: _NoResponses())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 40),
                itemCount: _responses.length,
                itemBuilder: (context, i) {
                  final r = _responses[i];
                  final num = (_responses.length - i).toString().padLeft(2, '0');
                  return _ResponseRow(
                    key: ValueKey(r.id),
                    response: r,
                    link: widget.link,
                    template: template,
                    cardNumber: num,
                    onReplyPosted: _updateResponse,
                    onShare: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ShareCardScreen(response: r, link: widget.link),
                      ),
                    ),
                    onShareReply: (updated) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReplyCardScreen(
                          response: updated,
                          link: widget.link,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 50 * i))
                      .slideX(begin: 0.05);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Inbox header ─────────────────────────────────────────────────────────────

class _InboxHeader extends StatelessWidget {
  final PromptTemplate template;
  final PromptLink link;

  const _InboxHeader({required this.template, required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AnonTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AnonTheme.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: AnonTheme.card,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Slash-label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INBOX',
                        style: TextStyle(
                          color: AnonTheme.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        template.title,
                        style: const TextStyle(
                          color: AnonTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Prompt question — full editorial block
          ClipRect(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AnonTheme.cardBorder),
                  bottom: BorderSide(color: AnonTheme.cardBorder),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3, color: template.color),
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: AnonTheme.cardBorder)),
                      ),
                      child: Icon(template.icon,
                          color: template.color, size: 20),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.question,
                              style: const TextStyle(
                                color: AnonTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: template.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${link.responseCount.toString().padLeft(2, '0')} RESPONSES',
                                    style: TextStyle(
                                      color: template.color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '# ${link.shareCode}',
                                  style: const TextStyle(
                                    color: AnonTheme.subtext,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No responses state ───────────────────────────────────────────────────────

class _NoResponses extends StatelessWidget {
  const _NoResponses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border:
                    Border.all(color: AnonTheme.cardBorder, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_rounded,
                      color: AnonTheme.subtext, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '00',
                    style: TextStyle(
                      color: AnonTheme.subtext.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'NO RESPONSES YET',
              style: TextStyle(
                color: AnonTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            const Text(
              'Share your link and wait for the chaos to arrive.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AnonTheme.subtext, fontSize: 14, height: 1.6),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Response row (editorial style) ──────────────────────────────────────────

class _ResponseRow extends StatefulWidget {
  final AnonResponse response;
  final PromptLink link;
  final PromptTemplate template;
  final String cardNumber;
  final ValueChanged<AnonResponse> onReplyPosted;
  final VoidCallback onShare;
  final ValueChanged<AnonResponse> onShareReply;

  const _ResponseRow({
    super.key,
    required this.response,
    required this.link,
    required this.template,
    required this.cardNumber,
    required this.onReplyPosted,
    required this.onShare,
    required this.onShareReply,
  });

  @override
  State<_ResponseRow> createState() => _ResponseRowState();
}

class _ResponseRowState extends State<_ResponseRow> {
  bool _showReplyInput = false;
  final _replyCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _postReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    final provider = context.read<AppProvider>();
    final updated = await provider.sendReply(
      linkId: widget.link.id,
      responseId: widget.response.id,
      reply: text,
    );
    if (!mounted) return;
    setState(() {
      _posting = false;
      _showReplyInput = false;
    });
    if (updated != null) {
      widget.onReplyPosted(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to post reply'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    final color = widget.template.color;

    return Container(
      decoration: BoxDecoration(
        color: AnonTheme.card,
        border: Border(
          bottom: BorderSide(color: AnonTheme.cardBorder, width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color rule
            Container(width: 3, color: color),

            // Number column
            Container(
              width: 48,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: AnonTheme.cardBorder, width: 1),
                ),
              ),
              child: Text(
                widget.cardNumber,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AnonTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AnonTheme.cardBorder),
                          ),
                          child: const Center(
                            child: Icon(Icons.person_outline_rounded,
                                color: AnonTheme.subtext, size: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ANONYMOUS',
                                style: TextStyle(
                                  color: AnonTheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                _timeAgo(r.createdAt),
                                style: const TextStyle(
                                    color: AnonTheme.subtext, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Message
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Text(
                      r.message,
                      style: const TextStyle(
                        color: AnonTheme.primary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Existing reply
                  if (r.hasReply) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(color: color, width: 2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR REPLY',
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(r.reply!,
                              style: const TextStyle(
                                color: AnonTheme.primary,
                                fontSize: 14,
                                height: 1.4,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Reply input
                  if (_showReplyInput && !r.hasReply)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyCtrl,
                              autofocus: true,
                              maxLength: 300,
                              style: const TextStyle(
                                  color: AnonTheme.primary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Type your reply...',
                                hintStyle:
                                    const TextStyle(color: AnonTheme.subtext),
                                filled: true,
                                fillColor: AnonTheme.surface,
                                counterStyle: const TextStyle(
                                    color: AnonTheme.subtext),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: color.withValues(alpha: 0.4)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: color, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AnonTheme.cardBorder),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _posting
                              ? const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AnonTheme.primary))
                              : IconButton(
                                  onPressed: _postReply,
                                  icon: Icon(Icons.send_rounded, color: color,
                                      size: 18),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        color.withValues(alpha: 0.12),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                        ],
                      ),
                    ),

                  // Action row
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AnonTheme.cardBorder, width: 1)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        if (!r.hasReply)
                          _ActionBtn(
                            icon: _showReplyInput
                                ? Icons.close_rounded
                                : Icons.reply_rounded,
                            label: _showReplyInput ? 'CANCEL' : 'REPLY',
                            color: color,
                            onTap: () => setState(
                                () => _showReplyInput = !_showReplyInput),
                          ),
                        const Spacer(),
                        if (r.hasReply)
                          _ActionBtn(
                            icon: Icons.ios_share_rounded,
                            label: 'SHARE REPLY',
                            color: color,
                            onTap: () => widget.onShareReply(r),
                          ),
                      ],
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
