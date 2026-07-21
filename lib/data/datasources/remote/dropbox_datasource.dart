import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dropboxDataSourceProvider = Provider<DropboxDataSource>((ref) {
  return DropboxDataSource();
});

class DropboxDataSource {
  static const String _clientId = 'rin197bgs7odw7n';
  static const String _clientSecret = '0x4hd9xvwqtnfwj';

  String get _redirectUri {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:45912/';
    } else {
      return 'zenist://oauth2redirect';
    }
  }

  static const String _tokenKey = 'dropbox_access_token';
  static const String _refreshTokenKey = 'dropbox_refresh_token';
  static const String _emailKey = 'dropbox_account_email';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _accessToken;
  HttpServer? _server;
  Timer? _serverTimeoutTimer;
  Future<void>? _pendingLogin;

  Future<bool> isLoggedIn() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    return refreshToken != null;
  }

  Future<void> login() async {
    if (_pendingLogin != null) {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 重置 10 分鐘計時器
        _serverTimeoutTimer?.cancel();
        _serverTimeoutTimer = Timer(const Duration(minutes: 10), () {
          _server?.close(force: true);
        });

        final url = Uri.https('www.dropbox.com', '/oauth2/authorize', {
          'client_id': _clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'token_access_type': 'offline',
        });
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      }
      return _pendingLogin;
    }

    _pendingLogin = _doLogin();
    try {
      await _pendingLogin;
    } finally {
      _pendingLogin = null;
    }
  }

  Future<void> _doLogin() async {
    final url = Uri.https('www.dropbox.com', '/oauth2/authorize', {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'token_access_type': 'offline',
    });

    String? code;

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 45912);
      
      _serverTimeoutTimer?.cancel();
      _serverTimeoutTimer = Timer(const Duration(minutes: 10), () {
        _server?.close(force: true);
      });

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw Exception('Could not launch $url');
        }

        await for (var request in _server!) {
          final queryParams = request.uri.queryParameters;
          if (queryParams.containsKey('code')) {
            code = queryParams['code'];
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(
                '<html><body style="font-family:sans-serif;text-align:center;margin-top:50px;"><h1>Zenist 授權成功！</h1><p>您可以安全地關閉這個視窗並返回應用程式。</p><script>window.close();</script></body></html>',
              );
            await request.response.close();
            break;
          } else if (queryParams.containsKey('error')) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..headers.contentType = ContentType.html
              ..write(
                '<html><body><h1>授權失敗</h1><p>${queryParams['error']}</p></body></html>',
              );
            await request.response.close();
            throw Exception('Dropbox login error: ${queryParams['error']}');
          }
        }
      } finally {
        _serverTimeoutTimer?.cancel();
        await _server?.close(force: true);
        _server = null;
      }
    } else {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'zenist',
      );
      code = Uri.parse(result).queryParameters['code'];
    }

    if (code == null) throw Exception('No code returned from Dropbox');

    final tokenResponse = await http.post(
      Uri.parse('https://api.dropboxapi.com/oauth2/token'),
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'redirect_uri': _redirectUri,
      },
    );

    if (tokenResponse.statusCode == 200) {
      final data = jsonDecode(tokenResponse.body);
      _accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      if (_accessToken != null) {
        await _storage.write(key: _tokenKey, value: _accessToken);
      }
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } else {
      throw Exception('Failed to exchange token: ${tokenResponse.body}');
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _emailKey);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/oauth2/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      await _storage.write(key: _tokenKey, value: _accessToken!);
      return true;
    } else {
      return false;
    }
  }

  Future<T> _withAuth<T>(Future<T> Function() action) async {
    if (_accessToken == null) {
      _accessToken = await _storage.read(key: _tokenKey);
    }

    try {
      return await action();
    } catch (e) {
      // 假設遇到 401 代表 token 過期
      if (e.toString().contains('401')) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await action();
        } else {
          throw Exception('Failed to refresh token');
        }
      }
      rethrow;
    }
  }

  Future<String?> getCurrentAccountEmail() async {
    if (!await isLoggedIn()) return null;

    try {
      return await _withAuth(() async {
        final response = await http.post(
          Uri.parse('https://api.dropboxapi.com/2/users/get_current_account'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final email = data['email'] as String?;
          if (email != null) {
            await _storage.write(key: _emailKey, value: email);
          }
          return email;
        } else if (response.statusCode == 401) {
          throw Exception('401 Unauthorized');
        }
        return null;
      });
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return await _storage.read(key: _emailKey);
      }
      rethrow;
    }
  }

  Future<String?> downloadBackup() async {
    if (!await isLoggedIn()) return null;

    return _withAuth(() async {
      final response = await http.post(
        Uri.parse('https://content.dropboxapi.com/2/files/download'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Dropbox-API-Arg': jsonEncode({'path': '/zenist_backup.json'}),
        },
      );

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else if (response.statusCode == 409) {
        // File not found (path_not_found)
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('401 Unauthorized');
      } else {
        throw Exception(
          'Failed to download backup: ${response.statusCode} ${response.body}',
        );
      }
    });
  }

  Future<void> uploadBackup(String jsonContent) async {
    if (!await isLoggedIn()) return;

    return _withAuth(() async {
      final response = await http.post(
        Uri.parse('https://content.dropboxapi.com/2/files/upload'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Dropbox-API-Arg': jsonEncode({
            'path': '/zenist_backup.json',
            'mode': 'overwrite',
            'autorename': false,
            'mute': true,
            'strict_conflict': false,
          }),
          'Content-Type': 'application/octet-stream',
        },
        body: utf8.encode(jsonContent),
      );

      if (response.statusCode == 401) {
        throw Exception('401 Unauthorized');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to upload backup: ${response.statusCode} ${response.body}',
        );
      }
    });
  }
}
