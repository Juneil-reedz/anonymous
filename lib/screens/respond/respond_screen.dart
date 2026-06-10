import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';
import '../../providers/app_provider.dart';

class RespondScreen extends StatefulWidget {
  const RespondScreen({super.key});

  @override
  State<RespondScreen> createState() => _RespondScreenState();
}

class _RespondScreenState extends State<RespondScreen> {
  final _codeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  PromptLink? _foundLink;
  bool _looking = false;
  bool _sending = false;
  bool _sent = false;
  String? _lookupError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _looking = true;
      _lookupError = null;
      _foundLink = null;
    });
    final provider = context.read<AppProvider>();
    final link = await provider.lookupByCode(code);
    setState(() {
      _looking = false;
      if (link == null) {
        _lookupError = 'No prompt found for code "$code". Check with your friend.';
      } else if (!link.isActive) {
        _lookupError = 'This prompt link has been closed.';
      } else {
        _foundLink = link;
      }
    });
  }

  Future<void> _send() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    final provider = context.read<AppProvider>();
    final ok = await provider.submitResponse(
      shareCode: _codeCtrl.text,
      message: msg,
    );
    setState(() {
      _sending = false;
      _sent = ok;
      if (!ok) _lookupError = provider.error;
    });
  }

  void _reset() {
    setState(() {
      _codeCtrl.clear();
      _messageCtrl.clear();
      _foundLink = null;
      _sent = false;
      _lookupError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Respond',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              const Text(
                'Got a code from a friend? Enter it below and respond anonymously.',
                style: TextStyle(
                    color: AnonTheme.subtext, fontSize: 15, height: 1.4),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              if (_sent)
                _SentView(onReset: _reset)
              else if (_foundLink != null)
                _PromptResponseView(
                  link: _foundLink!,
                  messageCtrl: _messageCtrl,
                  sending: _sending,
                  onSend: _send,
                  onBack: () => setState(() => _foundLink = null),
                )
              else
                _CodeEntryView(
                  codeCtrl: _codeCtrl,
                  looking: _looking,
                  error: _lookupError,
                  onLookup: _lookup,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeEntryView extends StatelessWidget {
  final TextEditingController codeCtrl;
  final bool looking;
  final String? error;
  final VoidCallback onLookup;

  const _CodeEntryView({
    required this.codeCtrl,
    required this.looking,
    required this.error,
    required this.onLookup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AnonTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AnonTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔑',
                  style: TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              const Text(
                'Enter the 8-character code',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your friend shared a code when they created their prompt.',
                style: TextStyle(
                    color: AnonTheme.subtext, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: 'ABC12345',
                  hintStyle: const TextStyle(
                    color: Color(0xFF374151),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                  counterText: '',
                  errorText: error,
                  errorStyle: const TextStyle(color: Color(0xFFF87171)),
                ),
                onSubmitted: (_) => onLookup(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: looking ? null : onLookup,
                  child: looking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('FIND PROMPT',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        const SizedBox(height: 32),
        const Text(
          'How this works',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...[
          ('1', 'Enter the code your friend shared'),
          ('2', 'See their prompt and respond honestly'),
          ('3', 'Your identity stays 100% anonymous'),
        ].map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AnonTheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(step.$1,
                          style: const TextStyle(
                              color: AnonTheme.primaryLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(step.$2,
                      style: const TextStyle(
                          color: AnonTheme.subtext, fontSize: 14)),
                ],
              ),
            )),
      ],
    );
  }
}

class _PromptResponseView extends StatelessWidget {
  final PromptLink link;
  final TextEditingController messageCtrl;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onBack;

  const _PromptResponseView({
    required this.link,
    required this.messageCtrl,
    required this.sending,
    required this.onSend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final template = link.template;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Row(
            children: [
              Icon(Icons.arrow_back_rounded,
                  color: AnonTheme.subtext, size: 18),
              SizedBox(width: 6),
              Text('Change code',
                  style: TextStyle(
                      color: AnonTheme.subtext, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: template.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: template.color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Text(template.emoji,
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                '@${link.username} asks:',
                style: const TextStyle(
                    color: AnonTheme.subtext, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                template.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.96, 0.96)),
        const SizedBox(height: 24),
        const Text(
          'Your anonymous response',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: messageCtrl,
          maxLines: 5,
          maxLength: 300,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: template.placeholder,
            counterStyle: const TextStyle(color: AnonTheme.subtext),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: AnonTheme.subtext, size: 14),
            const SizedBox(width: 6),
            const Text(
              'Your identity is completely anonymous',
              style: TextStyle(color: AnonTheme.subtext, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: sending ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: template.color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              sending ? 'Sending...' : 'SEND ANONYMOUSLY',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}

class _SentView extends StatelessWidget {
  final VoidCallback onReset;

  const _SentView({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 44),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 24),
          const Text(
            'Response sent! 🎉',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 10),
          const Text(
            'Your anonymous response has been delivered.\nThey\'ll never know it was you.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AnonTheme.subtext, fontSize: 15, height: 1.5),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AnonTheme.primaryLight),
              foregroundColor: AnonTheme.primaryLight,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.reply_rounded, size: 18),
            label: const Text('Respond to Another',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
