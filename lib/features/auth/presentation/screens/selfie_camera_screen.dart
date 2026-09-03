import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hai_app/core/services/camera_service.dart';
import 'package:hai_app/features/auth/presentation/cubits/face_verification_cubit/face_verification_cubit.dart';

class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  final CameraService _cameraService = GetIt.I<CameraService>();
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize(
        lens: CameraLensDirection.front,
        preset: ResolutionPreset.medium,
        format: ImageFormatGroup.yuv420,
      );
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
      _startStream();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startStream() {
    _cameraService.controller?.startImageStream((CameraImage image) {
      if (mounted) {
        context.read<FaceVerificationCubit>().onCameraFrame(image);
      }
    });
  }

  Future<void> _stopStream() async {
    try {
      // Guard: only stop if the stream is actually running.
      if (_cameraService.controller?.value.isStreamingImages == true) {
        await _cameraService.controller?.stopImageStream();
      }
    } catch (e) {
      debugPrint('Stop stream error: $e');
    }
  }

  Future<void> _onShutterPressed() async {
    final cubit = context.read<FaceVerificationCubit>();

    // 1. Signal "capturing" immediately so the button disables and
    //    frame processing stops before the async gap below.
    cubit.onCapturing();

    // 2. Stop the image stream BEFORE takePicture().
    //    Both cannot run simultaneously on the same controller.
    await _stopStream();

    try {
      final XFile photo = await _cameraService.controller!.takePicture();
      debugPrint('[SelfieCameraScreen] 📸 Saved to: ${photo.path}');

      if (mounted) cubit.onPhotoCaptured(photo);
    } catch (e) {
      debugPrint('[SelfieCameraScreen] takePicture error: $e');
      // Restart stream so the user can try again.
      _startStream();
      if (mounted) cubit.onRetake();
    }
  }

  Future<void> _onRetake() async {
    context.read<FaceVerificationCubit>().onRetake();
    // Restart stream after retake.
    _startStream();
  }

  void _onConfirm(XFile photo) {
    // Pop back and return the captured XFile to the caller.
    // The caller (SelfieScreen) can then save it to its model / BLoC.
    Navigator.pop(context, photo);
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<FaceVerificationCubit, FaceVerificationState>(
          builder: (context, state) {
            // ── Photo preview screen ────────────────────────────────────────
            if (state is FaceVerificationPhotoCaptured) {
              return _buildPhotoPreview(state.photo);
            }

            // ── Live camera view ────────────────────────────────────────────
            return Stack(
              children: [
                // Camera preview
                if (_isCameraInitialized && _cameraService.controller != null)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(_cameraService.controller!),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // Face detection status card
                Positioned(
                  bottom: 130,
                  left: 20,
                  right: 20,
                  child: _buildStatusCard(state),
                ),

                // Shutter button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildShutterButton(state)),
                ),

                // Back button
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildStatusCard(FaceVerificationState state) {
    if (state is FaceVerificationCapturing) {
      return _buildOverlayCard(
        text: 'جاري التقاط الصورة...',
        color: Colors.blueAccent,
      );
    }
    if (state is FaceVerificationError) {
      return _buildOverlayCard(text: state.message, color: Colors.redAccent);
    }
    if (state is FaceVerificationFaceDetected) {
      return _buildOverlayCard(
        text:
            'تم اكتشاف الوجه ✓\n', color: Colors.green,

      );
    }
    return _buildOverlayCard(
      text: 'جاري البحث عن وجه...',
      color: Colors.orange,
    );
  }

  /// The shutter button is active ONLY when a face is detected.
  /// Any other state disables it (grey + reduced opacity).
  Widget _buildShutterButton(FaceVerificationState state) {
    final bool canCapture = state is FaceVerificationFaceDetected;
    final bool isCapturing = state is FaceVerificationCapturing;

    return GestureDetector(
      onTap: canCapture ? _onShutterPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canCapture ? 1.0 : 0.4,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: canCapture ? Colors.white : Colors.grey,
          ),
          child: isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Shown after a successful capture — lets the user confirm or retake.
  Widget _buildPhotoPreview(XFile photo) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Captured image
        Image.file(File(photo.path), fit: BoxFit.cover),

        // Dark scrim at the bottom for button readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 180,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // Confirm / Retake row
        Positioned(
          bottom: 48,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Confirm
              _buildPreviewAction(
                icon: Icons.check_circle_outline,
                label: 'تأكيد',
                onTap: () => _onConfirm(photo),
                color: Colors.greenAccent,
              ),

              // Retake
              _buildPreviewAction(
                icon: Icons.refresh,
                label: 'إعادة التصوير',
                onTap: _onRetake,
                color: Colors.white70,
              ),

              
            ],
          ),
        ),

        // Back button
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildOverlayCard({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
      ),
    );
  }
}
