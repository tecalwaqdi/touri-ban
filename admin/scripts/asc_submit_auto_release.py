#!/usr/bin/env python3
"""Create App Store versions, attach builds, submit for review with AFTER_APPROVAL."""
from __future__ import annotations

import base64
import json
import pathlib
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

KEY_ID = "CXA8LB4ADH"
ISSUER = "33620f9e-4268-4130-a32b-d1ee48bddc41"
PEM = pathlib.Path.home() / ".appstoreconnect/private_keys/AuthKey_CXA8LB4ADH.p8"

APPS = {
    "customer": {
        "id": "6754410562",
        "bundle": "com.mycompany.araoatanapp2",
        "version": "9.1.45",
        "build": "66",
    },
    "driver": {
        "id": "6754537170",
        "bundle": "com.mycompany.mndob3",
        "version": "11.1.25",
        "build": "54",
    },
}


def b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def make_jwt() -> str:
    now = int(time.time())
    h = b64url(
        json.dumps(
            {"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}, separators=(",", ":")
        ).encode()
    )
    p = b64url(
        json.dumps(
            {
                "iss": ISSUER,
                "iat": now,
                "exp": now + 1200,
                "aud": "appstoreconnect-v1",
            },
            separators=(",", ":"),
        ).encode()
    )
    sig_der = subprocess.check_output(
        ["openssl", "dgst", "-sha256", "-sign", str(PEM)],
        input=f"{h}.{p}".encode(),
    )
    assert sig_der[0] == 0x30
    parts = []
    idx = 0
    while idx < len(sig_der) and len(parts) < 2:
        if sig_der[idx] == 0x02:
            ln = sig_der[idx + 1]
            parts.append(sig_der[idx + 2 : idx + 2 + ln])
            idx = idx + 2 + ln
        else:
            idx += 1
    fix = lambda x: x.lstrip(b"\x00").rjust(32, b"\x00")[-32:]
    return f"{h}.{p}.{b64url(fix(parts[0]) + fix(parts[1]))}"


class Asc:
    def __init__(self):
        self.token = make_jwt()
        self.token_at = time.time()

    def refresh(self):
        if time.time() - self.token_at > 900:
            self.token = make_jwt()
            self.token_at = time.time()

    def request(self, method: str, path: str, body=None, params=None):
        self.refresh()
        url = "https://api.appstoreconnect.apple.com" + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = None
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }
        if body is not None:
            data = json.dumps(body).encode()
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as r:
                raw = r.read()
                return r.status, json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            raw = e.read().decode("utf-8", "replace")
            try:
                payload = json.loads(raw)
            except Exception:
                payload = {"raw": raw[:2000]}
            return e.code, payload

    def get(self, path, **params):
        return self.request("GET", path, params=params or None)

    def post(self, path, body):
        return self.request("POST", path, body=body)

    def patch(self, path, body):
        return self.request("PATCH", path, body=body)


def wait_for_build(api: Asc, app_id: str, build_number: str, timeout_s=3600):
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        code, data = api.get(
            "/v1/builds",
            **{
                "filter[app]": app_id,
                "filter[version]": build_number,
                "limit": "10",
                "fields[builds]": "version,processingState,uploadedDate",
            },
        )
        if code != 200:
            print("builds_poll_err", code, json.dumps(data)[:400])
            time.sleep(30)
            continue
        for b in data.get("data", []):
            st = b["attributes"].get("processingState")
            print(f"build {build_number} state={st} id={b['id']}")
            if st == "VALID":
                return b["id"]
            if st == "FAILED":
                raise RuntimeError(f"build {build_number} FAILED")
        time.sleep(45)
    raise TimeoutError(f"build {build_number} not VALID in time")


def ensure_version(api: Asc, app_id: str, version_string: str) -> str:
    code, data = api.get(
        f"/v1/apps/{app_id}/appStoreVersions",
        **{"filter[platform]": "IOS", "filter[versionString]": version_string, "limit": "5"},
    )
    if code == 200 and data.get("data"):
        vid = data["data"][0]["id"]
        state = data["data"][0]["attributes"].get("appStoreState")
        print(f"existing version {version_string} id={vid} state={state}")
        return vid
    body = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {
                "platform": "IOS",
                "versionString": version_string,
                "releaseType": "AFTER_APPROVAL",
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
            },
        }
    }
    code, data = api.post("/v1/appStoreVersions", body)
    if code not in (200, 201):
        raise RuntimeError(f"create version failed {code} {json.dumps(data)[:800]}")
    vid = data["data"]["id"]
    print(f"created version {version_string} id={vid}")
    return vid


def set_release_after_approval(api: Asc, version_id: str):
    body = {
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"releaseType": "AFTER_APPROVAL"},
        }
    }
    code, data = api.patch(f"/v1/appStoreVersions/{version_id}", body)
    print("releaseType AFTER_APPROVAL", code, json.dumps(data.get("errors") or {"ok": True})[:300])


def attach_build(api: Asc, version_id: str, build_id: str):
    body = {
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "relationships": {
                "build": {"data": {"type": "builds", "id": build_id}},
            },
        }
    }
    code, data = api.patch(f"/v1/appStoreVersions/{version_id}", body)
    if code not in (200, 201):
        # fallback relationship endpoint
        code2, data2 = api.patch(
            f"/v1/appStoreVersions/{version_id}/relationships/build",
            {"data": {"type": "builds", "id": build_id}},
        )
        print("attach_build_rel", code2, json.dumps(data2)[:400])
        if code2 not in (200, 204):
            raise RuntimeError(f"attach build failed {code} {json.dumps(data)[:600]}")
    else:
        print("attach_build ok", build_id)


def submit_for_review(api: Asc, version_id: str, app_id: str):
    # Prefer modern reviewSubmissions API
    body = {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
            },
        }
    }
    code, data = api.post("/v1/reviewSubmissions", body)
    if code in (200, 201):
        sub_id = data["data"]["id"]
        print("reviewSubmission created", sub_id)
        item = {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {
                        "data": {"type": "reviewSubmissions", "id": sub_id}
                    },
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": version_id}
                    },
                },
            }
        }
        c2, d2 = api.post("/v1/reviewSubmissionItems", item)
        print("reviewSubmissionItem", c2, json.dumps(d2)[:500])
        # submit
        c3, d3 = api.patch(
            f"/v1/reviewSubmissions/{sub_id}",
            {
                "data": {
                    "type": "reviewSubmissions",
                    "id": sub_id,
                    "attributes": {"submitted": True},
                }
            },
        )
        print("reviewSubmission submit", c3, json.dumps(d3)[:600])
        if c3 in (200, 201):
            return True, "reviewSubmissions"
        return False, d3

    # Legacy fallback
    print("reviewSubmissions unavailable", code, json.dumps(data)[:400])
    body2 = {
        "data": {
            "type": "appStoreVersionSubmissions",
            "relationships": {
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id}
                }
            },
        }
    }
    c4, d4 = api.post("/v1/appStoreVersionSubmissions", body2)
    print("legacy submission", c4, json.dumps(d4)[:600])
    return c4 in (200, 201), d4




def latest_ready_version(api: Asc, app_id: str):
    code, data = api.get(
        f"/v1/apps/{app_id}/appStoreVersions",
        **{"filter[platform]": "IOS", "limit": "20", "fields[appStoreVersions]": "versionString,appStoreState,createdDate"},
    )
    if code != 200:
        raise RuntimeError(f"list versions failed {code} {data}")
    rows = sorted(
        data.get("data") or [],
        key=lambda x: x["attributes"].get("createdDate") or "",
        reverse=True,
    )
    for v in rows:
        st = v["attributes"].get("appStoreState")
        if st in ("READY_FOR_SALE", "WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_DEVELOPER_RELEASE", "PREPARE_FOR_SUBMISSION"):
            return v
    return rows[0] if rows else None


def ensure_review_detail(api: Asc, version_id: str, source_version_id: str, demo_overrides=None):
    """Copy review detail from source version; optionally override demo account fields."""
    code, src = api.get(f"/v1/appStoreVersions/{source_version_id}/appStoreReviewDetail")
    if code != 200 or not src.get("data"):
        print("no source review detail", code, str(src)[:300])
        return False
    attrs = dict(src["data"]["attributes"] or {})
    # Keep only writable-ish fields
    keep = {
        "contactFirstName",
        "contactLastName",
        "contactPhone",
        "contactEmail",
        "demoAccountName",
        "demoAccountPassword",
        "demoAccountRequired",
        "notes",
    }
    body_attrs = {k: attrs[k] for k in keep if attrs.get(k) is not None}
    if demo_overrides:
        body_attrs.update({k: v for k, v in demo_overrides.items() if v})
        body_attrs["demoAccountRequired"] = True
    # Check existing
    code2, cur = api.get(f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail")
    if code2 == 200 and cur.get("data"):
        rid = cur["data"]["id"]
        patch = {
            "data": {
                "type": "appStoreReviewDetails",
                "id": rid,
                "attributes": body_attrs,
            }
        }
        c3, d3 = api.patch(f"/v1/appStoreReviewDetails/{rid}", patch)
        print("reviewDetail patch", c3, "demo=", body_attrs.get("demoAccountName"), json.dumps(d3.get("errors") or {"ok": True})[:300])
        return c3 in (200, 201)
    create = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": body_attrs,
            "relationships": {
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id}
                }
            },
        }
    }
    c4, d4 = api.post("/v1/appStoreReviewDetails", create)
    print("reviewDetail create", c4, "demo=", body_attrs.get("demoAccountName"), json.dumps(d4.get("errors") or {"ok": True})[:400])
    return c4 in (200, 201)


def ensure_whats_new(api: Asc, version_id: str, source_version_id: str | None):
    """Copy what'sNew text from previous version localizations into the new version."""
    if not source_version_id:
        return
    code, locs = api.get(
        f"/v1/appStoreVersions/{source_version_id}/appStoreVersionLocalizations",
        **{"limit": "50"},
    )
    if code != 200:
        print("source localizations fetch failed", code)
        return
    code2, cur_locs = api.get(
        f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations",
        **{"limit": "50"},
    )
    cur_by_locale = {}
    if code2 == 200:
        for loc in cur_locs.get("data") or []:
            cur_by_locale[loc["attributes"].get("locale")] = loc

    for loc in locs.get("data") or []:
        attrs = loc.get("attributes") or {}
        locale = attrs.get("locale")
        whats = attrs.get("whatsNew")
        if not locale or not whats:
            continue
        existing = cur_by_locale.get(locale)
        if existing:
            rid = existing["id"]
            c3, d3 = api.patch(
                f"/v1/appStoreVersionLocalizations/{rid}",
                {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": rid,
                        "attributes": {"whatsNew": whats},
                    }
                },
            )
            print("whatsNew patch", locale, c3, json.dumps(d3.get("errors") or {"ok": True})[:200])
        else:
            c4, d4 = api.post(
                "/v1/appStoreVersionLocalizations",
                {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "attributes": {
                            "locale": locale,
                            "whatsNew": whats,
                        },
                        "relationships": {
                            "appStoreVersion": {
                                "data": {
                                    "type": "appStoreVersions",
                                    "id": version_id,
                                }
                            }
                        },
                    }
                },
            )
            print("whatsNew create", locale, c4, json.dumps(d4.get("errors") or {"ok": True})[:200])


def set_build_encryption_false(api: Asc, build_id: str):
    """Declare that the build does not use non-exempt encryption."""
    body = {
        "data": {
            "type": "builds",
            "id": build_id,
            "attributes": {"usesNonExemptEncryption": False},
        }
    }
    code, data = api.patch(f"/v1/builds/{build_id}", body)
    print(
        "usesNonExemptEncryption=false",
        code,
        json.dumps(data.get("errors") or {"ok": True})[:400],
    )
    return code in (200, 201)


def process_one(api: Asc, key: str):
    cfg = APPS[key]
    print(f"\n===== {key.upper()} =====")
    build_id = wait_for_build(api, cfg["id"], cfg["build"])
    set_build_encryption_false(api, build_id)
    source = latest_ready_version(api, cfg["id"])
    source_id = source["id"] if source else None
    print("source_version", source["attributes"].get("versionString") if source else None, source_id)
    version_id = ensure_version(api, cfg["id"], cfg["version"])
    set_release_after_approval(api, version_id)
    attach_build(api, version_id, build_id)
    ensure_whats_new(api, version_id, source_id)
    demo_overrides = None
    if key == "customer":
        # Prefer dedicated QA customer account from env (never print password)
        import os
        email = os.environ.get("CUSTOMER_QA_EMAIL", "").strip()
        password = os.environ.get("CUSTOMER_QA_PASSWORD", "").strip()
        if email and password and email.lower() != "info@touri-taxi.com":
            demo_overrides = {"demoAccountName": email, "demoAccountPassword": password}
        elif email and password:
            # still customer QA even if named differently
            demo_overrides = {"demoAccountName": email, "demoAccountPassword": password}
    elif key == "driver":
        # NEVER use info@ for Driver — preserve ASC dedicated demo (engosama@...) via copy
        demo_overrides = None
    if source_id:
        ensure_review_detail(api, version_id, source_id, demo_overrides=demo_overrides)
    ok, detail = submit_for_review(api, version_id, cfg["id"])
    # verify release type
    code, ver = api.get(f"/v1/appStoreVersions/{version_id}", **{"fields[appStoreVersions]": "versionString,appStoreState,releaseType"})
    rel = (ver.get("data") or {}).get("attributes") or {}
    print("version_state", rel)
    return {
        "ok": ok,
        "build_id": build_id,
        "version_id": version_id,
        "releaseType": rel.get("releaseType"),
        "appStoreState": rel.get("appStoreState"),
        "detail": detail if isinstance(detail, str) else json.dumps(detail)[:500],
    }


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "both"
    api = Asc()
    results = {}
    targets = ["customer", "driver"] if which == "both" else [which]
    for t in targets:
        try:
            results[t] = process_one(api, t)
        except Exception as e:
            results[t] = {"ok": False, "error": str(e)}
            print("ERROR", t, e)
    out = pathlib.Path("/tmp/asc_submit_result.json")
    out.write_text(json.dumps(results, indent=2))
    print(out.read_text())
    if not all(r.get("ok") for r in results.values()):
        sys.exit(2)


if __name__ == "__main__":
    main()
