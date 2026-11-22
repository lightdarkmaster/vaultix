import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/security_providers.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);

/// Categories with credential counts. Invalidate after any change to
/// categories or credentials.
final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryWithCount>>(
  (ref) => ref.watch(categoryRepositoryProvider).listWithCounts(),
);
