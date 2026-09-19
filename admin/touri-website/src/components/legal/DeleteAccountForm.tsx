"use client";

import { useState } from "react";
import type { Locale } from "@/i18n/config";
import type { Dictionary } from "@/i18n/get-dictionary";

type Props = {
  locale: Locale;
  dict: Dictionary;
};

export function DeleteAccountForm({ locale, dict }: Props) {
  const d = dict.deleteAccount;
  const [accountType, setAccountType] = useState<"customer" | "driver">("customer");
  const [contact, setContact] = useState("");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setMessage(null);
    setError(null);
    try {
      const res = await fetch("/api/account-deletion-request", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          accountType,
          contact,
          note,
          locale,
        }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        ok?: boolean;
        requestId?: string;
        error?: string;
      };
      if (!res.ok || !body.ok) {
        setError(d.error);
        return;
      }
      setMessage(
        body.requestId ? `${d.success} (#${body.requestId})` : d.success,
      );
      setContact("");
      setNote("");
    } catch {
      setError(d.error);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="space-y-4" onSubmit={onSubmit}>
      <fieldset className="space-y-2">
        <legend className="text-sm font-semibold">{d.accountType}</legend>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="radio"
            name="accountType"
            checked={accountType === "customer"}
            onChange={() => setAccountType("customer")}
          />
          {d.customer}
        </label>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="radio"
            name="accountType"
            checked={accountType === "driver"}
            onChange={() => setAccountType("driver")}
          />
          {d.driver}
        </label>
      </fieldset>

      <label className="block text-sm font-semibold">
        {d.contact}
        <input
          required
          value={contact}
          onChange={(e) => setContact(e.target.value)}
          className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
          autoComplete="email"
        />
      </label>

      <label className="block text-sm font-semibold">
        {d.note}
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          rows={3}
          className="mt-1 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm"
        />
      </label>

      <button
        type="submit"
        disabled={busy}
        className="rounded-full bg-primary px-5 py-2.5 text-sm font-bold text-white disabled:opacity-60"
      >
        {d.submit}
      </button>

      {message ? <p className="text-sm font-semibold text-primary">{message}</p> : null}
      {error ? <p className="text-sm font-semibold text-red-600">{error}</p> : null}
    </form>
  );
}
