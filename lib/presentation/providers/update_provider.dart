import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return const UpdateService();
});
