#!/usr/bin/env python3
"""Create App Store versions, attach builds, submit for review (AFTER_APPROVAL)."""
from __future__ import annotations

import json
import pathlib
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

KEY_ID = "Q649FRVDBW"
ISSUER = "33620f9e-4268-4130-a32b-d1ee48bddc41"
KEY_PATH = pathlib.Path.home() / ".appstoreconnect/private_keys/AuthKey_Q649FRVDBW.p8"

APPS = {
    "customer": {
        "app_id": "6754410562",
        "version": "9.1.33",
        "build": "52",
    },
    "driver": {
        "app_id": "6754537170",
        "version": "11.1.15",
        "build": "44",
    },
}


def token() -> str:
    key = KEY_PATH.read_text()
    t = jwt.encode(
        {
            "iss": ISSUER,
            "iat": int(time.time()),
            "exp": int(time.time()) + 1200,
            "aud": "appstoreconnect-v1",
        },
        key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )
    return t.decode() if isinstance(t, bytes) else t


def api(method: str, path: str, body: dict | None = None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token()}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def find_build(app_id: str, version: str) -> str | None:
    q = urllib.parse.urlencode(
        {
            "filter[app]": app_id,
            "filter[version]": version,
            "sort": "-uploadedDate",
            "limit": "10",
        }
    )
    st, data = api("GET", f"/v1/builds?{q}")
    if st != 200 or not isinstance(data, dict):
        print("find_build failed", st, str(data)[:300])
        return None
    for b in data.get("data", []):
        attrs = b.get("attributes") or {}
        if attrs.get("processingState") == "VALID":
            return b["id"]
        print("  build candidate", attrs.get("version"), attrs.get("processingState"))
    return None


def wait_build(app_id: str, version: str, timeout_s: int = 3600) -> str:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        bid = find_build(app_id, version)
        if bid:
            print("VALID build", version, bid)
            return bid
        print(f"waiting for build {version} ...")
        time.sleep(45)
    raise SystemExit(f"timeout waiting for build {version}")


def ensure_version(app_id: str, version_string: str) -> str:
    st, data = api("GET", f"/v1/apps/{app_id}/appStoreVersions?limit=10")
    if st == 200 and isinstance(data, dict):
        for v in data.get("data", []):
            a = v.get("attributes") or {}
            if a.get("versionString") == version_string and a.get("platform") == "IOS":
                state = a.get("appStoreState")
                print("existing version", version_string, state, v["id"])
                if state in {
                    "PREPARE_FOR_SUBMISSION",
                    "DEVELOPER_REJECTED",
                    "REJECTED",
                    "METADATA_REJECTED",
                    "INVALID_BINARY",
                }:
                    return v["id"]
                if state == "READY_FOR_SALE":
                    break
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
    st, data = api("POST", "/v1/appStoreVersions", body)
    print("create version", st, str(data)[:400])
    if st not in (200, 201) or not isinstance(data, dict):
        raise SystemExit(f"create version failed: {st}")
    return data["data"]["id"]


def set_release_type(version_id: str) -> None:
    body = {
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "attributes": {"releaseType": "AFTER_APPROVAL"},
        }
    }
    st, data = api("PATCH", f"/v1/appStoreVersions/{version_id}", body)
    print("releaseType", st, str(data)[:200] if not isinstance(data, dict) else data.get("data", {}).get("attributes", {}).get("releaseType"))


def attach_build(version_id: str, build_id: str) -> None:
    body = {
        "data": {
            "type": "appStoreVersions",
            "id": version_id,
            "relationships": {
                "build": {"data": {"type": "builds", "id": build_id}},
            },
        }
    }
    st, data = api("PATCH", f"/v1/appStoreVersions/{version_id}", body)
    print("attach build", st, str(data)[:300] if st >= 400 else "ok")


def create_review_submission(app_id: str) -> str:
    body = {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
            },
        }
    }
    st, data = api("POST", "/v1/reviewSubmissions", body)
    print("create reviewSubmission", st, str(data)[:400])
    if st not in (200, 201) or not isinstance(data, dict):
        # Maybe one already exists READY
        st2, data2 = api(
            "GET",
            f"/v1/apps/{app_id}/reviewSubmissions?filter[platform]=IOS&limit=5",
        )
        if isinstance(data2, dict):
            for item in data2.get("data", []):
                state = (item.get("attributes") or {}).get("state")
                if state in {"READY_FOR_REVIEW", "UNRESOLVED_ISSUES"}:
                    print("reuse reviewSubmission", item["id"], state)
                    return item["id"]
        raise SystemExit(f"create reviewSubmission failed: {st}")
    return data["data"]["id"]


def add_version_item(submission_id: str, version_id: str) -> None:
    body = {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {
                    "data": {"type": "reviewSubmissions", "id": submission_id}
                },
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id}
                },
            },
        }
    }
    st, data = api("POST", "/v1/reviewSubmissionItems", body)
    print("add item", st, str(data)[:400] if st >= 400 else "ok")


def submit(submission_id: str) -> None:
    body = {
        "data": {
            "type": "reviewSubmissions",
            "id": submission_id,
            "attributes": {"submitted": True},
        }
    }
    st, data = api("PATCH", f"/v1/reviewSubmissions/{submission_id}", body)
    print("submit", st, str(data)[:500] if st >= 400 else (data.get("data", {}).get("attributes") if isinstance(data, dict) else data))


def process_one(label: str, cfg: dict) -> None:
    print("===", label, cfg)
    build_id = wait_build(cfg["app_id"], cfg["build"])
    version_id = ensure_version(cfg["app_id"], cfg["version"])
    set_release_type(version_id)
    attach_build(version_id, build_id)
    time.sleep(2)
    submission_id = create_review_submission(cfg["app_id"])
    add_version_item(submission_id, version_id)
    time.sleep(2)
    submit(submission_id)
    st, data = api("GET", f"/v1/appStoreVersions/{version_id}")
    if isinstance(data, dict):
        print("FINAL", label, data.get("data", {}).get("attributes"))


def main() -> None:
    labels = sys.argv[1:] or list(APPS.keys())
    for label in labels:
        process_one(label, APPS[label])


if __name__ == "__main__":
    main()
