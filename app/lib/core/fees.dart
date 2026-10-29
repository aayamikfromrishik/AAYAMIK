/// Unlock fee the buyer pays to see the seller's contact and exact location.
///
/// Mirrors `public.unlock_fee_rupees` in the database, which is what is
/// actually charged; this copy is only for showing the fee in the app.
///   up to ₹1,000          -> ₹10
///   ₹1,001 – ₹50,000      -> 1% (rounded)
///   ₹50,001 – ₹1,00,000   -> ₹500
///   above ₹1,00,000       -> ₹1,000
int unlockFeeRupees(int priceRupees) {
  if (priceRupees <= 1000) return 10;
  if (priceRupees <= 50000) return (priceRupees / 100).round();
  if (priceRupees <= 100000) return 500;
  return 1000;
}
