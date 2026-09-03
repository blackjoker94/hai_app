import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthService(this._firebaseAuth);

  User? get currentUser => _firebaseAuth.currentUser;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('لم يتم تسجيل الدخول');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  static Exception mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('لم يتم العثور على حساب بهذا البريد الإلكتروني');
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('كلمة المرور أو البريد الإلكتروني غير صحيح');
      case 'email-already-in-use':
        return Exception('البريد الإلكتروني مسجل بالفعل بحساب آخر');
      case 'invalid-email':
        return Exception('صيغة البريد الإلكتروني غير صحيحة');
      case 'weak-password':
        return Exception('كلمة المرور ضعيفة جدًا، يرجى اختيار كلمة مرور أقوى');
      case 'user-disabled':
        return Exception('تم تعطيل هذا الحساب من قبل الإدارة');
      case 'too-many-requests':
        return Exception('تم حظر المحاولات مؤقتًا بسبب كثرة المحاولات، يرجى المحاولة لاحقًا');
      case 'network-request-failed':
        return Exception('تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت');
      default:
        return Exception(e.message ?? 'حدث خطأ في المصادقة، يرجى المحاولة مرة أخرى');
    }
  }
}
