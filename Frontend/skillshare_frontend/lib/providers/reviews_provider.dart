import 'package:flutter/foundation.dart';

import '../models/request_item.dart';
import '../models/review.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/request_service.dart';
import '../services/review_service.dart';

class ReviewsProvider extends ChangeNotifier {
  final ProfileService _profileService;
  final RequestService _requestService;
  final ReviewService _reviewService;

  bool _isLoading = false;
  String? _error;

  UserProfile? _me;
  List<RequestItem> _completedRequests = const [];
  List<Review> _myReviews = const [];
  List<Review> _receivedReviews = const [];

  ReviewsProvider({
    ProfileService? profileService,
    RequestService? requestService,
    ReviewService? reviewService,
  })  : _profileService = profileService ?? ProfileService(),
        _requestService = requestService ?? RequestService(),
        _reviewService = reviewService ?? ReviewService();

  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProfile? get me => _me;
  List<RequestItem> get completedRequests => _completedRequests;
  List<Review> get myReviews => _myReviews;
  List<Review> get receivedReviews => _receivedReviews;

  double get averageReceivedRating {
    if (_receivedReviews.isEmpty) return 0;
    final sum = _receivedReviews.fold<int>(0, (a, r) => a + r.rating);
    return sum / _receivedReviews.length;
  }

  Future<void> load() async {
    _setLoading(true);
    _error = null;

    try {
      final me = await _profileService.me();
      _me = me;

      final mine = await _requestService.listMine(page: 0, size: 200);
      _completedRequests = mine.content.where((r) => r.status == 'COMPLETED').toList();

      _myReviews = await _reviewService.listMine();
      _receivedReviews = await _reviewService.getByUser(me.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  bool hasReviewedRequest(int requestId) {
    return _myReviews.any((r) => r.requestId == requestId);
  }

  Future<bool> createReview({required int requestId, required int rating, String? comment}) async {
    final me = _me;
    if (me == null) return false;

    _setLoading(true);
    _error = null;

    try {
      final req = _completedRequests.firstWhere((r) => r.id == requestId);
      final created = await _reviewService.create(
        reviewedUserId: req.skillOwnerId,
        requestId: requestId,
        rating: rating,
        comment: comment,
      );
      _myReviews = [created, ..._myReviews];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReview({required int id, required int rating, String? comment}) async {
    _setLoading(true);
    _error = null;

    try {
      final updated = await _reviewService.update(id: id, rating: rating, comment: comment);
      _myReviews = _myReviews.map((r) => r.id == id ? updated : r).toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteReview({required int id}) async {
    _setLoading(true);
    _error = null;

    try {
      await _reviewService.delete(id: id);
      _myReviews = _myReviews.where((r) => r.id != id).toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
