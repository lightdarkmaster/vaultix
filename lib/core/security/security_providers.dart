import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'crypto_service.dart';
import 'secure_store.dart';

final appDatabaseProvider = Provider<AppDatabase>((_) => AppDatabase.instance);
final cryptoServiceProvider = Provider<CryptoService>((_) => CryptoService());
final secureStoreProvider = Provider<SecureStore>((_) => SecureStore());
