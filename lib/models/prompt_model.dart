import 'package:flutter/material.dart';

enum PromptType {
  roastMe,
  complimentMe,
  vibeCheck,
  fakeAward,
  villainEra,
  guessMySecret,
  createRumor,
  rateMe,
  confess,
  unpopularOpinion,
  customPrompt,
}

class PromptTemplate {
  final PromptType type;
  final String emoji;
  final String title;
  final String question;
  final String placeholder;
  final Color color;
  final Color textColor;
  /// Google Fonts font family name used on the story card
  final String fontFamily;
  /// Icon shown on story cards instead of emoji
  final IconData icon;

  const PromptTemplate({
    required this.type,
    required this.emoji,
    required this.title,
    required this.question,
    required this.placeholder,
    required this.color,
    this.textColor = Colors.white,
    this.fontFamily = 'Bebas Neue',
    this.icon = Icons.chat_bubble_rounded,
  });

  static const List<PromptTemplate> all = [
    PromptTemplate(
      type: PromptType.roastMe,
      emoji: '🔥',
      title: 'Roast Me',
      question: 'Roast me. Don\'t hold back.',
      placeholder: 'Your roast here... make it hurt (but funny)',
      color: Color(0xFFDC2626),
      fontFamily: 'Bebas Neue',
      icon: Icons.local_fire_department_rounded,
    ),
    PromptTemplate(
      type: PromptType.complimentMe,
      emoji: '💯',
      title: 'Compliment Me',
      question: 'Say something nice about me.',
      placeholder: 'Type a genuine compliment...',
      color: Color(0xFF059669),
      fontFamily: 'Playfair Display',
      icon: Icons.favorite_rounded,
    ),
    PromptTemplate(
      type: PromptType.vibeCheck,
      emoji: '✨',
      title: 'Vibe Check',
      question: 'Rate my vibe. Be honest.',
      placeholder: 'Describe the vibe you get from me...',
      color: Color(0xFF7C3AED),
      fontFamily: 'Orbitron',
      icon: Icons.auto_awesome_rounded,
    ),
    PromptTemplate(
      type: PromptType.fakeAward,
      emoji: '🏆',
      title: 'Give Me an Award',
      question: 'Give me a fake award I\'d actually win.',
      placeholder: 'e.g. "Most Likely to Overthink a Text Message"',
      color: Color(0xFFF59E0B),
      textColor: Color(0xFF1F2937),
      fontFamily: 'Cinzel',
      icon: Icons.emoji_events_rounded,
    ),
    PromptTemplate(
      type: PromptType.villainEra,
      emoji: '😈',
      title: 'Villain Era',
      question: 'Describe my villain era.',
      placeholder: 'What kind of villain would I be?',
      color: Color(0xFF4C1D95),
      fontFamily: 'Creepster',
      icon: Icons.electric_bolt_rounded,
    ),
    PromptTemplate(
      type: PromptType.guessMySecret,
      emoji: '🔮',
      title: 'Guess My Secret',
      question: 'What do you think my deepest secret is?',
      placeholder: 'Your theory about my secret life...',
      color: Color(0xFF5B21B6),
      fontFamily: 'Special Elite',
      icon: Icons.visibility_off_rounded,
    ),
    PromptTemplate(
      type: PromptType.createRumor,
      emoji: '📣',
      title: 'Create a Rumor',
      question: 'Start a ridiculous rumor about me.',
      placeholder: 'Make it chaotic and unhinged...',
      color: Color(0xFFBE185D),
      fontFamily: 'Anton',
      icon: Icons.campaign_rounded,
    ),
    PromptTemplate(
      type: PromptType.rateMe,
      emoji: '⭐',
      title: 'Rate Me',
      question: 'Rate me out of 10. Justify your score.',
      placeholder: 'X/10 because...',
      color: Color(0xFF0369A1),
      fontFamily: 'Exo 2',
      icon: Icons.star_rounded,
    ),
    PromptTemplate(
      type: PromptType.confess,
      emoji: '🤫',
      title: 'Confess',
      question: 'Confess something to me anonymously.',
      placeholder: 'Get it off your chest...',
      color: Color(0xFF065F46),
      fontFamily: 'Caveat',
      icon: Icons.lock_rounded,
    ),
    PromptTemplate(
      type: PromptType.unpopularOpinion,
      emoji: '💬',
      title: 'Unpopular Opinion',
      question: 'Share an unpopular opinion about me.',
      placeholder: 'Say what others won\'t...',
      color: Color(0xFF92400E),
      fontFamily: 'Fredoka',
      icon: Icons.record_voice_over_rounded,
    ),
    PromptTemplate(
      type: PromptType.customPrompt,
      emoji: '✏️',
      title: 'Make Your Own',
      question: 'Write your own prompt question.',
      placeholder: 'Type your response here...',
      color: Color(0xFFC9A87C),
      textColor: Color(0xFF1F150C),
      fontFamily: 'Caveat',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  static PromptTemplate forType(PromptType type) =>
      all.firstWhere((t) => t.type == type);

  static PromptTemplate fromKey(String key) {
    final type = PromptType.values.firstWhere(
      (t) => t.name == key,
      orElse: () => PromptType.roastMe,
    );
    return forType(type);
  }
}

class PromptLink {
  final String id;
  final String userId;
  final String username;
  final String promptTypeKey;
  final String shareCode;
  final DateTime createdAt;
  final bool isActive;
  final int responseCount;
  final String? customQuestion;

  const PromptLink({
    required this.id,
    required this.userId,
    required this.username,
    required this.promptTypeKey,
    required this.shareCode,
    required this.createdAt,
    this.isActive = true,
    this.responseCount = 0,
    this.customQuestion,
  });

  PromptTemplate get template {
    if (promptTypeKey == 'customPrompt' &&
        customQuestion != null &&
        customQuestion!.isNotEmpty) {
      final base = PromptTemplate.forType(PromptType.customPrompt);
      return PromptTemplate(
        type: PromptType.customPrompt,
        emoji: base.emoji,
        title: base.title,
        question: customQuestion!,
        placeholder: base.placeholder,
        color: base.color,
        textColor: base.textColor,
        fontFamily: base.fontFamily,
        icon: base.icon,
      );
    }
    return PromptTemplate.fromKey(promptTypeKey);
  }

  PromptLink copyWith({int? responseCount, bool? isActive}) => PromptLink(
        id: id,
        userId: userId,
        username: username,
        promptTypeKey: promptTypeKey,
        shareCode: shareCode,
        createdAt: createdAt,
        isActive: isActive ?? this.isActive,
        responseCount: responseCount ?? this.responseCount,
        customQuestion: customQuestion,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'promptTypeKey': promptTypeKey,
        'shareCode': shareCode,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'responseCount': responseCount,
        if (customQuestion != null) 'customQuestion': customQuestion,
      };

  factory PromptLink.fromJson(Map<String, dynamic> json) => PromptLink(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String,
        promptTypeKey: json['promptTypeKey'] as String,
        shareCode: json['shareCode'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
        responseCount: json['responseCount'] as int? ?? 0,
        customQuestion: json['customQuestion'] as String?,
      );
}

class AnonResponse {
  final String id;
  final String linkId;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? reply;
  final DateTime? repliedAt;

  const AnonResponse({
    required this.id,
    required this.linkId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.reply,
    this.repliedAt,
  });

  bool get hasReply => reply != null && reply!.isNotEmpty;

  AnonResponse copyWith({bool? isRead, String? reply, DateTime? repliedAt}) =>
      AnonResponse(
        id: id,
        linkId: linkId,
        message: message,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        reply: reply ?? this.reply,
        repliedAt: repliedAt ?? this.repliedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'linkId': linkId,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        if (reply != null) 'reply': reply,
        if (repliedAt != null) 'repliedAt': repliedAt!.toIso8601String(),
      };

  factory AnonResponse.fromJson(Map<String, dynamic> json) => AnonResponse(
        id: json['id'] as String,
        linkId: json['linkId'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        reply: json['reply'] as String?,
        repliedAt: json['repliedAt'] != null
            ? DateTime.parse(json['repliedAt'] as String)
            : null,
      );
}

class AnonUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarBase64;

  const AnonUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarBase64,
  });

  AnonUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarBase64,
  }) =>
      AnonUser(
        id: id ?? this.id,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        avatarBase64: avatarBase64 ?? this.avatarBase64,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        if (avatarBase64 != null) 'avatarBase64': avatarBase64,
      };

  factory AnonUser.fromJson(Map<String, dynamic> json) => AnonUser(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        avatarBase64: json['avatarBase64'] as String?,
      );
}
