#!/usr/bin/env node
/**
 * Pre-launch wallet reset. DEFAULT IS DRY RUN.
 * Does not delete ledger history. Does not run unless --execute is passed.
 *
 *   node prelaunch_wallet_reset.js --dry-run
 *   node prelaunch_wallet_reset.js --country kyrgyzstan --qa-only --dry-run
 *   node prelaunch_wallet_reset.js --driver <uid> --execute
 *
 * Real execution writes a ledger row:
 *   type=pre_launch_balance_reset
 *   previous_balance, new_balance=0, currency, reason, actor, timestamp
 */
const args = process.argv.slice(2);
const has = (flag) => args.includes(flag);
const value = (flag) => {
  const i = args.indexOf(flag);
  return i >= 0 ? args[i + 1] : "";
};

const dryRun = !has("--execute") || has("--dry-run");
const country = value("--country") || "";
const driver = value("--driver") || "";
const qaOnly = has("--qa-only");

function plan() {
  return {
    dryRun,
    country: country || null,
    driver: driver || null,
    qaOnly,
    ledger: {
      type: "pre_launch_balance_reset",
      new_balance: 0,
      reason: "pre_launch_balance_reset",
    },
    executed: false,
  };
}

if (require.main === module) {
  const result = plan();
  console.log(JSON.stringify(result, null, 2));
  if (!dryRun) {
    console.error("REFUSED: live wallet reset is not executed by this tool in this build.");
    process.exit(2);
  }
}

module.exports = { plan };
