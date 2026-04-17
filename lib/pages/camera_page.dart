import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:praktikum7/bloc/camera_bloc.dart';
import 'package:praktikum7/bloc/camera_event.dart';
import 'package:praktikum7/bloc/camera_state.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<CameraBloc>();
      if (bloc.state is CameraInitial) {
        bloc.add(InitializeCamera());
      }
    });
  }

  IconData _flashIcon(FlashMode mode) {
    return switch (mode) {
      FlashMode.auto => Icons.flash_auto,
      FlashMode.always => Icons.flash_on,
      _ => Icons.flash_off,
    };
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return ClipOval(
      child: Material(
        color: Colors.white24,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CameraBloc, CameraState>(
        builder: (context, state) {
          if (state is! CameraReady) {
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              var scale = 1 / (state.controller.value.aspectRatio * size.aspectRatio);
              if (scale < 1) {
                scale = 1 / scale;
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Center(
                        child: CameraPreview(state.controller),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Column(
                      children: [
                        _circleButton(Icons.flip_camera_android, () {
                          context.read<CameraBloc>().add(SwitchCamera());
                        }),
                        const SizedBox(height: 12),
                        _circleButton(_flashIcon(state.flashMode), () {
                          context.read<CameraBloc>().add(ToggleFlash());
                        }),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        onPressed: () {
                          context.read<CameraBloc>().add(
                                TakePicture(
                                  onPictureTaken: (file) => Navigator.pop(
                                    context,
                                    file,
                                  ),
                                ),
                              );
                        },
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}