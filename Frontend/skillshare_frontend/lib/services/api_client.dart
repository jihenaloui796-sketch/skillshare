import 'dart:convert';

import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final http.Client _http;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
      : _http = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.baseUrl();
    return Uri.parse('$base$path')
        .replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _decodeBody(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return res.body;
    }
  }

  ApiException _asException(http.Response res) {
    final decoded = _decodeBody(res);
    if (decoded is Map && decoded['message'] is String) {
      return ApiException(res.statusCode, decoded['message'] as String);
    }
    return ApiException(res.statusCode, res.reasonPhrase ?? 'Request failed');
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _http.get(_uri(path, query), headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _decodeBody(res);
    }
    throw _asException(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final res = await _http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _decodeBody(res);
    }
    throw _asException(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await _http.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _decodeBody(res);
    }
    throw _asException(res);
  }

  Future<void> delete(String path) async {
    final res = await _http.delete(_uri(path), headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw _asException(res);
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required File file,
    String? filename,
    bool auth = true,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
    }

    req.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        filename: filename,
      ),
    );

    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _decodeBody(res);
    }
    throw _asException(res);
  }
}
