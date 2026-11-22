/// Argon2id parameters. Stored next to the salt so they can be raised later
/// without breaking existing vaults.
class KdfParams {
  const KdfParams({
    this.algorithm = 'argon2id',
    this.memoryKiB = 19456, // ~19 MiB (OWASP minimum for Argon2id, t=2, p=1)
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
  });

  final String algorithm;
  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int hashLength;

  static const defaults = KdfParams();

  Map<String, Object> toMap() => {
        'algorithm': algorithm,
        'memoryKiB': memoryKiB,
        'iterations': iterations,
        'parallelism': parallelism,
        'hashLength': hashLength,
      };

  factory KdfParams.fromMap(Map<String, dynamic> m) => KdfParams(
        algorithm: m['algorithm'] as String? ?? 'argon2id',
        memoryKiB: m['memoryKiB'] as int,
        iterations: m['iterations'] as int,
        parallelism: m['parallelism'] as int,
        hashLength: m['hashLength'] as int? ?? 32,
      );
}
