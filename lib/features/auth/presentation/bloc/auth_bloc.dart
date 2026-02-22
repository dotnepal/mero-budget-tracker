import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on app start to begin listening to auth state changes.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Dispatched when the user taps "Sign in with Google".
class AuthSignInWithGoogle extends AuthEvent {
  const AuthSignInWithGoogle();
}

/// Dispatched when the user taps "Sign out".
class AuthSignedOut extends AuthEvent {
  const AuthSignedOut();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignedOut>(_onSignedOut);
  }

  /// Subscribes to the Firebase auth state stream for the lifetime of the bloc.
  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    await emit.forEach<AppUser?>(
      _authRepository.authStateChanges,
      onData: (user) =>
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      onError: (_, __) => const AuthError('Authentication error'),
    );
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signInWithGoogle();
      // Auth state stream (via AuthStarted) will emit AuthAuthenticated.
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
      // Auth state stream will emit AuthUnauthenticated.
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
