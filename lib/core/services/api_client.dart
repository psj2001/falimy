import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/core/config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Shared HTTP client with JWT session storage.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _tokenKey = 'falimy_auth_token';

  final http.Client _client;
  String? _token;
  final _tokenController = StreamController<String?>.broadcast();

  String? get token => _token;

  Stream<String?> get tokenChanges => _tokenController.stream;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenController.add(_token);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
    _tokenController.add(_token);
  }

  Future<void> clearToken() => setToken(null);

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized');
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client.get(_uri(path), headers: _headers());
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body ?? const {}),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body ?? const {}),
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } catch (_) {
        // ignore non-JSON body
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final message = (json['message'] as String?) ??
        'Request failed (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }

  void dispose() {
    _tokenController.close();
    _client.close();
  }
}
