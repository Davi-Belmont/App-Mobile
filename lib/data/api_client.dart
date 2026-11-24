// Responsável: Cainã Coutinho (camada de acesso à API compartilhada por todos)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:study_planner/core/config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP/JSON único do app (a API é a dona das regras de negócio).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();
  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send(() => _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send(() => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(ApiConfig.timeout);
      final decoded = _decode(res);
      if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
      throw ApiException(_errorMessage(decoded, res.statusCode), res.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder. Tente novamente.');
    } on SocketException {
      throw const ApiException('Sem conexão com o servidor. Verifique se a API está rodando.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar à API.');
    }
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      return res.body;
    }
  }

  String _errorMessage(dynamic body, int status) {
    if (body is Map) {
      final m = body['message'] ?? body['error'];
      if (m is List) return m.join('\n');
      if (m != null) return m.toString();
    }
    return 'Erro $status ao falar com o servidor.';
  }

  /// Aceita tanto `[...]` quanto `{ "data": [...] }`.
  static List<Map<String, dynamic>> asList(dynamic data) {
    final raw = data is Map ? (data['data'] ?? data['items'] ?? const []) : data;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
