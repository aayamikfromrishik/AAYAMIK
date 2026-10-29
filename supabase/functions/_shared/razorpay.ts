import { HttpError, requireEnv } from "./http.ts";

const API = "https://api.razorpay.com/v1";

export async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig), (b) => b.toString(16).padStart(2, "0")).join("");
}

export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

// Signature the Razorpay checkout returns to the app after payment.
export async function isValidPaymentSignature(
  orderId: string,
  paymentId: string,
  signature: string,
): Promise<boolean> {
  const expected = await hmacSha256Hex(requireEnv("RAZORPAY_KEY_SECRET"), `${orderId}|${paymentId}`);
  return timingSafeEqual(expected, signature);
}

// Signature Razorpay puts on webhook calls (X-Razorpay-Signature).
export async function isValidWebhookSignature(rawBody: string, signature: string): Promise<boolean> {
  const expected = await hmacSha256Hex(requireEnv("RAZORPAY_WEBHOOK_SECRET"), rawBody);
  return timingSafeEqual(expected, signature);
}

async function call<T>(method: "GET" | "POST", path: string, body?: unknown): Promise<T> {
  const auth = btoa(`${requireEnv("RAZORPAY_KEY_ID")}:${requireEnv("RAZORPAY_KEY_SECRET")}`);
  const res = await fetch(`${API}${path}`, {
    method,
    headers: { Authorization: `Basic ${auth}`, "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) {
    console.error("Razorpay error", res.status, data);
    throw new HttpError(502, "PAYMENT_PROVIDER_ERROR");
  }
  return data as T;
}

export interface RazorpayOrder {
  id: string;
  amount: number;
  currency: string;
}

export interface RazorpayPayment {
  id: string;
  order_id: string;
  amount: number;
  status: "created" | "authorized" | "captured" | "refunded" | "failed";
}

export function createOrder(
  amountPaise: number,
  receipt: string,
  notes: Record<string, string>,
): Promise<RazorpayOrder> {
  return call("POST", "/orders", { amount: amountPaise, currency: "INR", receipt, notes });
}

export function fetchPayment(paymentId: string): Promise<RazorpayPayment> {
  return call("GET", `/payments/${encodeURIComponent(paymentId)}`);
}
