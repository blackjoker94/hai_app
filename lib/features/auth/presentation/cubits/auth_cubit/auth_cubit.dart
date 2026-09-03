import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hai_app/features/auth/data/repo/auth_repo.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_state.dart';
import 'package:hai_app/core/network/errors/failure.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthCubit extends Cubit<AuthState> {
  final AuthRepo _authRepo;

  AuthCubit(this._authRepo) : super(SessionChecking());

  // ── SESSION CHECK ─────────────────────────────────────────────────────────

  Future<void> checkSession() async {
    emit(SessionChecking());

    final stopwatch = Stopwatch()..start();
    final loggedIn = await _authRepo.isLoggedIn();

    const minDuration = 5200;
    final elapsed = stopwatch.elapsed.inMilliseconds;
    final remaining = minDuration - elapsed;

    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    emit(loggedIn ? SessionAuthenticated() : SessionUnauthenticated());
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────

  Future<void> emitLoginStates({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());
    try {
      final user = await _authRepo.login(email, password);
      emit(LoginSuccess(user));
    } catch (error) {
      emit(LoginError(error is Failure ? error.message : error.toString()));
    }
  }

  // ── SIGNUP ────────────────────────────────────────────────────────────────

  Future<void> emitSignupStates({
    required String name,
    required String email,
    required String password,
    required String address,
    required String nationalId,
  }) async {
    emit(SignupLoading());
    try {
      final user = await _authRepo.register(
        name: name,
        email: email,
        password: password,
        address: address,
        nationalId: nationalId,
      );
      emit(SignupSuccess(user));
    } catch (error) {
      emit(SignupError(error is Failure ? error.message : error.toString()));
    }
  }

  // ── CHANGE PASSWORD ───────────────────────────────────────────────────────

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    emit(ChangePasswordLoading());
    try {
      await _authRepo.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      emit(ChangePasswordSuccess());
    } catch (error) {
      emit(ChangePasswordError(error is Failure ? error.message : error.toString()));
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(LogoutLoading());
    try {
      await _authRepo.logout();
      emit(LogoutSuccess());
    } catch (error) {
      emit(SessionUnauthenticated());
    }
  }
}
