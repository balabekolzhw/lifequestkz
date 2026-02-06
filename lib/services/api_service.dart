// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' as io;

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  // Request timeout duration
  static const Duration _timeout = Duration(seconds: 15);

  // Base URL configuration
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://10.0.2.2:3000'; // Android emulator
    }
  }

  /// Helper method to handle HTTP responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = json.decode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 400:
        throw ApiException(body['message'] ?? 'Неверный запрос', 400);
      case 401:
        throw ApiException(body['message'] ?? 'Требуется авторизация', 401);
      case 403:
        throw ApiException(body['message'] ?? 'Доступ запрещён', 403);
      case 404:
        throw ApiException(body['message'] ?? 'Не найдено', 404);
      case 429:
        throw ApiException('Слишком много запросов. Попробуйте позже.', 429);
      case 500:
      default:
        throw ApiException(body['message'] ?? 'Ошибка сервера', response.statusCode);
    }
  }

  /// Helper method to handle network errors
  static Map<String, dynamic> _handleError(dynamic error) {
    debugPrint('API Error: $error');
    if (error is TimeoutException) {
      return {'success': false, 'message': 'Превышено время ожидания. Проверьте соединение.'};
    } else if (error is io.SocketException) {
      return {'success': false, 'message': 'Нет соединения с сервером. Проверьте интернет.'};
    } else if (error is ApiException) {
      return {'success': false, 'message': error.message};
    }
    return {'success': false, 'message': 'Ошибка подключения к серверу'};
  }

  // ========== AUTH ==========
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== USERS ==========
  static Future<Map<String, dynamic>> getProfile(
    String token,
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<List<dynamic>> searchUsers(String token, String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/search/${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Search users error: $e');
      return [];
    }
  }

  // ========== FRIENDS ==========
  static Future<List<dynamic>> getFriends(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/friends'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Get friends error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addFriend(
    String token,
    String friendId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/friends/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'friendId': friendId}),
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> removeFriend(
    String token,
    String friendId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/friends/$friendId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== TASKS ==========
  static Future<List<dynamic>> getTasks(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Get tasks error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createTask(
    String token,
    String title,
    String description,
    String category,
    int xp,
    String priority,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'category': category,
          'xp': xp,
          'priority': priority,
        }),
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> completeTask(
    String token,
    String taskId,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/tasks/$taskId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteTask(
    String token,
    String taskId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== STATISTICS ==========
  static Future<Map<String, dynamic>> getStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Get stats error: $e');
      return {};
    }
  }

  // ========== LEADERBOARD ==========
  static Future<List<dynamic>> getFriendsLeaderboard(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard/friends'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Get leaderboard error: $e');
      return [];
    }
  }

  // Get global leaderboard with pagination
  static Future<List<dynamic>> getLeaderboard(String token, {String type = 'xp', int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard?type=$type&page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Get leaderboard error: $e');
      return [];
    }
  }

  // ========== AVATAR ==========
  static Future<Map<String, dynamic>> uploadAvatar(
    String token,
    String userId,
    dynamic imageFile, // XFile for mobile, bytes for web
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/$userId/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Get bytes and filename depending on platform
      List<int> bytes;
      String filename;

      if (imageFile is String) {
        // File path (mobile)
        if (!kIsWeb) {
          final file = io.File(imageFile);
          bytes = await file.readAsBytes();
          filename = imageFile.split('/').last;
        } else {
          return {'success': false, 'message': 'Неверный формат для веб'};
        }
      } else {
        // Already bytes (web or XFile)
        bytes = await imageFile.readAsBytes();
        filename = imageFile.name ?? 'avatar.jpg';
      }

      // Determine file type
      String mimeType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') ||
                 filename.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'avatar',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== ACHIEVEMENTS ==========
  static Future<List<dynamic>> getAchievements(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/achievements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Get achievements error: $e');
      return [];
    }
  }
}
