import '../models/auth_response.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _api = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }

  Future<bool> hasToken() async {
    final t = await _tokenStorage.getToken();
    return t != null && t.isNotEmpty;
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    final json = await _api.post(
      '/auth/login',
      auth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final res = AuthResponse.fromJson((json as Map).cast<String, dynamic>());
    await _tokenStorage.setToken(res.token);
    return res;
  }

  Future<AuthResponse> register({required String email, required String password, required String fullName}) async {
    final json = await _api.post(
      '/auth/register',
      auth: false,
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
    );

    final res = AuthResponse.fromJson((json as Map).cast<String, dynamic>());
    await _tokenStorage.setToken(res.token);
    return res;
  }
}
