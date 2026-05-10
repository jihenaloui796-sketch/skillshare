import '../models/rating_stats.dart';
import 'api_client.dart';

class RatingService {
  final ApiClient _api;

  RatingService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<RatingStats> getUserRating(int userId) async {
    final json = await _api.get('/ratings/users/$userId');
    return RatingStats.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<RatingStats> getSkillRating(int skillId) async {
    final json = await _api.get('/ratings/skills/$skillId');
    return RatingStats.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<RatingStats> getSessionRating(int sessionId) async {
    final json = await _api.get('/ratings/sessions/$sessionId');
    return RatingStats.fromJson((json as Map).cast<String, dynamic>());
  }
}
