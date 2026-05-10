import 'package:flutter/foundation.dart';

import '../models/skill.dart';
import '../services/skill_service.dart';

class SkillsProvider extends ChangeNotifier {
  final SkillService _skillService;

  bool _isLoading = false;
  String? _error;
  List<Skill> _skills = const [];
  List<Skill> _mySkills = const [];

  SkillsProvider({SkillService? skillService})
      : _skillService = skillService ?? SkillService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Skill> get skills => _skills;
  List<Skill> get mySkills => _mySkills;

  Future<void> loadMine({bool refresh = false}) async {
    _setLoading(true);
    _error = null;
    try {
      final page = await _skillService.listMine(page: 0, size: 50);
      _mySkills = page.content;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> load({
    bool refresh = false,
    int? excludeOwnerId,
    String? search,
    String? level,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final page = await _skillService.list(
          page: 0, size: 50, search: search, level: level);
      final raw = page.content;
      _skills = excludeOwnerId == null
          ? raw
          : raw.where((s) => s.ownerId != excludeOwnerId).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSkill(
      {required String name,
      String? description,
      required String level}) async {
    _setLoading(true);
    _error = null;
    try {
      final created = await _skillService.create(
          name: name, description: description, level: level);
      _skills = [created, ..._skills];
      _mySkills = [created, ..._mySkills];
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
