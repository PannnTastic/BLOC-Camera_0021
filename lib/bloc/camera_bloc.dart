import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:praktikum7/bloc/camera_event.dart';
import 'package:praktikum7/bloc/camera_state.dart';
import 'package:praktikum7/helpers/storage_helper.dart';
import 'package:praktikum7/pages/camera_page.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late List<CameraDescription> _cameras;

  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<ToggleFlash>(_onToggleFlash);
    on<TakePicture>(_onTakePicture);
    on<TapToFocus>(_onTapToFocus);
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<OpenCameraAndCapture>(_onOpenCameraAndCapture);
    on<DeleteImage>(_onDeleteImage);
    on<ClearSnackBar>(_onClearSnackBar);
    on<RequestPermission>(_onRequestPermission);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    _cameras = await availableCameras();
    await _setupController(emit, 0);
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    final next = (current.selectedIndex + 1) % _cameras.length;
    await _setupController(emit, next, previous: current);
  }

  Future<void> _onToggleFlash(
    ToggleFlash event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    final next = current.flashMode == FlashMode.off
        ? FlashMode.auto
        : current.flashMode == FlashMode.auto
            ? FlashMode.always
            : FlashMode.off;
    await current.controller.setFlashMode(next);
    emit(current.copyWith(flashMode: next));
  }

  Future<void> _onTakePicture(
    TakePicture event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    final file = await current.controller.takePicture();
    event.onPictureTaken(File(file.path));
  }

  Future<void> _onTapToFocus(
    TapToFocus event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    final x = event.position.dx / event.previewSize.width;
    final y = event.position.dy / event.previewSize.height;

    await current.controller.setFocusPoint(Offset(x, y));
    await current.controller.setExposurePoint(Offset(x, y));
  }

  Future<void> _onPickImageFromGallery(
    PickImageFromGallery event,
    Emitter<CameraState> emit,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && state is CameraReady) {
      final file = File(picked.path);
      emit((state as CameraReady).copyWith(
        imageFile: file,
        snackbarMessage: 'Berhasil memilih dari galeri',
      ));
    }
  }

  Future<void> _onOpenCameraAndCapture(
    OpenCameraAndCapture event,
    Emitter<CameraState> emit,
  ) async {
    final navigator = Navigator.of(event.context);

    if (state is CameraInitial) {
      _cameras = await availableCameras();
      await _setupController(emit, 0);
    }

    if (state is! CameraReady) {
      return;
    }

    final file = await navigator.push<File?>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: this,
          child: const CameraPage(),
        ),
      ),
    );

    if (file != null) {
      final saved = await StorageHelper.saveImage(file, 'camera');
      emit((state as CameraReady).copyWith(
        imageFile: saved,
        snackbarMessage: 'Tersimpan: ${saved.path}',
      ));
    }
  }

  Future<void> _onDeleteImage(
    DeleteImage event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    if (current.imageFile != null) {
      await current.imageFile!.delete();
    }
    emit(current.copyWith(imageFile: null, snackbarMessage: 'Gambar dihapus'));
  }

  void _onClearSnackBar(
    ClearSnackBar event,
    Emitter<CameraState> emit,
  ) {
    if (state is! CameraReady) return;
    final current = state as CameraReady;
    emit(current.copyWith(clearSnackbar: true));
  }

  Future<void> _setupController(
    Emitter<CameraState> emit,
    int cameraIndex, {
    CameraReady? previous,
  }) async {
    if (previous != null) {
      await previous.controller.dispose();
    }

    final controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.max,
    );
    await controller.initialize();
    await controller.setFlashMode(previous?.flashMode ?? FlashMode.off);

    emit(CameraReady(
      controller: controller,
      selectedIndex: cameraIndex,
      flashMode: previous?.flashMode ?? FlashMode.off,
      imageFile: previous?.imageFile,
      snackbarMessage: null,
    ));
  }

  @override
  Future<void> close() async {
    if (state is CameraReady) {
      await (state as CameraReady).controller.dispose();
    }
    await super.close();
  }

  Future<void> _onRequestPermission(
    RequestPermission event,
    Emitter<CameraState> emit,
  ) async {
    final statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    final denied = statuses.values.any(
      (status) => status.isDenied || status.isPermanentlyDenied,
    );
    if (!denied && state is CameraReady) {
      emit((state as CameraReady).copyWith(
        snackbarMessage: 'Izin diberikan, silakan inisialisasi kamera',
      ));
    }
  }
}