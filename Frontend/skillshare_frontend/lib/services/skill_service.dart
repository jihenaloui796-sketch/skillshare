import '../models/paged.dart';
import '../models/skill.dart';
import 'api_client.dart';

class SkillService {
  final ApiClient _api;

  SkillService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Paged<Skill>> list(
      {int page = 0, int size = 20, String? search, String? level}) async {
    final query = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (level != null && level.trim().isNotEmpty) {
      query['level'] = level.trim();
    }

    final json = await _api.get('/skills', query: query);
    return Paged.fromJson(
        (json as Map).cast<String, dynamic>(), (m) => Skill.fromJson(m));
  }

  Future<Paged<Skill>> listMine({int page = 0, int size = 50}) async {
    final json = await _api.get('/skills/mine', query: {
      'page': page,
      'size': size,
    });
    return Paged.fromJson(
        (json as Map).cast<String, dynamic>(), (m) => Skill.fromJson(m));
  }

  Future<Skill> create(
      {required String name,
      String? description,
      required String level}) async {
    final json = await _api.post('/skills', body: {
      'name': name,
      'description': description,
      'level': level,
    });
    return Skill.fromJson((json as Map).cast<String, dynamic>());
  }
}
