import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/core/utils/url_utils.dart';
import 'package:vaultix/features/vault/domain/credential.dart';
import 'package:vaultix/features/vault/domain/vault_filter.dart';

void main() {
  group('normalizeWebUrl', () {
    test('adds https and accepts paths', () {
      expect(normalizeWebUrl('github.com/login')?.toString(),
          'https://github.com/login');
      expect(normalizeWebUrl('  http://example.org ')?.scheme, 'http');
    });

    test('rejects empty, non-web schemes and hostless input', () {
      expect(normalizeWebUrl(''), isNull);
      expect(normalizeWebUrl('javascript:alert(1)'), isNull);
      expect(normalizeWebUrl('intent://scan/#Intent;end'), isNull);
      expect(normalizeWebUrl('ftp://files.example.com'), isNull);
      expect(normalizeWebUrl('notaurl'), isNull);
    });
  });

  group('VaultFilter', () {
    test('isDefault ignores sort order', () {
      expect(const VaultFilter().isDefault, isTrue);
      expect(const VaultFilter(sort: CredentialSort.recentlyAdded).isDefault,
          isTrue);
      expect(const VaultFilter(query: 'git').isDefault, isFalse);
      expect(const VaultFilter(favoritesOnly: true).isDefault, isFalse);
    });

    test('copyWith can set and clear the category', () {
      final f = const VaultFilter().copyWith(categoryId: 3);
      expect(f.categoryId, 3);
      expect(f.copyWith(query: 'x').categoryId, 3);
      expect(f.copyWith(clearCategory: true).categoryId, isNull);
    });
  });
}
