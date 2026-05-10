import '../models/paged.dart';
import '../models/request_item.dart';
import 'api_client.dart';

class RequestService {
  final ApiClient _api;

  RequestService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Paged<RequestItem>> listMine({int page = 0, int size = 50}) async {
    final json = await _api.get('/requests', query: {'page': page, 'size': size});
    return Paged.fromJson(
      (json as Map).cast<String, dynamic>(),
      (m) => RequestItem.fromJson(m),
    );
  }

  Future<Paged<RequestItem>> listIncoming({int page = 0, int size = 50}) async {
    final json = await _api.get('/requests/incoming', query: {'page': page, 'size': size});
    return Paged.fromJson(
      (json as Map).cast<String, dynamic>(),
      (m) => RequestItem.fromJson(m),
    );
  }

  Future<RequestItem> create({required int skillId, String? message}) async {
    final json = await _api.post('/requests', body: {
      'skillId': skillId,
      'message': message,
    });
    return RequestItem.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<RequestItem> update({required int id, required String status, String? message}) async {
    final json = await _api.put('/requests/$id', body: {
      'status': status,
      'message': message,
    });
    return RequestItem.fromJson((json as Map).cast<String, dynamic>());
  }
}
