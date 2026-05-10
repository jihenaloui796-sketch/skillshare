import 'package:flutter/foundation.dart';

import '../models/review.dart';
import '../models/session_item.dart';
import '../models/skill.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/request_service.dart';
import '../services/review_service.dart';
import '../services/session_service.dart';
import '../services/skill_service.dart';

class DashboardStats {
  final int totalSkills;
  final int totalRequests;
  final int acceptedRequests;
  final int totalReviews;
  final double averageRating;
  final int activeSessions;

  const DashboardStats({
    required this.totalSkills,
    required this.totalRequests,
    required this.acceptedRequests,
    required this.totalReviews,
    required this.averageRating,
    required this.activeSessions,
  });
}

class PieSlice {
  final String name;
  final int value;

  const PieSlice(this.name, this.value);
}

class ActivityPoint {
  final String label;
  final int value;

  const ActivityPoint(this.label, this.value);
}

class BarPoint {
  final String name;
  final int value;

  const BarPoint(this.name, this.value);
}

class DashboardProvider extends ChangeNotifier {
  final ProfileService _profileService;
  final SkillService _skillService;
  final RequestService _requestService;
  final SessionService _sessionService;
  final ReviewService _reviewService;

  bool _isLoading = false;
  String? _error;

  UserProfile? _me;
  DashboardStats? _stats;
  List<PieSlice> _distribution = const [];
  List<ActivityPoint> _activity = const [];
  List<BarPoint> _topSkills = const [];

  DashboardProvider({
    ProfileService? profileService,
    SkillService? skillService,
    RequestService? requestService,
    SessionService? sessionService,
    ReviewService? reviewService,
  })  : _profileService = profileService ?? ProfileService(),
        _skillService = skillService ?? SkillService(),
        _requestService = requestService ?? RequestService(),
        _sessionService = sessionService ?? SessionService(),
        _reviewService = reviewService ?? ReviewService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfile? get me => _me;
  DashboardStats? get stats => _stats;
  List<PieSlice> get distribution => _distribution;
  List<ActivityPoint> get activity => _activity;
  List<BarPoint> get topSkills => _topSkills;

  Future<void> load() async {
    _setLoading(true);
    _error = null;

    try {
      final me = await _profileService.me();
      _me = me;

      final skillsPage = await _skillService.list(page: 0, size: 200);
      final allSkills = skillsPage.content;
      final mySkills = allSkills.where((s) => s.ownerId == me.id).toList();

      final myRequestsPage = await _requestService.listMine(page: 0, size: 200);
      final incomingPage = await _requestService.listIncoming(page: 0, size: 200);

      final myRequests = myRequestsPage.content;
      final incoming = incomingPage.content;

      final sessionsPage = await _sessionService.listMine(page: 0, size: 200);
      final sessions = sessionsPage.content;

      final reviews = await _reviewService.getByUser(me.id);

      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

      final acceptedCount = incoming
          .where((r) => r.status == 'ACCEPTED' || r.status == 'COMPLETED')
          .length;
      final activeCount = incoming.where((r) => r.status == 'ACCEPTED').length;

      _stats = DashboardStats(
        totalSkills: mySkills.length,
        totalRequests: myRequests.length,
        acceptedRequests: acceptedCount,
        totalReviews: reviews.length,
        averageRating: avgRating,
        activeSessions: activeCount,
      );

      _distribution = _levelDistribution(mySkills);
      _activity = _last7DaysActivity([...myRequests, ...incoming], sessions, reviews);
      _topSkills = _topSkillsByIncomingRequests(incoming);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  List<PieSlice> _levelDistribution(List<Skill> mySkills) {
    final map = <String, int>{};
    for (final s in mySkills) {
      map[s.level] = (map[s.level] ?? 0) + 1;
    }
    final items = map.entries.map((e) => PieSlice(e.key, e.value)).toList();
    items.sort((a, b) => b.value.compareTo(a.value));
    return items;
  }

  List<ActivityPoint> _last7DaysActivity(
    List<dynamic> requests,
    List<SessionItem> sessions,
    List<Review> reviews,
  ) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    int countForDay(DateTime d) {
      bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

      int c = 0;
      for (final r in requests) {
        final dt = (r.createdAt as DateTime);
        if (sameDay(dt.toLocal(), d)) c++;
      }
      for (final s in sessions) {
        if (sameDay(s.createdAt.toLocal(), d)) c++;
      }
      for (final r in reviews) {
        if (sameDay(r.createdAt.toLocal(), d)) c++;
      }
      return c;
    }

    const fr = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    String labelFor(DateTime d) => fr[d.weekday - 1];

    return days.map((d) => ActivityPoint(labelFor(d), countForDay(d))).toList();
  }

  List<BarPoint> _topSkillsByIncomingRequests(List<dynamic> incoming) {
    final map = <String, int>{};
    for (final r in incoming) {
      final name = (r.skillName ?? '') as String;
      if (name.trim().isEmpty) continue;
      map[name] = (map[name] ?? 0) + 1;
    }
    final items = map.entries.map((e) => BarPoint(e.key, e.value)).toList();
    items.sort((a, b) => b.value.compareTo(a.value));
    return items.take(5).toList();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
