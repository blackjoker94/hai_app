import 'package:hai_app/features/auth/data/model/user.dart';

abstract class AuthState {}

// ── SESSION CHECK ───────────────────────────────────────────────────────────
class SessionChecking extends AuthState {}
class SessionAuthenticated extends AuthState {}
class SessionUnauthenticated extends AuthState {}

// ── LOGIN ───────────────────────────────────────────────────────────────────
class LoginInitial extends AuthState {}
class LoginLoading extends AuthState {}
class LoginSuccess extends AuthState {
  final User user;
  LoginSuccess(this.user);
}
class LoginError extends AuthState {
  final String error;
  LoginError(this.error);
}

// ── SIGNUP ──────────────────────────────────────────────────────────────────
class SignupLoading extends AuthState {}
class SignupSuccess extends AuthState {
  final User user;
  SignupSuccess(this.user);
}
class SignupError extends AuthState {
  final String error;
  SignupError(this.error);
}

// ── CHANGE PASSWORD ─────────────────────────────────────────────────────────
class ChangePasswordLoading extends AuthState {}
class ChangePasswordSuccess extends AuthState {}
class ChangePasswordError extends AuthState {
  final String error;
  ChangePasswordError(this.error);
}

// ── LOGOUT ──────────────────────────────────────────────────────────────────
class LogoutLoading extends AuthState {}
class LogoutSuccess extends AuthState {}