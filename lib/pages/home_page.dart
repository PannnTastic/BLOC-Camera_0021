import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:praktikum7/bloc/camera_bloc.dart';
import 'package:praktikum7/bloc/camera_event.dart';
import 'package:praktikum7/bloc/camera_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Beranda')),
			body: SafeArea(
				child: BlocConsumer<CameraBloc, CameraState>(
					listener: (context, state) {
						if (state is CameraReady && state.snackbarMessage != null) {
							ScaffoldMessenger.of(context).showSnackBar(
								SnackBar(content: Text(state.snackbarMessage!)),
							);
							context.read<CameraBloc>().add(ClearSnackBar());
						}
					},
					builder: (context, state) {
						final imageFile = state is CameraReady ? state.imageFile : null;

						return Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Row(
										children: [
											Expanded(
												child: ElevatedButton.icon(
													icon: const Icon(Icons.camera_alt),
													label: const Text('Ambil Foto'),
													onPressed: () {
														context.read<CameraBloc>().add(
															OpenCameraAndCapture(context: context),
																);
													},
												),
											),
											const SizedBox(width: 12),
											Expanded(
												child: ElevatedButton.icon(
													icon: const Icon(Icons.photo_library),
													label: const Text('Pilih dari Galeri'),
													onPressed: () => context
															.read<CameraBloc>()
															.add(PickImageFromGallery()),
												),
											),
										],
									),
									const SizedBox(height: 20),
									Expanded(
										child: imageFile != null
												? Card(
														clipBehavior: Clip.antiAlias,
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.stretch,
															children: [
																Expanded(
																	child: Image.file(
																		imageFile,
																		fit: BoxFit.cover,
																		width: double.infinity,
																	),
																),
																Padding(
																	padding: const EdgeInsets.all(16),
																	child: Text(
																		'Gambar disimpan di: ${imageFile.path}',
																	),
																),
																Padding(
																	padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
																	child: ElevatedButton.icon(
																		icon: const Icon(Icons.delete),
																		label: const Text('Hapus Gambar'),
																		onPressed: () => context
																				.read<CameraBloc>()
																				.add(DeleteImage()),
																	),
																),
															],
														),
													)
												: const Center(
														child: Text('Belum ada gambar diambil/dipilih.'),
													),
									),
								],
							),
						);
					},
				),
			),
		);
  }
}