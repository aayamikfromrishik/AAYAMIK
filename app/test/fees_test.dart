import 'package:aayamik/core/fees.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unlock fee bands match the database', () {
    const expected = {
      1: 10,
      500: 10,
      1000: 10,
      1001: 10,
      1050: 11,
      25000: 250,
      50000: 500,
      50001: 500,
      100000: 500,
      100001: 1000,
      5000000: 1000,
    };
    expected.forEach((price, fee) => expect(unlockFeeRupees(price), fee, reason: 'price $price'));
  });
}
