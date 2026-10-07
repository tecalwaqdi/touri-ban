/**
 * Canonical country finance for NEW operations.
 * Historical order snapshots are never rewritten here.
 *
 * FX: local_units_per_sar means how many local currency units equal 1 SAR.
 * gateway_sar = local_amount / local_units_per_sar
 *
 * Saudi Arabia (ISO SA or currency SAR) defaults FX to 1 when the field is absent.
 * Other countries must have local_units_per_sar > 0. Missing is not zero.
 */

const PLATFORM_COMMISSION_PERCENT = 15;
const MIN_CASH_WALLET_SAR = 50;
const SAUDI_FALLBACK_PHONE = "966533356126";

function num(value) {
  if (value === null || value === undefined || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function str(value) {
  return String(value || "").trim();
}

function readCountry(raw) {
  const c = raw || {};
  const iso2 = str(c.iso_code || c.iso2 || c.isoCode).toUpperCase();
  const currency = str(
    c.currency_code || c.currencyCode || c.currency || c.Currency,
  ).toUpperCase();
  const symbol = str(
    c.currency_symbol || c.currencySymbol || c.CurrencySymbol,
  );
  const vatExplicit = c.vat_percent != null ? num(c.vat_percent) : num(c.vat);
  const fxExplicit = num(c.local_units_per_sar);
  const cashEnabled = c.cash_enabled !== false;
  const onlineEnabled = c.online_payment_enabled !== false;
  return {
    countryId: str(c.country_id || c.id),
    iso2,
    currency,
    symbol,
    vatPercent: vatExplicit,
    fxExplicit,
    cashEnabled,
    onlineEnabled,
    version: num(c.finance_config_version) || 1,
  };
}

function resolvedFx(config) {
  if (config.fxExplicit != null && config.fxExplicit > 0) return config.fxExplicit;
  if (config.iso2 === "SA" || config.currency === "SAR") return 1;
  return null;
}

function financeStatus(raw) {
  const config = readCountry(raw);
  const fx = resolvedFx(config);
  const vat = config.vatPercent;
  if (!config.currency) return "INVALID";
  if (vat == null || vat < 0 || PLATFORM_COMMISSION_PERCENT + vat >= 100) {
    if (vat == null) return "VAT MISSING";
    return "INVALID";
  }
  if (fx == null) return "FX MISSING";
  return "CONFIGURED";
}

function assertNewFinanceConfig(raw, {requireOnline = false} = {}) {
  const config = readCountry(raw);
  const status = financeStatus(raw);
  const fx = resolvedFx(config);
  if (!config.currency) {
    const err = new Error("INVALID_COUNTRY_FINANCE");
    err.code = "INVALID_COUNTRY_FINANCE";
    throw err;
  }
  if (config.vatPercent == null) {
    const err = new Error("VAT_CONFIG_MISSING");
    err.code = "VAT_CONFIG_MISSING";
    throw err;
  }
  if (config.vatPercent < 0 || PLATFORM_COMMISSION_PERCENT + config.vatPercent >= 100) {
    const err = new Error("INVALID_VAT");
    err.code = "INVALID_VAT";
    throw err;
  }
  if (requireOnline) {
    if (config.onlineEnabled === false) {
      const err = new Error("ONLINE_PAYMENT_DISABLED");
      err.code = "ONLINE_PAYMENT_DISABLED";
      throw err;
    }
    if (fx == null || status === "FX MISSING") {
      const err = new Error("FX_CONFIG_MISSING");
      err.code = "FX_CONFIG_MISSING";
      throw err;
    }
  }
  return {config, fx, status};
}

function splitGross(gross, vatPercent) {
  const g = Number(gross);
  const vat = Number(vatPercent);
  if (!Number.isFinite(g) || g < 0) {
    const err = new Error("INVALID_GROSS");
    err.code = "INVALID_GROSS";
    throw err;
  }
  if (!Number.isFinite(vat) || vat < 0 || PLATFORM_COMMISSION_PERCENT + vat >= 100) {
    const err = new Error("INVALID_VAT");
    err.code = "INVALID_VAT";
    throw err;
  }
  const commission = roundMoney(g * (PLATFORM_COMMISSION_PERCENT / 100));
  const tax = roundMoney(g * (vat / 100));
  const companyDue = roundMoney(commission + tax);
  const driverNet = roundMoney(g - companyDue);
  return {
    gross: roundMoney(g),
    platformCommissionPercent: PLATFORM_COMMISSION_PERCENT,
    countryTaxPercent: vat,
    commission,
    tax,
    companyDue,
    driverNet,
  };
}

function roundMoney(n) {
  return Math.round(n * 100) / 100;
}

function localToGatewaySar(localAmount, fxLocalPerSar) {
  const local = Number(localAmount);
  const fx = Number(fxLocalPerSar);
  if (!Number.isFinite(local) || local < 0 || !Number.isFinite(fx) || fx <= 0) {
    const err = new Error("FX_CONFIG_MISSING");
    err.code = "FX_CONFIG_MISSING";
    throw err;
  }
  const gatewaySar = local / fx;
  const gatewayMinorSar = Math.round(gatewaySar * 100);
  return {
    localAmount: roundMoney(local),
    gatewayAmountSar: roundMoney(gatewayMinorSar / 100),
    gatewayMinorSar,
    gatewayCurrency: "SAR",
    fxLocalPerSar: fx,
  };
}

function minCashLocal(fxLocalPerSar) {
  const fx = Number(fxLocalPerSar);
  if (!Number.isFinite(fx) || fx <= 0) {
    const err = new Error("FX_CONFIG_MISSING");
    err.code = "FX_CONFIG_MISSING";
    throw err;
  }
  return roundMoney(MIN_CASH_WALLET_SAR * fx);
}

function quickTopUpLocal(fxLocalPerSar) {
  return minCashLocal(fxLocalPerSar);
}

function normalizeWhatsappDigits(phone) {
  let d = String(phone || "").replace(/[^\d]/g, "");
  if (d.startsWith("00")) d = d.slice(2);
  return d;
}

function whatsappHref(phone, message) {
  const digits = normalizeWhatsappDigits(phone);
  if (!digits) return "";
  const text = encodeURIComponent(String(message || ""));
  return text ? `https://wa.me/${digits}?text=${text}` : `https://wa.me/${digits}`;
}

function isSaudiCountry(iso2, countryPath) {
  const iso = str(iso2).toUpperCase();
  if (iso === "SA" || iso === "SAU") return true;
  const path = str(countryPath).toLowerCase();
  return path === "countries/saudi_arabia" || path.endsWith("/saudi_arabia");
}

/**
 * Saudi fallback only when the country is Saudi Arabia and the Agent phone is missing.
 * Any other country without an Agent phone is SUPPORT_NOT_CONFIGURED.
 */
function resolveSupportPhone({iso2, countryPath, agentPhone} = {}) {
  const digits = normalizeWhatsappDigits(agentPhone);
  if (digits.length >= 8) {
    return {ok: true, digits, fallback: false};
  }
  if (isSaudiCountry(iso2, countryPath)) {
    return {ok: true, digits: SAUDI_FALLBACK_PHONE, fallback: true};
  }
  return {ok: false, code: "SUPPORT_NOT_CONFIGURED", digits: ""};
}

/**
 * Customer booking commercial amount stays local. N-Genius is charged the SAR snapshot only.
 * Client gateway amounts are ignored; callers pass the server quote major.
 */
function bookingGatewaySnapshot(localAmountMajor, countryRaw, {now = new Date()} = {}) {
  const checked = assertNewFinanceConfig(countryRaw, {requireOnline: true});
  const gateway = localToGatewaySar(localAmountMajor, checked.fx);
  return {
    local_amount: gateway.localAmount,
    local_currency: checked.config.currency,
    local_amount_minor: Math.round(gateway.localAmount * 100),
    fx_local_per_sar: checked.fx,
    gateway_amount_sar: gateway.gatewayAmountSar,
    gateway_minor_sar: gateway.gatewayMinorSar,
    gateway_currency: "SAR",
    fx_snapshot_at: now.toISOString(),
    country_id: checked.config.countryId,
    country_iso2: checked.config.iso2,
  };
}

function expectedGatewayMinor(session) {
  const snap = session || {};
  if (snap.gateway_minor_sar != null && snap.gateway_minor_sar !== "") {
    return Number(snap.gateway_minor_sar);
  }
  return Number(snap.amount_minor ?? snap.amount_halalas);
}

function assertGatewayAmountMatches(session, gatewayMinor) {
  const expected = expectedGatewayMinor(session);
  if (!Number.isFinite(expected) || Number(gatewayMinor) !== expected) {
    const err = new Error("PAYMENT_AMOUNT_MISMATCH");
    err.code = "PAYMENT_AMOUNT_MISMATCH";
    throw err;
  }
  return expected;
}

function buildFinanceSnapshot(raw, {now = new Date()} = {}) {
  const checked = assertNewFinanceConfig(raw, {requireOnline: false});
  const fx = checked.fx;
  return {
    country_id: checked.config.countryId,
    country_iso2: checked.config.iso2,
    local_currency: checked.config.currency,
    currency_symbol: checked.config.symbol,
    platform_commission_percent: PLATFORM_COMMISSION_PERCENT,
    country_tax_percent: checked.config.vatPercent,
    fx_local_per_sar: fx,
    finance_config_version: checked.config.version,
    finance_snapshot_at: now.toISOString(),
  };
}

module.exports = {
  PLATFORM_COMMISSION_PERCENT,
  MIN_CASH_WALLET_SAR,
  SAUDI_FALLBACK_PHONE,
  readCountry,
  resolvedFx,
  financeStatus,
  assertNewFinanceConfig,
  splitGross,
  localToGatewaySar,
  minCashLocal,
  quickTopUpLocal,
  normalizeWhatsappDigits,
  whatsappHref,
  isSaudiCountry,
  resolveSupportPhone,
  bookingGatewaySnapshot,
  expectedGatewayMinor,
  assertGatewayAmountMatches,
  buildFinanceSnapshot,
};
