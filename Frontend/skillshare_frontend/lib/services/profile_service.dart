import '../models/user_profile.dart';
import 'api_client.dart';

import 'dart:io';

class ProfileService {
  final ApiClient _api;

  ProfileService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<UserProfile> me() async {
    final json = await _api.get('/profile');
    return UserProfile.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<UserProfile> update({required String fullName, String? bio}) async {
    final json = await _api.put('/profile', body: {
      'fullName': fullName,
      'bio': bio,
    });
    return UserProfile.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<UserProfile> uploadAvatar({required File file}) async {
    final json = await _api.postMultipart(
      '/profile/avatar',
      fieldName: 'file',
      file: file,
    );
    return UserProfile.fromJson((json as Map).cast<String, dynamic>());
  }
}
