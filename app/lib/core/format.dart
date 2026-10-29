import 'package:intl/intl.dart';

final _rupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _quantity = NumberFormat.decimalPattern('en_IN');

String rupees(num amount) => _rupees.format(amount);

String quantityWithUnit(num quantity, String unit) =>
    '${_quantity.format(quantity)} ${unitLabels[unit] ?? unit}';

String shortDate(DateTime date) => DateFormat('d MMM yyyy').format(date.toLocal());

/// Units allowed by the `listings.unit` check constraint.
const unitLabels = {
  'pieces': 'pieces',
  'bags': 'bags',
  'kg': 'kg',
  'tonnes': 'tonnes',
  'sq_ft': 'sq ft',
  'sq_m': 'sq m',
  'cu_ft': 'cu ft',
  'cu_m': 'cu m',
  'running_ft': 'running ft',
  'metres': 'metres',
  'litres': 'litres',
  'boxes': 'boxes',
  'sets': 'sets',
  'lot': 'lot',
};

/// Values of the `material_condition` enum.
const conditionLabels = {
  'new': 'New',
  'unused_surplus': 'Unused surplus',
  'used_good': 'Used – good',
  'used_fair': 'Used – fair',
};

/// Values of the `listing_status` enum.
const statusLabels = {
  'draft': 'Draft',
  'active': 'Live',
  'sold': 'Sold',
  'removed': 'Removed by admin',
};

/// "+919822012345" -> "+91 98220 12345". Other formats are returned unchanged.
String formatPhone(String phone) {
  final m = RegExp(r'^\+91(\d{5})(\d{5})$').firstMatch(phone);
  return m == null ? phone : '+91 ${m[1]} ${m[2]}';
}
