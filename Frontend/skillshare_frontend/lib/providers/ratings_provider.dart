import 'package:flutter/foundation.dart';

import '../models/rating_stats.dart';
import '../services/rating_service.dart';

class RatingsProvider extends ChangeNotifier {
  final RatingService _ratingService;

  final Map<int, RatingStats> _userStats = {};
  final Map<int, RatingStats> _skillStats = {};
  final Map<int, RatingStats> _sessionStats = {};

  final Set<int> _userLoading = {};
  final Set<int> _skillLoading = {};
  final Set<int> _sessionLoading = {};

  RatingsProvider({RatingService? ratingService})
      : _ratingService = ratingService ?? RatingService();

  RatingStats? userStats(int userId) => _userStats[userId];
  RatingStats? skillStats(int skillId) => _skillStats[skillId];
  RatingStats? sessionStats(int sessionId) => _sessionStats[sessionId];

  bool isUserLoading(int userId) => _userLoading.contains(userId);
  bool isSkillLoading(int skillId) => _skillLoading.contains(skillId);
  bool isSessionLoading(int sessionId) => _sessionLoading.contains(sessionId);

  Future<void> ensureUser(int userId) async {
    if (_userStats.containsKey(userId) || _userLoading.contains(userId)) return;
    _userLoading.add(userId);
    notifyListeners();
    try {
      final stats = await _ratingService.getUserRating(userId);
      _userStats[userId] = stats;
    } finally {
      _userLoading.remove(userId);
      notifyListeners();
    }
  }

  Future<void> ensureSkill(int skillId) async {
    if (_skillStats.containsKey(skillId) || _skillLoading.contains(skillId)) {
      return;
    }
    _skillLoading.add(skillId);
    notifyListeners();
    try {
      final stats = await _ratingService.getSkillRating(skillId);
      _skillStats[skillId] = stats;
    } finally {
      _skillLoading.remove(skillId);
      notifyListeners();
    }
  }

  Future<void> ensureSession(int sessionId) async {
    if (_sessionStats.containsKey(sessionId) ||
        _sessionLoading.contains(sessionId)) {
      return;
    }
    _sessionLoading.add(sessionId);
    notifyListeners();
    try {
      final stats = await _ratingService.getSessionRating(sessionId);
      _sessionStats[sessionId] = stats;
    } finally {
      _sessionLoading.remove(sessionId);
      notifyListeners();
    }
  }

  void clear() {
    _userStats.clear();
    _skillStats.clear();
    _sessionStats.clear();
    _userLoading.clear();
    _skillLoading.clear();
    _sessionLoading.clear();
    notifyListeners();
  }
}
