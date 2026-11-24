import 'password_health.dart';

enum RecommendationSeverity { high, medium, low, good }

class Recommendation {
  const Recommendation(this.severity, this.title, this.message);

  final RecommendationSeverity severity;
  final String title;
  final String message;
}

String _n(int count, String singular, [String? plural]) =>
    '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';

/// Turns a report into plain-language advice, most urgent first.
List<Recommendation> buildRecommendations(HealthReport r) {
  if (r.total == 0) return const [];

  final out = <Recommendation>[];

  if (r.weakCount > 0) {
    out.add(Recommendation(
      RecommendationSeverity.high,
      'Replace ${_n(r.weakCount, 'weak password', 'weak passwords')}',
      'Weak passwords can be guessed quickly. Generate a random one of 16 or '
          'more characters and save it over the old password.',
    ));
  }

  if (r.reusedCount > 0) {
    final groups = r.reuseGroups.length;
    out.add(Recommendation(
      RecommendationSeverity.high,
      'Stop reusing passwords',
      '${_n(r.reusedCount, 'entry', 'entries')} share a password across '
          '${_n(groups, 'group', 'groups')}. If one site is breached, attackers try the '
          'same password everywhere. Give each account its own.',
    ));
  }

  if (r.oldCount > 0) {
    out.add(Recommendation(
      RecommendationSeverity.medium,
      'Refresh ${_n(r.oldCount, 'old password', 'old passwords')}',
      'These have not changed in over 6 months. Start with email, banking '
          'and work accounts.',
    ));
  }

  final fair = r.fairIds.length;
  if (fair > 0) {
    out.add(Recommendation(
      RecommendationSeverity.low,
      'Strengthen ${_n(fair, 'fair password', 'fair passwords')}',
      'Longer passphrases or generated passwords are much harder to crack.',
    ));
  }

  if (out.isEmpty) {
    out.add(const Recommendation(
      RecommendationSeverity.good,
      'Everything looks healthy',
      'Your passwords are strong, unique and recently changed. Keep it up.',
    ));
  }
  return out;
}
