// lib/services/camera_service.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';


@lazySingleton
class CameraService with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _desiredLens = CameraLensDirection.back;
  bool _resumedReinitPending = false;

  Future<void> initialize({
    CameraLensDirection lens = CameraLensDirection.back,
    ResolutionPreset preset = ResolutionPreset.medium,
    bool enableAudio = false,
    ImageFormatGroup format = ImageFormatGroup.yuv420,
  }) async {
    WidgetsBinding.instance.addObserver(this);
    _desiredLens = lens;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No cameras available on this device');
      }

      final selected = _cameras.firstWhere(
        (c) => c.lensDirection == lens,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        selected,
        preset,
        enableAudio: enableAudio,
        imageFormatGroup: format,
      );

      await controller.initialize();
      _controller = controller;
    // ignore: unused_catch_clause
    } on CameraException catch (e) {
      // Common reasons: permission denied, camera in use by another app, etc.
      await _safeDispose();
      rethrow;
    } catch (_) {
      await _safeDispose();
      rethrow;
    }
  }

  CameraController? get controller => _controller;

  Future<XFile?> takePicture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }
    if (c.value.isTakingPicture) {
      // Already capturing; you can also wait or throw based on app logic
      return null;
    }
    try {
      return await c.takePicture();
    } on CameraException {
      rethrow;
    }
  }


  Future<void> reinitialize({
    CameraLensDirection? lens,
    ResolutionPreset preset = ResolutionPreset.medium,
    bool enableAudio = false,
    ImageFormatGroup format = ImageFormatGroup.yuv420,
  }) async {
    await _safeDispose();
    await initialize(
      lens: lens ?? _desiredLens,
      preset: preset,
      enableAudio: enableAudio,
      format: format,
    );
  }

  /// Lifecycle hook: dispose camera on pause, re-init on resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free camera for other apps / OS
      _safeDispose();
      _resumedReinitPending = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_resumedReinitPending) {
        // Attempt re-init with previous desired settings
        // Ignore errors here; let UI trigger manual re-try if needed
        initialize(lens: _desiredLens).catchError((_) {});
        _resumedReinitPending = false;
      }
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _safeDispose();
    _cameras = const [];
  }

  Future<void> _safeDispose() async {
    final c = _controller;
    _controller = null;
    try {
      await c?.dispose();
    } catch (_) {
      // ignore
    }
  }
}
