import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import 'profile_provider.dart';

final resumeUploadProvider = AsyncNotifierProvider<ResumeUploadNotifier, void>(
  ResumeUploadNotifier.new,
);

class ResumeUploadNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> pickAndUploadResume() async {
    if (state.isLoading) {
      return false;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return false;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null) {
      state = AsyncError(
        StateError('Failed to read selected file'),
        StackTrace.current,
      );

      return false;
    }

    state = const AsyncLoading();

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });

      await ApiClient.dio.post(
        '/upload/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      ref.invalidate(profileProvider);

      await ref.read(profileProvider.future);

      state = const AsyncData(null);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }
}
