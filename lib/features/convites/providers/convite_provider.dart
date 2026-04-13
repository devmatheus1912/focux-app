import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/convite_repository.dart';

final conviteRepositoryProvider = Provider<ConviteRepository>(
  (ref) => ConviteRepository(ref.read(apiClientProvider)),
);
