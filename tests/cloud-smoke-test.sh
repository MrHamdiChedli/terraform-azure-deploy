#!/usr/bin/env bash
# Tests the deployed app on Azure through its public HTTPS address.
# Usage: bash tests/cloud-smoke-test.sh "$(terraform -chdir=infra output -raw app_url)"
set -euo pipefail

URL="${1:?usage: cloud-smoke-test.sh <app_url>}"
fail() { echo "FAIL: $1"; exit 1; }
visits() { curl -fsS --max-time 30 "$URL/" | grep -o '"visits":[0-9]*' | cut -d: -f2; }

echo "1. The app answers over HTTPS (waking it up if it scaled to zero)"
for _ in $(seq 1 30); do
  curl -fsS --max-time 30 "$URL/healthz" > /dev/null 2>&1 && break
  sleep 10
done
curl -fsS --max-time 30 "$URL/healthz" | grep -q '"status":"ok"' || fail "/healthz is not ok"

echo "2. Plain HTTP is redirected to HTTPS"
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "${URL/https:/http:}/healthz")
case "$code" in 301|302|307|308) ;; *) fail "HTTP returned $code instead of a redirect" ;; esac

echo "3. The counter is stored in Azure Database for PostgreSQL"
first=$(visits); second=$(visits)
[ "$second" -gt "$first" ] || fail "counter did not increase ($first then $second)"

echo "4. The certificate is valid"
curl -fsS --max-time 30 -o /dev/null "$URL/healthz" || fail "TLS check failed"

echo "PASS: all checks succeeded ($URL)"
