/// Turns user input like "github.com/login" into an https Uri.
/// Returns null for anything that is not a plausible http(s) web address,
/// so schemes like javascript: or intent: can never be launched.
Uri? normalizeWebUrl(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final withScheme = text.contains('://') ? text : 'https://$text';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty || !uri.host.contains('.')) return null;
  return uri;
}
