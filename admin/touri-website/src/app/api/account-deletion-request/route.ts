import { NextResponse } from "next/server";

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const REGION = "us-central1";
const CALLABLE =
  `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/createAccountDeletionRequest`;

type Body = {
  accountType?: string;
  contact?: string;
  note?: string;
  locale?: string;
};

/**
 * Public web → verified support request only.
 * Never deletes Auth/Firestore from this endpoint.
 */
export async function POST(request: Request) {
  let body: Body;
  try {
    body = (await request.json()) as Body;
  } catch {
    return NextResponse.json({ ok: false, error: "invalid_json" }, { status: 400 });
  }

  const accountType = String(body.accountType || "").trim();
  const contact = String(body.contact || "").trim();
  const note = String(body.note || "").trim().slice(0, 1000);
  const locale = String(body.locale || "ar").trim();

  if (!["customer", "driver"].includes(accountType)) {
    return NextResponse.json({ ok: false, error: "invalid_account_type" }, { status: 400 });
  }
  if (contact.length < 5 || contact.length > 120) {
    return NextResponse.json({ ok: false, error: "invalid_contact" }, { status: 400 });
  }

  try {
    const res = await fetch(CALLABLE, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        data: { accountType, contact, note, locale },
      }),
    });

    const json = (await res.json().catch(() => null)) as {
      result?: { ok?: boolean; requestId?: string; status?: string };
      error?: { message?: string; status?: string };
    } | null;

    if (res.ok && json?.result?.ok) {
      return NextResponse.json({
        ok: true,
        requestId: json.result.requestId,
        status: json.result.status || "pending_verification",
      });
    }

    console.warn("createAccountDeletionRequest failed", {
      status: res.status,
      error: json?.error,
      accountType,
      contactMasked: contact.slice(0, 3) + "***",
    });

    return NextResponse.json(
      {
        ok: false,
        error: "callable_unavailable",
        message: json?.error?.message || "Request backend unavailable",
      },
      { status: 503 },
    );
  } catch (e) {
    console.warn("account deletion request proxy failed", String(e));
    return NextResponse.json(
      { ok: false, error: "network_error" },
      { status: 503 },
    );
  }
}
