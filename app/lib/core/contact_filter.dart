/// Detects phone numbers, emails, links and "WhatsApp me"-style hints.
///
/// Port of `public.contains_contact_info` in the database. The database check
/// is the one that counts; this copy gives instant feedback while typing and
/// checks text read from photos on the phone before upload. Keep both in sync
/// (test cases: supabase/tests/local/schema_test.sql and
/// test/contact_filter_test.dart).
bool containsContactInfo(String? input) {
  if (input == null || input.trim().isEmpty) return false;
  var t = input.toLowerCase();

  if (_email.hasMatch(t) || _spokenEmail.hasMatch(t)) return true;
  if (_upiId.hasMatch(t) || _handle.hasMatch(t)) return true;
  if (_link.hasMatch(t)) return true;
  if (_hint.hasMatch(t) || _labelledNumber.hasMatch(t)) return true;

  _numberWords.forEach((word, digit) {
    t = t.replaceAll(RegExp('\\b$word\\b'), digit);
  });

  t = t
      .replaceAll(RegExp(r'(?<=\d)o(?=\d|[^a-z]|$)'), '0')
      .replaceAll(RegExp(r'(?<=[^a-z]|^)o(?=\d)'), '0')
      .replaceAll(RegExp(r'(?<=\d)[il](?=\d|[^a-z]|$)'), '1')
      .replaceAll(RegExp(r'(?<=[^a-z]|^)[il](?=\d)'), '1');

  // Numbers as written.
  for (final m in RegExp(r'\d{10,}').allMatches(t)) {
    if (RegExp(r'[6-9]\d{9}').hasMatch(m[0]!)) return true;
  }

  // Separators between digits removed ("98765 43210", "9 8 7 6 ...").
  final collapsed = t.replaceAll(RegExp(r'(?<=\d)[\s\-.()/+,_*|]{1,3}(?=\d)'), '');
  for (final m in RegExp(r'\d+').allMatches(collapsed)) {
    final run = m[0]!;
    if (run.length >= 10 && run.length <= 13 && _indianMobile.hasMatch(run)) return true;
  }

  return false;
}

final _email = RegExp(
    r'[a-z0-9._%+-]+\s*(@|\(at\)|\[at\])\s*[a-z0-9-]+\s*(\.|\(dot\)|\[dot\])\s*[a-z]{2,}');
final _spokenEmail = RegExp(r'[a-z0-9._-]+\s+at\s+[a-z0-9-]+\s+dot\s+[a-z]{2,}');
final _upiId = RegExp(r'[a-z0-9._-]{2,}@[a-z]{2,}');
final _handle = RegExp(r'(^|\s)@[a-z0-9_.]{3,}');
final _link = RegExp(
    r'(https?://|www\.|wa\.me|t\.me|bit\.ly|\b[a-z0-9-]{2,}\.(com|in|net|org|co|io|me|app|link)\b)');
final _hint = RegExp(r'\b(whats\s*app|watsapp|whatsap|wtsp|telegram|instagram|insta|facebook|gmail'
    r'|yahoo|call\s+me|call\s+on|call\s+at|ring\s+me|dm\s+me|text\s+me|msg\s+me|message\s+me'
    r'|contact\s+(me|on|at|no|number|details)|my\s+number|ph(one)?\s*(no|num|number)'
    r'|mob(ile)?\s*(no|num|number)|cell\s*(no|number)|mo(\.|\s)\s*no)\b');
final _labelledNumber = RegExp(r'\b(ph|phone|mob|mobile|cell|contact|tel)\s*[:#]');
final _indianMobile = RegExp(r'^(\+?91|0)?[6-9]\d{9}$');

const _numberWords = {
  'zero': '0',
  'one': '1',
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
};
