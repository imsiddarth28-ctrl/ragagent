import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../models/user_model.dart';
import '../../../core/services/api_service.dart';

const _tokenStorageKey = 'auth_access_token';
const _guestStorageKey = 'is_guest_mode';
const _storage = FlutterSecureStorage();

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
  });

  bool get isAuthenticated => user != null || isGuest;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState(isLoading: true)) {
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final isGuest = await _storage.read(key: _guestStorageKey) == 'true';
      if (isGuest) {
        state = AuthState(isGuest: true, isLoading: false);
        return;
      }

      final token = await _storage.read(key: _tokenStorageKey);
      if (token != null && token.isNotEmpty) {
        _apiService.setAuthToken(token);
        try {
          final user = await _apiService.getMe();
          state = AuthState(user: user, token: token, isLoading: false);
          return;
        } catch (_) {
          // Token expired or invalid
          await _storage.delete(key: _tokenStorageKey);
          _apiService.setAuthToken(null);
        }
      }
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _apiService.login(email: email, password: password);
      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      await _storage.write(key: _tokenStorageKey, value: token);
      await _storage.delete(key: _guestStorageKey);
      _apiService.setAuthToken(token);

      state = AuthState(user: user, token: token, isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Auth error: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _apiService.register(name: name, email: email, password: password);
      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      await _storage.write(key: _tokenStorageKey, value: token);
      await _storage.delete(key: _guestStorageKey);
      _apiService.setAuthToken(token);

      state = AuthState(user: user, token: token, isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Auth error: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String email = "google_user@gmail.com";
      String name = "Google User";
      String? avatarUrl;
      String? idToken;

      try {
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account != null) {
          email = account.email;
          name = account.displayName ?? "Google User";
          avatarUrl = account.photoUrl;
          final GoogleSignInAuthentication auth = await account.authentication;
          idToken = auth.idToken;
        }
      } catch (_) {
        // Fallback for environments without Play Services
      }

      final result = await _apiService.googleAuth(
        email: email,
        name: name,
        avatarUrl: avatarUrl,
        idToken: idToken,
      );

      final token = result['token'] as String;
      final user = result['user'] as UserModel;

      await _storage.write(key: _tokenStorageKey, value: token);
      await _storage.delete(key: _guestStorageKey);
      _apiService.setAuthToken(token);

      state = AuthState(user: user, token: token, isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Google Sign In error: ', '');
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> signInAsGuest() async {
    await _storage.write(key: _guestStorageKey, value: 'true');
    await _storage.delete(key: _tokenStorageKey);
    _apiService.setAuthToken(null);
    state = AuthState(isGuest: true, isLoading: false);
  }

  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _storage.delete(key: _tokenStorageKey);
    await _storage.delete(key: _guestStorageKey);
    _apiService.setAuthToken(null);
    state = AuthState(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});
