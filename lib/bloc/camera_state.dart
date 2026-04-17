import 'dart:io';

import 'package:camera/camera.dart';

sealed class CameraState {}
final class CameraInitialState extends CameraState{}

final class CameraReady extends CameraState{
  final CameraController controller;
  final int selectedIndex;
  final FlashMode flashMode;
  final File? imageFile;
  final String? snackbarMessage;

  CameraReady({
    required this.controller,
    required this.selectedIndex,
    required this.flashMode,
    this.imageFile,
    this.snackbarMessage,
  });

  CameraReady copyWith({
    CameraController? controller,
    int? selectedIndex,
    FlashMode? flashMode,
    File? imageFile,
    String? snackbarMessage,
  }) {
    return CameraReady(
      controller: controller ?? this.controller,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      flashMode: flashMode ?? this.flashMode,
      imageFile: imageFile ?? this.imageFile,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
    );
  }
}