import 'package:flutter/foundation.dart';

import '../models/request_item.dart';
import '../services/request_service.dart';

class RequestsProvider extends ChangeNotifier {
  final RequestService _requestService;

  bool _isLoading = false;
  String? _error;
  List<RequestItem> _myRequests = const [];
  List<RequestItem> _incomingRequests = const [];

  RequestsProvider({RequestService? requestService})
      : _requestService = requestService ?? RequestService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RequestItem> get myRequests => _myRequests;
  List<RequestItem> get incomingRequests => _incomingRequests;

  Future<void> loadAll() async {
    _setLoading(true);
    _error = null;
    try {
      final mine = await _requestService.listMine(page: 0, size: 50);
      final incoming = await _requestService.listIncoming(page: 0, size: 50);
      _myRequests = mine.content;
      _incomingRequests = incoming.content;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createRequest({required int skillId, String? message}) async {
    _setLoading(true);
    _error = null;
    try {
      final created = await _requestService.create(skillId: skillId, message: message);
      _myRequests = [created, ..._myRequests];
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus({required int id, required String status}) async {
    _setLoading(true);
    _error = null;
    try {
      final updated = await _requestService.update(id: id, status: status);
      _myRequests = _myRequests.map((r) => r.id == id ? updated : r).toList();
      _incomingRequests = _incomingRequests.map((r) => r.id == id ? updated : r).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clear() {
    _myRequests = const [];
    _incomingRequests = const [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
