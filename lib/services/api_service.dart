import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your PC IP for physical device
  static const String baseUrl = 'https://leading-unity-nest-backend.vercel.app/api';
  
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // --- AUTH ---
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  Future<dynamic> registerStudent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register/student', data: data);
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- COMMON ---
  Future<List<dynamic>> getCourses() async {
    final response = await _dio.get('/courses');
    return response.data;
  }

  Future<List<dynamic>> getUsers() async {
    final response = await _dio.get('/users');
    return response.data;
  }

  Future<bool> isRegistrationOpen() async {
    try {
      final response = await _dio.get('/settings');
      return response.data['isStudentRegistrationOpen'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // --- STUDENT SPECIFIC ---
  Future<void> submitProposal(Map<String, dynamic> data) async {
    try {
      await _dio.post('/proposals', data: data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Submission failed';
    }
  }

  Future<List<dynamic>> getMyProposals() async {
    try {
      final response = await _dio.get('/proposals/my');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  // --- SUPERVISOR SPECIFIC (REAL ENDPOINTS) ---

  // 1. First Time Login (Change Password)
  Future<void> changePasswordFirstLogin(String email, String tempPass, String newPass) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'email': email,
        'oldPassword': tempPass,
        'newPassword': newPass
      });
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? 'Failed to change password';
    }
  }

  // 2. Get All Teams (Marking & Viewing)
  Future<List<dynamic>> getAllProposals() async {
    try {
      final response = await _dio.get('/proposals'); 
      return response.data;
    } catch (e) {
      return []; 
    }
  }

  // 3. Get Evaluation Settings (Admin Defined Criteria)
  Future<Map<String, dynamic>> getEvaluationSettings() async {
    try {
      final response = await _dio.get('/settings');
      final data = response.data;
      
      // Map backend fields to UI expectation
      return {
        'criteria1': {'name': data['criteria1Name'] ?? 'Criteria 1', 'max': data['criteria1Max'] ?? 30},
        'criteria2': {'name': data['criteria2Name'] ?? 'Criteria 2', 'max': data['criteria2Max'] ?? 30},
      };
    } catch (e) {
      // Fallback
      return {
        'criteria1': {'name': 'Criteria 1', 'max': 30},
        'criteria2': {'name': 'Criteria 2', 'max': 30},
      };
    }
  }

  // 4. Save/Update Marks
  Future<void> saveTeamMarks(String proposalId, List<Map<String, dynamic>> marksData) async {
    try {
      await _dio.post('/proposals/$proposalId/marks', data: marksData);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to save marks';
    }
  }
}