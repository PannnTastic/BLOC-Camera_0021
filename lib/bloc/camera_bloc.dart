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
    InitializeCamera event, Emitter<CameraState> emit) async{
      _cameras = await availableCameras();
      await _setupController(emit,0);
    } 
  
  Future<void> _onSwitchCamera(
    SwitchCamera event, Emitter<CameraState> emit) async{
      if (state is! CameraReady) return;
      final s = state as CameraReady;
      final next = (s.selectedIndex + 1) % _cameras.length;
      await _setupController(emit, next, previous: s);
    }

  Future<void> _onToggleFlash(
    ToggleFlash event, Emitter<CameraState> emit) async{
      if (state is! CameraReady) return;
      final s = state as CameraReady;
      final next = s.flashMode == FlashMode.off ? FlashMode.auto : s.flashMode == FlashMode.auto ? FlashMode.always : FlashMode.off;
      await s.controller.setFlashMode(next);
      emit(s.copyWith(flashMode: next));
    }

  Future<void> _onTakePicture(
    TakePicture event, Emitter<CameraState> emit) async{
      if (state is! CameraReady) return;
      final s = state as CameraReady;
      final file = await s.controller.takePicture();
      event.onPictureTaken(File(file.path));
    }

  Future<void> _onTapToFocus(
    TapToFocus event, Emitter<CameraState> emit) async{
      if (state is! CameraReady) return;
      final s = state as CameraReady;
      final x = event.position.dx / event.previewSize.width;
      final y = event.position.dy / event.previewSize.height;

      await s.controller.setFocusPoint(Offset(x, y));
      await s.controller.setExposurePoint(Offset(x, y));
    }

  Future<void> _onPickImageFromGallery(
    PickImageFromGallery event, Emitter<CameraState> emit
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && state is CameraReady) {
      final file = File(picked.path);
      emit((state as CameraReady).copyWith(
        imageFile: file,
        snackbarMessage: 'Berhasil memilih dari galeri'
      ));
    }
  }

  Future<void> _onOpenCameraAndCapture(
    OpenCameraAndCapture event, Emitter<CameraState> emit
  ) async {
    if (state is CameraInitial) {
      _cameras = await availableCameras();
      await _setupController(emit, 0);
    }

    if (state is! CameraReady) {
      return;
    }

    final bloc = event.context.read<CameraBloc>();

    final file = await Navigator.push<File?>(event.context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const CameraPage(),
      )
    ));

    if (file != null ){
      final saved = await StorageHelper.saveImage(file,'camera');
      emit((state as CameraReady).copyWith(
        imageFile: saved,
        snackbarMessage: "Tersimpan: ${saved.path}",
      ));
    }
  }

  Future<void> _onDeleteImage(
    DeleteImage event, Emitter<CameraState> emit
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    if (s.imageFile != null){
      await s.imageFile!.deleteSync();
    }
    emit(s.copyWith(imageFile: null, snackbarMessage: "Gambar dihapus"));
  }

  void _onClearSnackBar(
    ClearSnackBar event, Emitter<CameraState> emit
  ) {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    emit(s.copyWith(clearSnackbar: true));
  }

  Future<void> _setupController(
    Emitter<CameraState> emit, int cameraIndex, {CameraController? previous}
  ) async {
    if (previous != null) {
      await previous.dispose();
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
      snackbarMessage: null
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
    RequestPermission event, Emitter<CameraState> emit
  ) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    final denied = statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied);
    if (!denied && state is CameraReady) {
      emit((state as CameraReady).copyWith(
        snackbarMessage: "Izin diberikan, silakan inisialisasi kamera",
      ));
    }
  }
}