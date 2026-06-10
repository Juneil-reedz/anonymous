import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/notification_service.dart';
import '../models/prompt_model.dart';

class AppProvider extends ChangeNotifier {
  static const _tokenKey = 'anon_token';
  static const _userKey = 'anon_user_v2';

  AnonUser? _user;
  List<PromptLink> _links = [];
  bool _isLoading = false;
  String? _error;

  AnonUser? get user => _user;
  List<PromptLink> get links => List.unmodifiable(_links);
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalResponses =>
      _links.fold(0, (sum, l) => sum + l.responseCount);
  int get totalUnread =>
      _links.fold(0, (sum, l) => sum + l.unreadCount);

  Future<void> init() async {
    // Wake Render's free-tier server; ignore errors
    ApiService.get('/api/health').catchError((_) => <String, dynamic>{});
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return;
    ApiService.setToken(token);
    _user = AnonUser.fromJson(json.decode(userJson) as Map<String, dynamic>);
    notifyListeners();
    await _fetchLinks();
  }

  Future<void> _fetchLinks() async {
    try {
      final data = await ApiService.get('/api/links');
      final list = data['links'] as List<dynamic>;
      _links = list
          .map((e) => PromptLink.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final data = await ApiService.post('/api/register', {
        'username': username.trim(),
        'displayName': displayName.trim().isEmpty ? username.trim() : displayName.trim(),
        'password': password,
      });
      await _saveSession(data);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final data = await ApiService.post('/api/login', {
        'username': username.trim(),
        'password': password,
      });
      await _saveSession(data);
      await _fetchLinks();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;
    _user = AnonUser.fromJson(userMap);
    ApiService.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(userMap));
    _links = [];
    notifyListeners();
    NotificationService.registerToken();
  }

  Future<void> logout() async {
    NotificationService.clearToken();
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _user = null;
    _links = [];
    notifyListeners();
  }

  Future<PromptLink?> createLink(PromptType type, {String? customQuestion}) async {
    if (_user == null) return null;
    try {
      final body = <String, dynamic>{'promptTypeKey': type.name};
      if (customQuestion != null && customQuestion.isNotEmpty) {
        body['customQuestion'] = customQuestion;
      }
      final data = await ApiService.post('/api/links', body);
      final link = PromptLink.fromJson(data['link'] as Map<String, dynamic>);
      _links.insert(0, link);
      notifyListeners();
      return link;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteLink(String linkId) async {
    try {
      await ApiService.delete('/api/links/$linkId');
      _links.removeWhere((l) => l.id == linkId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<AnonResponse>> getResponses(String linkId) async {
    try {
      final data = await ApiService.get('/api/links/$linkId/responses');
      final list = data['responses'] as List<dynamic>;
      final responses = list
          .map((e) => AnonResponse.fromJson(e as Map<String, dynamic>))
          .toList();
      final idx = _links.indexWhere((l) => l.id == linkId);
      if (idx != -1) {
        _links[idx] = _links[idx].copyWith(responseCount: responses.length, unreadCount: 0);
        notifyListeners();
      }
      // Mark all as read in background — don't await, don't block UI
      ApiService.put('/api/links/$linkId/mark-read', {}).catchError((_) => <String, dynamic>{});
      return responses;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<AnonResponse?> sendReply({
    required String linkId,
    required String responseId,
    required String reply,
  }) async {
    try {
      final data = await ApiService.post(
        '/api/links/$linkId/responses/$responseId/reply',
        {'reply': reply.trim()},
      );
      return AnonResponse.fromJson(data['response'] as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> submitResponse({
    required String shareCode,
    required String message,
  }) async {
    try {
      await ApiService.post(
        '/api/r/${shareCode.trim().toUpperCase()}/respond',
        {'message': message.trim()},
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<PromptLink?> lookupByCode(String shareCode) async {
    try {
      final data = await ApiService.get('/api/r/${shareCode.trim().toUpperCase()}');
      return PromptLink.fromJson(data['link'] as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<bool> updateProfile({String? displayName, String? avatarBase64}) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName.trim();
      if (avatarBase64 != null) body['avatarBase64'] = avatarBase64;
      final data = await ApiService.put('/api/profile', body);
      final userMap = data['user'] as Map<String, dynamic>;
      _user = AnonUser.fromJson(userMap);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_user!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ApiService.post('/api/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() => _fetchLinks();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
