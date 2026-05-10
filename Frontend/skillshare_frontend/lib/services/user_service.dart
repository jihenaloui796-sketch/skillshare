import '../models/user_summary.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api;

  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<UserSummary>> listUsers() async {
    final json = await _api.get('/users');
    final raw = (json as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => UserSummary.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
