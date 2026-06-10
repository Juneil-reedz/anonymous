import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../models/prompt_model.dart';
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
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, provider: provider),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _StatsRow(provider: provider).animate().fadeIn(delay: 200.ms),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'ACCOUNT',
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
              itemCount: 2,
              separatorBuilder: (_, _a) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final items = [
                  _SettingItem(
                    icon: Icons.lock_reset_rounded,
                    label: 'Change Password',
                    subtitle: 'Update your login password',
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () => _showChangePassword(context, provider),
                  ),
                  _SettingItem(
                    icon: Icons.share_rounded,
                    label: 'Share App',
                    subtitle: 'Invite friends to try Anonymous',
                    iconColor: AnonTheme.primary,
                    onTap: () => Share.share(
                      'Try Anonymous — post a prompt and get honest, anonymous replies from friends!\n\nhttps://juneil-reedz.github.io/anonymous/',
                      subject: 'Anonymous App',
                    ),
                  ),
                ];
                return _SettingTile(item: items[i])
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 280 + i * 50))
                    .slideX(begin: 0.06);
              },
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'INFO',
                style: TextStyle(
                    color: AnonTheme.subtext,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 320.ms),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: 3,
              separatorBuilder: (_, _a) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final items = [
                  _SettingItem(
                    icon: Icons.shield_outlined,
                    label: 'Privacy',
                    subtitle: 'How your anonymity is protected',
                    iconColor: const Color(0xFF059669),
                    onTap: () => _showPrivacyInfo(context),
                  ),
                  _SettingItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    subtitle: 'Get notified when someone responds',
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () => _showNotificationsInfo(context),
                  ),
                  _SettingItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Anonymous',
                    subtitle: 'no filters. no names. just truth. — v1.0.0',
                    iconColor: AnonTheme.primaryLight,
                    onTap: () => _showAbout(context),
                  ),
                ];
                return _SettingTile(item: items[i])
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 340 + i * 50))
                    .slideX(begin: 0.06);
              },
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => _ConfirmDialog(
                        title: 'Sign Out',
                        message: 'You can always log back in with your username and password.',
                        confirmLabel: 'Sign Out',
                        confirmColor: Colors.redAccent,
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    await provider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const IntroScreen()),
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

  static void _showChangePassword(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(provider: provider),
    );
  }

  static void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.shield_outlined,
        iconColor: const Color(0xFF059669),
        title: 'Your Privacy',
        items: const [
          ('100% Anonymous Responses', 'People who respond to your prompts are never identified — no name, no account, no trace.'),
          ('No Tracking', 'We don\'t store IP addresses or device identifiers tied to responses.'),
          ('Your Identity is Safe', 'Responders only see your username and your prompt question — nothing else.'),
          ('Delete Anytime', 'Deleting a prompt removes all its responses permanently.'),
        ],
      ),
    );
  }

  static void _showNotificationsInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFFF59E0B),
        title: 'Notifications',
        items: const [
          ('Push Notifications', 'You\'ll get a notification the moment someone responds to any of your prompts.'),
          ('How to Enable', 'Make sure notifications are allowed for this app in your phone\'s Settings → Apps → Anonymous.'),
          ('Android', 'Heads-up notifications appear even when the app is in the background.'),
          ('Web', 'Notifications are not supported in the web version — use the Android app for instant alerts.'),
        ],
      ),
    );
  }

  static void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.auto_awesome_rounded,
        iconColor: AnonTheme.primaryLight,
        title: 'Anonymous v1.0.0',
        items: const [
          ('What is Anonymous?', 'Post a prompt and get brutally honest, anonymous replies from your friends. No accounts needed to respond.'),
          ('Web App', 'juneil-reedz.github.io/anonymous — works on any browser, add to your home screen.'),
          ('Android App', 'Download the APK from GitHub Releases for push notifications and the full experience.'),
          ('Built with', 'Flutter · Firebase · Node.js · GitHub Pages · Render'),
        ],
        bottomWidget: _CopyLinkButton(),
      ),
    );
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatefulWidget {
  final AnonUser user;
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
    final ok = await widget.provider.updateProfile(avatarBase64: base64Encode(bytes));
    if (mounted) {
      setState(() => _saving = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.provider.error ?? 'Failed to update photo'),
              backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  Future<void> _editDisplayName() async {
    final ctrl = TextEditingController(text: widget.user.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AnonTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Display Name',
            style: TextStyle(color: AnonTheme.primary, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          style: const TextStyle(color: AnonTheme.primary),
          decoration: InputDecoration(
            hintText: 'Your display name',
            hintStyle: const TextStyle(color: AnonTheme.subtext),
            counterStyle: const TextStyle(color: AnonTheme.subtext),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AnonTheme.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AnonTheme.primaryLight, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AnonTheme.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: AnonTheme.primaryLight, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty || !mounted) return;
    setState(() => _saving = true);
    final ok = await widget.provider.updateProfile(displayName: result);
    if (mounted) {
      setState(() => _saving = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.provider.error ?? 'Failed to update name'),
              backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

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
              GestureDetector(
                onTap: _saving ? null : _pickAvatar,
                child: Stack(
                  children: [
                    if (user.avatarBase64 != null)
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AnonTheme.primaryLight, width: 2.5),
                        ),
                        child: ClipOval(
                          child: Image.memory(
                            base64Decode(user.avatarBase64!),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      WaxSealAvatar(
                        letter: user.displayName[0].toUpperCase(),
                        username: user.username,
                        size: 110,
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AnonTheme.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AnonTheme.surface, width: 2.5),
                        ),
                        child: _saving
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                color: Colors.black, size: 16),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.7, 0.7))
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Display name + edit
              GestureDetector(
                onTap: _saving ? null : _editDisplayName,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: AnonTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_rounded,
                        color: AnonTheme.subtext, size: 17),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 6),

              // Username chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AnonTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AnonTheme.primaryLight.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alternate_email_rounded,
                        color: AnonTheme.primaryLight, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: AnonTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 10),
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

// ─── Change password sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  final AppProvider provider;
  const _ChangePasswordSheet({required this.provider});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showError('All fields are required');
      return;
    }
    if (newPass.length < 6) {
      _showError('New password must be at least 6 characters');
      return;
    }
    if (newPass != confirm) {
      _showError('Passwords don\'t match');
      return;
    }

    setState(() => _saving = true);
    final error = await widget.provider.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _showError(error);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AnonTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AnonTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Change Password',
                style: TextStyle(
                    color: AnonTheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _PasswordField(
              controller: _currentCtrl,
              label: 'Current Password',
              visible: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _newCtrl,
              label: 'New Password',
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AnonTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('Update Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: const TextStyle(color: AnonTheme.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AnonTheme.subtext, fontSize: 13),
        filled: true,
        fillColor: AnonTheme.card,
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AnonTheme.subtext,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AnonTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AnonTheme.primaryLight, width: 2),
        ),
      ),
    );
  }
}

// ─── Info sheet ───────────────────────────────────────────────────────────────

class _InfoSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<(String, String)> items;
  final Widget? bottomWidget;

  const _InfoSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AnonTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AnonTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(title,
                  style: const TextStyle(
                      color: AnonTheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1,
                    style: TextStyle(
                        color: iconColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.$2,
                    style: const TextStyle(
                        color: AnonTheme.subtext,
                        fontSize: 13,
                        height: 1.45)),
              ],
            ),
          )),
          if (bottomWidget != null) ...[
            const SizedBox(height: 4),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}

// ─── Copy link button (for About sheet) ──────────────────────────────────────

class _CopyLinkButton extends StatefulWidget {
  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Clipboard.setData(const ClipboardData(
              text: 'https://juneil-reedz.github.io/anonymous/'));
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2),
              () { if (mounted) setState(() => _copied = false); });
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: _copied ? const Color(0xFF059669) : AnonTheme.primaryLight),
          foregroundColor:
              _copied ? const Color(0xFF059669) : AnonTheme.primaryLight,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(_copied ? Icons.check_rounded : Icons.link_rounded, size: 16),
        label: Text(_copied ? 'Copied!' : 'Copy Web App Link',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

// ─── Confirm dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AnonTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              color: AnonTheme.primary, fontWeight: FontWeight.w800)),
      content: Text(message,
          style: const TextStyle(color: AnonTheme.subtext, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AnonTheme.subtext)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: confirmColor, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// ─── Setting item model ───────────────────────────────────────────────────────

class _SettingItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });
}

// ─── Setting tile ─────────────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  final _SettingItem item;
  const _SettingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AnonTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AnonTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: const TextStyle(
                          color: AnonTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(item.subtitle,
                      style: const TextStyle(
                          color: AnonTheme.subtext,
                          fontSize: 12,
                          height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AnonTheme.subtext, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Wax Seal Avatar ──────────────────────────────────────────────────────────

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

  Color _sealColor() {
    const colors = [
      Color(0xFFDC2626), Color(0xFF059669), Color(0xFF7C3AED),
      Color(0xFFD97706), Color(0xFFBE185D), Color(0xFF0369A1),
      Color(0xFF065F46), Color(0xFF9A3412), Color(0xFF6D28D9),
      Color(0xFF0E7490),
    ];
    final hash = username.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WaxSealPainter(letter: letter, sealColor: _sealColor()),
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

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = sealColor.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(cx, cy), R * 0.85, glowPaint);

    const notches = 20;
    const outerR = 1.0;
    const innerR = 0.87;
    final sealPath = Path();
    for (int i = 0; i <= notches * 2; i++) {
      final angle = (i / (notches * 2)) * 2 * pi - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + R * r * cos(angle);
      final y = cy + R * r * sin(angle);
      if (i == 0) { sealPath.moveTo(x, y); } else { sealPath.lineTo(x, y); }
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

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.04;
    canvas.drawCircle(Offset(cx, cy), R * 0.68, ringPaint);

    final innerPaint = Paint()
      ..color = Color.lerp(sealColor, Colors.black, 0.5)!;
    canvas.drawCircle(Offset(cx, cy), R * 0.62, innerPaint);

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
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
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

// ─── Stats row ────────────────────────────────────────────────────────────────

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
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AnonTheme.subtext, fontSize: 13)),
        ],
      ),
    );
  }
}
