import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';
import '../../providers/app_provider.dart';
import '../story/story_invite_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  PromptType? _selected;
  PromptLink? _createdLink;
  bool _creating = false;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  bool get _canCreate {
    if (_selected == null) return false;
    if (_selected == PromptType.customPrompt) {
      return _customCtrl.text.trim().length >= 5;
    }
    return true;
  }

  Future<void> _create() async {
    if (_selected == null) return;
    setState(() => _creating = true);
    final provider = context.read<AppProvider>();
    final customQ = _selected == PromptType.customPrompt
        ? _customCtrl.text.trim()
        : null;
    final link = await provider.createLink(_selected!, customQuestion: customQ);
    if (!mounted) return;
    if (link == null) {
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create link. Is the server awake?'),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        ),
      );
      provider.clearError();
      return;
    }
    setState(() {
      _createdLink = link;
      _creating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnonTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('New Prompt Link',
            style: TextStyle(
                color: AnonTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AnonTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _createdLink != null
          ? _LinkCreatedView(link: _createdLink!)
          : _PickerView(
              selected: _selected,
              creating: _creating,
              canCreate: _canCreate,
              customCtrl: _customCtrl,
              onSelect: (t) => setState(() => _selected = t),
              onCreate: _create,
            ),
    );
  }
}

// ─── Picker ───────────────────────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  final PromptType? selected;
  final bool creating;
  final bool canCreate;
  final TextEditingController customCtrl;
  final ValueChanged<PromptType> onSelect;
  final VoidCallback onCreate;

  const _PickerView({
    required this.selected,
    required this.creating,
    required this.canCreate,
    required this.customCtrl,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick a prompt type',
                  style: TextStyle(
                    color: AnonTheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 6),
                const Text(
                  'Your friends respond anonymously — no account needed.',
                  style: TextStyle(color: AnonTheme.subtext, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 24),

                // All preset templates (skip customPrompt — shown last as special)
                ...PromptTemplate.all
                    .where((t) => t.type != PromptType.customPrompt)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  final isSelected = selected == t.type;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TemplateCard(
                      template: t,
                      isSelected: isSelected,
                      onTap: () => onSelect(t.type),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 40 * i))
                        .slideX(begin: 0.08),
                  );
                }),

                // ── Custom prompt card ─────────────────────────────────────
                const SizedBox(height: 6),
                _CustomCard(
                  isSelected: selected == PromptType.customPrompt,
                  ctrl: customCtrl,
                  onTap: () => onSelect(PromptType.customPrompt),
                )
                    .animate()
                    .fadeIn(delay: 450.ms)
                    .slideX(begin: 0.08),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Generate button ────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canCreate && !creating ? onCreate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCreate ? AnonTheme.primary : AnonTheme.card,
                disabledBackgroundColor: AnonTheme.card,
              ),
              child: creating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black),
                    )
                  : Text(
                      selected == null
                          ? 'Select a prompt first'
                          : selected == PromptType.customPrompt &&
                                  customCtrl.text.trim().length < 5
                              ? 'Write your question (min 5 chars)'
                              : 'GENERATE MY LINK',
                      style: TextStyle(
                          color: canCreate ? Colors.black : AnonTheme.subtext,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.5),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Custom card ──────────────────────────────────────────────────────────────

class _CustomCard extends StatelessWidget {
  final bool isSelected;
  final TextEditingController ctrl;
  final VoidCallback onTap;

  const _CustomCard({
    required this.isSelected,
    required this.ctrl,
    required this.onTap,
  });

  static const _color = Color(0xFFC9A87C);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? _color.withValues(alpha: 0.12)
            : AnonTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? _color : AnonTheme.primaryLight.withValues(alpha: 0.35),
          width: isSelected ? 2 : 1.5,
          // dashed look via solid border — CustomPainter not needed here
        ),
      ),
      child: Column(
        children: [
          // Header row — always tappable
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: _color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Make Your Own',
                              style: TextStyle(
                                  color: AnonTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('CUSTOM',
                                  style: TextStyle(
                                      color: _color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Write exactly what you want people to answer.',
                          style:
                              TextStyle(color: AnonTheme.subtext, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: _color, size: 22),
                ],
              ),
            ),
          ),

          // Expandable text field
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: isSelected
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          color: _color.withValues(alpha: 0.25),
                          margin: const EdgeInsets.only(bottom: 14),
                        ),
                        const Text(
                          'YOUR QUESTION',
                          style: TextStyle(
                              color: _color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: ctrl,
                          autofocus: true,
                          maxLength: 150,
                          maxLines: 3,
                          minLines: 2,
                          style: const TextStyle(
                              color: AnonTheme.primary,
                              fontSize: 15,
                              height: 1.4),
                          decoration: InputDecoration(
                            hintText:
                                'e.g. What\'s one thing you\'d never tell me to my face?',
                            hintStyle: TextStyle(
                                color: AnonTheme.subtext.withValues(alpha: 0.7),
                                fontSize: 14),
                            filled: true,
                            fillColor: AnonTheme.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: _color, width: 1.5),
                            ),
                            counterStyle: const TextStyle(
                                color: AnonTheme.subtext, fontSize: 11),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Preset template card ─────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final PromptTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? template.color.withValues(alpha: 0.15)
              : AnonTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? template.color : AnonTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: template.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(template.icon, color: template.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: const TextStyle(
                      color: AnonTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    template.question,
                    style: const TextStyle(
                        color: AnonTheme.subtext, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: template.color, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Link created view ────────────────────────────────────────────────────────

class _LinkCreatedView extends StatelessWidget {
  final PromptLink link;

  const _LinkCreatedView({required this.link});

  String get _url =>
      'https://anonymous-backend-0nnv.onrender.com/r/${link.shareCode}';

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied! Paste it anywhere.')),
    );
  }

  void _shareText(BuildContext context) {
    final template = link.template;
    final text =
        '${template.emoji} ${template.question}\n\nRespond anonymously 👇\n$_url';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Share text copied! Paste it on Facebook, IG, anywhere.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = link.template;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF14532D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF22C55E), size: 44),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
          const Text(
            'Prompt link created!',
            style: TextStyle(
                color: AnonTheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.w900),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          const Text(
            'Share your link — anyone can respond in their browser.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AnonTheme.subtext, fontSize: 15),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: template.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: template.color.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: template.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(template.icon, color: template.color, size: 36),
                ),
                const SizedBox(height: 10),
                Text(
                  template.title,
                  style: const TextStyle(
                      color: AnonTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  template.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AnonTheme.subtext, fontSize: 14),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 350.ms)
              .scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AnonTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AnonTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR LINK',
                    style: TextStyle(
                        color: AnonTheme.subtext,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  _url,
                  style: const TextStyle(
                    color: AnonTheme.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Anyone who taps this opens the respond page in their browser — no app needed.',
                  style: TextStyle(
                      color: AnonTheme.subtext, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _copyLink(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AnonTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('COPY LINK',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5)),
            ),
          ).animate().fadeIn(delay: 420.ms),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StoryInviteScreen(link: link)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AnonTheme.surface,
                side: const BorderSide(color: AnonTheme.primaryLight, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AnonTheme.primaryLight),
              label: const Text('MAKE STORY CARD',
                  style: TextStyle(
                      color: AnonTheme.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ).animate().fadeIn(delay: 440.ms),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: () => _shareText(context),
              icon: const Icon(Icons.copy_rounded,
                  size: 16, color: AnonTheme.subtext),
              label: const Text('Copy with message text',
                  style: TextStyle(color: AnonTheme.subtext, fontSize: 13)),
            ),
          ).animate().fadeIn(delay: 460.ms),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to My Links',
                  style: TextStyle(color: AnonTheme.subtext)),
            ),
          ),
        ],
      ),
    );
  }
}
