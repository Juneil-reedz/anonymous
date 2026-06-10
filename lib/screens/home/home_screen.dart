import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';
import '../../providers/app_provider.dart';
import '../create/create_screen.dart';
import '../inbox/inbox_screen.dart';
import '../story/story_invite_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AnonTheme.bg,
      body: RefreshIndicator(
        color: AnonTheme.primary,
        backgroundColor: AnonTheme.card,
        onRefresh: () async => provider.refresh(),
        child: CustomScrollView(
          slivers: [
            _VaultHeader(provider: provider),
            if (provider.links.isEmpty)
              const SliverFillRemaining(child: _EmptyVault())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                sliver: SliverList.builder(
                  itemCount: provider.links.length,
                  itemBuilder: (context, i) {
                    final link = provider.links[i];
                    final num = (provider.links.length - i)
                        .toString()
                        .padLeft(2, '0');
                    return _LinkRow(
                      link: link,
                      cardNumber: num,
                      onViewInbox: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => InboxScreen(link: link)),
                      ),
                      onStoryCard: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StoryInviteScreen(link: link)),
                      ),
                      onDelete: () =>
                          _confirmDelete(context, provider, link.id),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 60 * i))
                        .slideX(begin: 0.05);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _NewPromptButton(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppProvider provider, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AnonTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete prompt?',
            style: TextStyle(
                color: AnonTheme.primary, fontWeight: FontWeight.w800)),
        content: const Text(
          'This will permanently delete the link and all its responses.',
          style: TextStyle(color: AnonTheme.subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: AnonTheme.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) await provider.deleteLink(id);
  }
}

// ─── Vault header ─────────────────────────────────────────────────────────────

class _VaultHeader extends StatelessWidget {
  final AppProvider provider;
  const _VaultHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final user = provider.user!;
    final total = provider.links.length;
    final resp = provider.totalResponses;

    return SliverToBoxAdapter(
      child: Container(
        color: AnonTheme.surface,
        child: Stack(
          children: [
            const Positioned.fill(child: _Grain()),

            // Rotated background stamp
            Positioned(
              right: -18,
              top: 60,
              child: Transform.rotate(
                angle: -0.35,
                child: Text(
                  'CLASSIFIED',
                  style: TextStyle(
                    color: AnonTheme.primaryLight.withValues(alpha: 0.04),
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar: slash-label + username
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          color: AnonTheme.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'VAULT / MY PROMPTS',
                          style: TextStyle(
                            color: AnonTheme.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  AnonTheme.primaryLight.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: AnonTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Display headline
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR',
                          style: TextStyle(
                            color: AnonTheme.subtext,
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AnonTheme.primary, AnonTheme.primaryLight],
                          ).createShader(b),
                          child: const Text(
                            'VAULT.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 80.ms)
                        .slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Thin amber divider
                    Container(
                      height: 1,
                      color: AnonTheme.primaryLight.withValues(alpha: 0.25),
                    ),

                    const SizedBox(height: 14),

                    // Stats line: editorial inline
                    Row(
                      children: [
                        _StatBadge(value: total.toString().padLeft(2, '0'),
                            label: 'PROMPTS'),
                        Container(
                          width: 1,
                          height: 28,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 14),
                          color: AnonTheme.cardBorder,
                        ),
                        _StatBadge(
                          value: resp.toString().padLeft(2, '0'),
                          label: 'RESPONSES',
                          accent: resp > 0,
                        ),
                        if (resp > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AnonTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: AnonTheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ).animate().fadeIn(delay: 160.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _StatBadge({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent ? AnonTheme.primary : AnonTheme.primary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AnonTheme.subtext,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Empty vault ──────────────────────────────────────────────────────────────

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big hollow lock
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AnonTheme.primaryLight.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AnonTheme.primaryLight, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    'EMPTY',
                    style: TextStyle(
                      color: AnonTheme.primaryLight.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 28),

            const Text(
              'VAULT IS EMPTY',
              style: TextStyle(
                color: AnonTheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 10),

            const Text(
              'Create a prompt link and find out\nwhat people really think about you.',
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

// ─── Link row (editorial card) ────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  final PromptLink link;
  final String cardNumber;
  final VoidCallback onViewInbox;
  final VoidCallback onStoryCard;
  final VoidCallback onDelete;

  const _LinkRow({
    required this.link,
    required this.cardNumber,
    required this.onViewInbox,
    required this.onStoryCard,
    required this.onDelete,
  });

  String get _url =>
      'https://anonymous-backend-0nnv.onrender.com/r/${link.shareCode}';

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied — share it anywhere!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = link.template;
    final hasResponses = link.responseCount > 0;

    return GestureDetector(
      onTap: onViewInbox,
      child: Container(
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
              Container(width: 3, color: template.color),

              // Number column
              Container(
                width: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AnonTheme.cardBorder, width: 1),
                  ),
                ),
                child: Text(
                  cardNumber,
                  style: TextStyle(
                    color: template.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + title row
                      Row(
                        children: [
                          Icon(template.icon,
                              color: template.color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              template.title,
                              style: const TextStyle(
                                color: AnonTheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded,
                                color: AnonTheme.subtext, size: 20),
                            color: AnonTheme.surface,
                            onSelected: (v) {
                              if (v == 'copy') _copyLink(context);
                              if (v == 'story') onStoryCard();
                              if (v == 'delete') onDelete();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'copy',
                                child: Row(children: [
                                  Icon(Icons.link_rounded,
                                      color: AnonTheme.primary, size: 17),
                                  SizedBox(width: 10),
                                  Text('Copy Link',
                                      style:
                                          TextStyle(color: AnonTheme.primary)),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'story',
                                child: Row(children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      color: AnonTheme.primaryLight, size: 17),
                                  SizedBox(width: 10),
                                  Text('Story Card',
                                      style: TextStyle(
                                          color: AnonTheme.primary)),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline_rounded,
                                      color: Colors.redAccent, size: 17),
                                  SizedBox(width: 10),
                                  Text('Delete',
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        template.question,
                        style: const TextStyle(
                            color: AnonTheme.subtext,
                            fontSize: 12,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Bottom meta row
                      Row(
                        children: [
                          // Response badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasResponses
                                  ? template.color.withValues(alpha: 0.15)
                                  : AnonTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hasResponses
                                    ? template.color.withValues(alpha: 0.4)
                                    : AnonTheme.cardBorder,
                              ),
                            ),
                            child: Text(
                              '${link.responseCount.toString().padLeft(2, '0')} ${link.responseCount == 1 ? 'REPLY' : 'REPLIES'}',
                              style: TextStyle(
                                color: hasResponses
                                    ? template.color
                                    : AnonTheme.subtext,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Inbox arrow
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: hasResponses
                                  ? template.color.withValues(alpha: 0.12)
                                  : AnonTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'INBOX',
                                  style: TextStyle(
                                    color: hasResponses
                                        ? template.color
                                        : AnonTheme.subtext,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: hasResponses
                                      ? template.color
                                      : AnonTheme.subtext,
                                ),
                              ],
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
    );
  }
}

// ─── New Prompt button ────────────────────────────────────────────────────────

class _NewPromptButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewPromptButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AnonTheme.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 8,
            shadowColor: AnonTheme.primary.withValues(alpha: 0.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 20, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'NEW PROMPT',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grain texture ────────────────────────────────────────────────────────────

class _Grain extends StatelessWidget {
  const _Grain();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GrainPainter());
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(13);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    for (int i = 0; i < 1000; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.9,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
