import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hai_app/core/network/errors/failure.dart';
import 'package:hai_app/core/network/networkservice.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CloudinaryService {
  final NetworkService _network;

  CloudinaryService(this._network);

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'kf03vky3';
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'hai_preset';

  Future<String> uploadImage(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'upload_preset': _uploadPreset,
      });

      final response = await _network.dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }
      throw const ServerFailure('تعذّر رفع الصورة إلى السحابة، يرجى المحاولة لاحقًا');
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ?? e.message;
      throw ServerFailure('فشل رفع الصورة: $message');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }
}
