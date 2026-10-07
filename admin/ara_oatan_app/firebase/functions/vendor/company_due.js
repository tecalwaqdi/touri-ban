/**
 * Server-owned company-due payment decision.
 * Client outstandingDue is ignored.
 */
function decideCompanyDuePayment({
  requested,
  walletBalance,
  walletCurrency,
  serverDue,
  serverCurrency,
}) {
  const amount = Number(requested);
  const balance = Number(walletBalance);
  const due = Number(serverDue);
  const wallet = String(walletCurrency || "").toUpperCase();
  const dueCurrency = String(serverCurrency || "").toUpperCase();
  if (!wallet || !dueCurrency || wallet !== dueCurrency) {
    return {ok: false, code: "CURRENCY_MISMATCH"};
  }
  if (!Number.isFinite(due) || due <= 0) {
    return {ok: false, code: "NO_COMPANY_DUE"};
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    return {ok: false, code: "NO_COMPANY_DUE"};
  }
  if (!Number.isFinite(balance) || amount > balance) {
    return {ok: false, code: "INSUFFICIENT_WALLET_BALANCE"};
  }
  if (amount > due) {
    return {ok: false, code: "PAYMENT_EXCEEDS_COMPANY_DUE"};
  }
  return {
    ok: true,
    dueBefore: due,
    dueAfter: Math.round((due - amount) * 100) / 100,
  };
}

/**
 * Cash company due from analyzed order lines, minus confirmed settlements
 * and wallet company_due_payment rows in the same currency.
 * Amounts are major units.
 */
function outstandingCompanyDue({
  cashDueMinor = 0,
  settlementPaidMinor = 0,
  walletPaidMinor = 0,
  currency,
} = {}) {
  const outstandingMinor = Math.max(
    0,
    Number(cashDueMinor || 0) -
      Number(settlementPaidMinor || 0) -
      Number(walletPaidMinor || 0),
  );
  return {
    currency: String(currency || "").toUpperCase(),
    minor: outstandingMinor,
    major: Math.round(outstandingMinor) / 100,
  };
}

module.exports = {
  decideCompanyDuePayment,
  outstandingCompanyDue,
};
