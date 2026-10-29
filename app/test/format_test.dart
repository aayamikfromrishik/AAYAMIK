import 'package:aayamik/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPhone groups Indian mobile numbers', () {
    expect(formatPhone('+919822012345'), '+91 98220 12345');
    expect(formatPhone('+14155550100'), '+14155550100');
  });

  test('rupees uses Indian grouping', () {
    expect(rupees(250000), '₹2,50,000');
  });
}
