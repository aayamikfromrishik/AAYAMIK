// POST { image_id } — called by the app after uploading a listing photo to the
// private "listing-uploads" bucket and inserting its listing_images row.
//
// Rejects photos with human faces, QR/barcodes, or text that contains contact
// details. Clean photos are copied to the public "listing-images" bucket.
// The app also runs the same checks on the phone (ML Kit) before uploading;
// this is the check that cannot be skipped.
import { HttpError, json, readJson, requireEnv, serve } from "../_shared/http.ts";
import { adminClient, dbError, requireUser } from "../_shared/supabase.ts";

const MAX_BYTES = 5 * 1024 * 1024;
const QR_LABELS = new Set(["qr code", "barcode"]);
const LABEL_MIN_SCORE = 0.6;

const REJECTION = {
  face: "Photos with people's faces are not allowed. Please photograph only the material.",
  qr: "Photos with QR codes or barcodes are not allowed.",
  contact:
    "This photo seems to show a phone number, email or website. Please use a photo without contact details.",
  too_large: "Photo is larger than 5 MB.",
};

interface VisionResponse {
  faceAnnotations?: unknown[];
  fullTextAnnotation?: { text?: string };
  labelAnnotations?: { description: string; score: number }[];
  error?: { message: string };
}

async function annotate(bytes: Uint8Array): Promise<VisionResponse> {
  let binary = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  const res = await fetch(
    `https://vision.googleapis.com/v1/images:annotate?key=${requireEnv("GOOGLE_VISION_API_KEY")}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        requests: [{
          image: { content: btoa(binary) },
          features: [
            { type: "FACE_DETECTION", maxResults: 1 },
            { type: "TEXT_DETECTION" },
            { type: "LABEL_DETECTION", maxResults: 20 },
          ],
        }],
      }),
    },
  );
  const data = await res.json();
  const result = data?.responses?.[0] as VisionResponse | undefined;
  if (!res.ok || !result || result.error) {
    console.error("Vision API error", res.status, JSON.stringify(data));
    throw new HttpError(502, "IMAGE_CHECK_UNAVAILABLE");
  }
  return result;
}

serve(async (req) => {
  const user = await requireUser(req);
  const { image_id } = await readJson<{ image_id?: string }>(req);
  if (!image_id) throw new HttpError(400, "IMAGE_ID_REQUIRED");

  const db = adminClient();
  const { data: image, error } = await db
    .from("listing_images")
    .select("id, upload_path, status, rejection_reason, listings!inner(seller_id)")
    .eq("id", image_id)
    .maybeSingle();
  if (error) throw dbError(error);
  // deno-lint-ignore no-explicit-any
  if (!image || (image.listings as any).seller_id !== user.id) {
    throw new HttpError(404, "IMAGE_NOT_FOUND");
  }
  if (image.status !== "pending") {
    return json({ status: image.status, reason: image.rejection_reason });
  }

  const reject = async (key: keyof typeof REJECTION) => {
    const { error: updError } = await db
      .from("listing_images")
      .update({ status: "rejected", rejection_reason: REJECTION[key] })
      .eq("id", image.id);
    if (updError) throw dbError(updError);
    return json({ status: "rejected", reason: REJECTION[key] });
  };

  const { data: blob, error: dlError } = await db.storage.from("listing-uploads").download(image.upload_path);
  if (dlError || !blob) throw new HttpError(404, "UPLOAD_NOT_FOUND");
  if (blob.size > MAX_BYTES) return await reject("too_large");
  const bytes = new Uint8Array(await blob.arrayBuffer());

  const vision = await annotate(bytes);

  if ((vision.faceAnnotations?.length ?? 0) > 0) return await reject("face");

  const hasCode = (vision.labelAnnotations ?? []).some(
    (l) => l.score >= LABEL_MIN_SCORE && QR_LABELS.has(l.description.toLowerCase()),
  );
  if (hasCode) return await reject("qr");

  const text = vision.fullTextAnnotation?.text ?? "";
  if (text) {
    const { data: hasContact, error: rpcError } = await db.rpc("contains_contact_info", { input: text });
    if (rpcError) throw dbError(rpcError);
    if (hasContact) return await reject("contact");
  }

  // Clean: publish a copy, then drop the private original.
  const { error: upError } = await db.storage
    .from("listing-images")
    .upload(image.upload_path, bytes, { contentType: blob.type || "image/jpeg", upsert: true });
  if (upError) throw new Error(`Publish failed: ${upError.message}`);

  const { error: updError } = await db
    .from("listing_images")
    .update({ status: "approved", public_path: image.upload_path })
    .eq("id", image.id);
  if (updError) throw dbError(updError);

  await db.storage.from("listing-uploads").remove([image.upload_path]);

  return json({ status: "approved", public_path: image.upload_path });
});
