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
    bool isActuallyLoggedIn = isLoggedIn;

    if (isLoggedIn) {
      try {
        email = await dropbox.getCurrentAccountEmail();
      } catch (e) {
        if (e.toString().contains('Failed to refresh token') || e.toString().contains('401')) {
          await dropbox.logout();
          isActuallyLoggedIn = false;
        }
      }
    }
    if (mounted) {
      state = (isLoggedIn: isActuallyLoggedIn, email: email);
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
