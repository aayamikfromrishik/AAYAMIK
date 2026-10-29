// Razorpay webhook. Subscribe to: payment.captured, refund.processed.
// Deployed without JWT verification (see supabase/config.toml); trust comes
// from the X-Razorpay-Signature header instead.
import { json, serve } from "../_shared/http.ts";
import { adminClient } from "../_shared/supabase.ts";
import { isValidWebhookSignature } from "../_shared/razorpay.ts";

interface WebhookEvent {
  event: string;
  payload: {
    payment?: { entity: { id: string; order_id: string; amount: number } };
    refund?: { entity: { id: string; payment_id: string } };
  };
}

serve(async (req) => {
  const raw = await req.text();
  const signature = req.headers.get("X-Razorpay-Signature") ?? "";
  if (!(await isValidWebhookSignature(raw, signature))) {
    return json({ error: "INVALID_SIGNATURE" }, 400);
  }

  const event = JSON.parse(raw) as WebhookEvent;
  const db = adminClient();

  if (event.event === "payment.captured" && event.payload.payment) {
    const p = event.payload.payment.entity;
    const { error } = await db.rpc("mark_unlock_paid", {
      p_razorpay_order_id: p.order_id,
      p_razorpay_payment_id: p.id,
      p_amount_paise: p.amount,
    });
    // ORDER_NOT_FOUND: a payment that isn't an unlock (e.g. made from the
    // dashboard). Acknowledge it so Razorpay stops retrying.
    if (error && error.message !== "ORDER_NOT_FOUND") {
      console.error("mark_unlock_paid failed", error);
      return json({ error: "RETRY" }, 500);
    }
  }

  if (event.event === "refund.processed" && event.payload.refund) {
    const { error } = await db.rpc("mark_unlock_refunded", {
      p_razorpay_payment_id: event.payload.refund.entity.payment_id,
    });
    if (error) {
      console.error("mark_unlock_refunded failed", error);
      return json({ error: "RETRY" }, 500);
    }
  }

  return json({ ok: true });
});
