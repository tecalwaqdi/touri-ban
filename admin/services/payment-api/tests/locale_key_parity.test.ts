import {readFileSync} from "node:fs";
import {describe, expect, it} from "vitest";

const LANGS = ["ar", "en", "ru", "ky", "fr", "ur", "pt"] as const;
const ROOTS = [
  "../../../mndob-main/assets/langs",
  "../../../ara_oatan_app/assets/langs",
];

const REQUIRED = [
  "common.logout",
  "wallet.title",
  "wallet.total_earnings",
  "wallet.today_net_earnings",
  "wallet.custom_topup",
  "wallet.quick_topup",
  "wallet.pay_company_due",
  "bank.title",
  "bank.bank_name",
  "bank.account_number",
  "bank.iban",
  "bank.account_holder",
  "bank.update",
  "support.contact_directly",
  "support.whatsapp_message",
  "finance.gross",
  "finance.commission",
  "finance.tax",
  "finance.company_due",
  "finance.driver_net",
];

function load(root: string, lang: string) {
  return JSON.parse(readFileSync(new URL(`${root}/${lang}.json`, import.meta.url), "utf8"));
}

describe("production locale key parity", () => {
  for (const root of ROOTS) {
    it(`${root} has the same active keys in all 7 languages`, () => {
      const maps = LANGS.map((lang) => load(root, lang) as Record<string, string>);
      const union = new Set<string>();
      for (const map of maps) {
        for (const key of Object.keys(map)) union.add(key);
      }
      for (const key of union) {
        for (const map of maps) {
          expect(map[key], key).toEqual(expect.any(String));
          expect(String(map[key]).trim().length, key).toBeGreaterThan(0);
        }
      }
      for (const key of REQUIRED) {
        expect(union.has(key), key).toBe(true);
      }
    });
  }
});
