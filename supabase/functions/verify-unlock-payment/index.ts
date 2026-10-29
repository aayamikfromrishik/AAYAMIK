// POST { razorpay_order_id, razorpay_payment_id, razorpay_signature }
// Called by the app right after checkout succeeds, so the contact unlocks
// instantly. The webhook does the same thing as a backup.
import { HttpError, json, readJson, serve } from "../_shared/http.ts";
import { adminClient, dbError, requireUser } from "../_shared/supabase.ts";
import { fetchPayment, isValidPaymentSignature } from "../_shared/razorpay.ts";

interface Body {
  razorpay_order_id?: string;
  razorpay_payment_id?: string;
  razorpay_signature?: string;
}

serve(async (req) => {
  const user = await requireUser(req);
  const { razorpay_order_id: orderId, razorpay_payment_id: paymentId, razorpay_signature: signature } =
    await readJson<Body>(req);
  if (!orderId || !paymentId || !signature) throw new HttpError(400, "MISSING_PAYMENT_FIELDS");

  if (!(await isValidPaymentSignature(orderId, paymentId, signature))) {
    throw new HttpError(400, "INVALID_SIGNATURE");
  }

  const db = adminClient();
  const { data: unlock, error } = await db
    .from("unlocks")
    .select("id, listing_id, buyer_id")
    .eq("razorpay_order_id", orderId)
    .maybeSingle();
  if (error) throw dbError(error);
  if (!unlock || unlock.buyer_id !== user.id) throw new HttpError(404, "ORDER_NOT_FOUND");

  // Don't trust the amount from the app; ask Razorpay.
  const payment = await fetchPayment(paymentId);
  if (payment.order_id !== orderId) throw new HttpError(400, "PAYMENT_ORDER_MISMATCH");
  if (payment.status !== "captured") {
    // Auto-capture usually finishes within seconds; the webhook will complete it.
    return json({ status: "processing", listing_id: unlock.listing_id }, 202);
  }

  const { data: status, error: markError } = await db.rpc("mark_unlock_paid", {
    p_razorpay_order_id: orderId,
    p_razorpay_payment_id: paymentId,
    p_amount_paise: payment.amount,
  });
  if (markError) throw dbError(markError);

  return json({ status, listing_id: unlock.listing_id });
});
