import 'package:aayamik/core/contact_filter.dart';
import 'package:flutter_test/flutter_test.dart';

// Same cases as supabase/tests/local/schema_test.sql, so the app and the
// database agree.
const blocked = [
  '9876543210',
  'call 98765 43210',
  '+91-98765-43210',
  '098765 43210',
  '9 8 7 6 5 4 3 2 1 0',
  '98-76-54-32-10',
  'nine eight seven six five four three two one zero',
  'nine 8 seven 6 five 4 three 2 one 0',
  '98765432l0',
  '98765 4321O',
  'whatsapp me for rates',
  'Whats App only',
  'contact me for best price',
  'Phone: 22',
  'mob no given after deal',
  'raj@gmail.com',
  'raj (at) gmail (dot) com',
  'raj at gmail dot com',
  'pay to raj@okaxis',
  'follow @rajbuilders',
  'see www.rajbuilders.com',
  'rajbuilders.in for photos',
  'https://example.org/x',
  'wa.me/919876543210',
];

const allowed = [
  '500 bags of ACC cement, 50 kg each',
  'Sizes 1200 1500 1800 mm',
  '6000 7000 8000 bricks available',
  'Price Rs 2,50,000 negotiable',
  'TMT bars 8mm 10mm 12mm 16mm',
  'Available at site. Great condition',
  'Installation material left over',
  'Mono block pump',
  'Solar cell - 20 pcs',
  'Tiles 600 x 600, 120 boxes',
  'One lot of two hundred bricks',
  'Phone cable 90 metres',
  'Andheri East, Mumbai',
  '',
];

void main() {
  for (final s in blocked) {
    test('blocks "$s"', () => expect(containsContactInfo(s), isTrue));
  }
  for (final s in allowed) {
    test('allows "$s"', () => expect(containsContactInfo(s), isFalse));
  }
}
