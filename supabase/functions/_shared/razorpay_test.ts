import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  hmacSha256Hex,
  isValidPaymentSignature,
  isValidWebhookSignature,
  timingSafeEqual,
} from "./razorpay.ts";

Deno.test("hmacSha256Hex matches the RFC 4231 test vector", async () => {
  assertEquals(
    await hmacSha256Hex("Jefe", "what do ya want for nothing?"),
    "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
  );
});

Deno.test("timingSafeEqual", () => {
  assert(timingSafeEqual("abc", "abc"));
  assert(!timingSafeEqual("abc", "abd"));
  assert(!timingSafeEqual("abc", "abcd"));
});

Deno.test("payment and webhook signatures", async () => {
  Deno.env.set("RAZORPAY_KEY_SECRET", "key_secret");
  Deno.env.set("RAZORPAY_WEBHOOK_SECRET", "hook_secret");

  const good = await hmacSha256Hex("key_secret", "order_1|pay_1");
  assert(await isValidPaymentSignature("order_1", "pay_1", good));
  assert(!(await isValidPaymentSignature("order_1", "pay_2", good)));

  const body = '{"event":"payment.captured"}';
  assert(await isValidWebhookSignature(body, await hmacSha256Hex("hook_secret", body)));
  assert(!(await isValidWebhookSignature(body + " ", await hmacSha256Hex("hook_secret", body))));
});
