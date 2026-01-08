import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return const UpdateService();
});

final updateConfigProvider = FutureProvider.autoDispose<UpdateConfig>((ref) async {
  final service = ref.read(updateServiceProvider);
  return service.fetchConfig();
});
