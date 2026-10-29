// POST { listing_id } -> Razorpay order for the listing's unlock fee.
// The app opens Razorpay checkout with the returned order_id and key_id.
import { HttpError, json, readJson, requireEnv, serve } from "../_shared/http.ts";
import { adminClient, dbError, requireUser } from "../_shared/supabase.ts";
import { createOrder } from "../_shared/razorpay.ts";

serve(async (req) => {
  const user = await requireUser(req);
  const { listing_id } = await readJson<{ listing_id?: string }>(req);
  if (!listing_id) throw new HttpError(400, "LISTING_ID_REQUIRED");

  const db = adminClient();

  const { data: fee, error: prepError } = await db.rpc("prepare_unlock", {
    p_listing_id: listing_id,
    p_buyer_id: user.id,
  });
  if (prepError) throw dbError(prepError);

  const order = await createOrder(
    (fee as number) * 100,
    `unlock_${crypto.randomUUID().slice(0, 30)}`,
    { listing_id, buyer_id: user.id },
  );

  const { error: recordError } = await db.rpc("record_unlock_order", {
    p_listing_id: listing_id,
    p_buyer_id: user.id,
    p_fee_rupees: fee,
    p_razorpay_order_id: order.id,
  });
  if (recordError) throw dbError(recordError);

  return json({
    order_id: order.id,
    amount_paise: order.amount,
    currency: order.currency,
    fee_rupees: fee,
    key_id: requireEnv("RAZORPAY_KEY_ID"),
  });
});
