import { describe, expect, it } from "vitest";
import { paidActivationPatch } from "../src/lib/bookings/build-order";

describe("paidActivationPatch", () => {
  it("activates unpaid order into driver pool fields", () => {
    const patch = paidActivationPatch(
      {
        user_id: "u1",
        carPath: "type_car/c",
        countryPath: "countries/sa",
        provider_order_ref: "ng-1",
      },
      "session-abc",
    );
    expect(patch.status_code).toBe("pending_driver");
    expect(patch.payment_status).toBe("paid");
    expect(patch.ALLNOW).toBe(true);
    expect(patch.ngeniusOrderId).toBe("ng-1");
    expect(patch.halh_text).toBe("بإنتظار قبول المندوب");
  });
});
