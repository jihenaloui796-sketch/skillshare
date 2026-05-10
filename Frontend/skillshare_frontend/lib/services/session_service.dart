import '../models/paged.dart';
import '../models/session_item.dart';
import 'api_client.dart';

class SessionService {
  final ApiClient _api;

  SessionService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Paged<SessionItem>> listMine({int page = 0, int size = 50}) async {
    final json = await _api.get('/sessions', query: {'page': page, 'size': size});
    return Paged.fromJson(
      (json as Map).cast<String, dynamic>(),
      (m) => SessionItem.fromJson(m),
    );
  }
}
