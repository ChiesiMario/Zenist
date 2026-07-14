import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/dropbox_datasource.dart';

typedef AuthState = ({bool isLoggedIn, String? email});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super((isLoggedIn: false, email: null)) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final dropbox = ref.read(dropboxDataSourceProvider);
    final isLoggedIn = await dropbox.isLoggedIn();
    String? email;
    if (isLoggedIn) {
      email = await dropbox.getCurrentAccountEmail();
    }
    if (mounted) {
      state = (isLoggedIn: isLoggedIn, email: email);
    }
  }

  Future<void> login() async {
    final dropbox = ref.read(dropboxDataSourceProvider);
    await dropbox.login();
    await checkLoginStatus();
  }

  Future<void> logout() async {
    final dropbox = ref.read(dropboxDataSourceProvider);
    await dropbox.logout();
    await checkLoginStatus();
  }
}
