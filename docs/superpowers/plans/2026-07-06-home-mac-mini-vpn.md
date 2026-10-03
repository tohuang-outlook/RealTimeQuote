# Home Mac mini VPN Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy a self-hosted US exit path on the user's home `Mac mini` with one primary censorship-resistant protocol and one fallback protocol, reachable at `vpn.crystalhuangdance.org`.

**Architecture:** Use the US home `Mac mini` as the single access node behind the home router's public IP. Point `vpn.crystalhuangdance.org` at that public IP, forward only the required ports to the `Mac mini`, install a primary `Amnezia`-style stack for restrictive-network access, and prepare `Outline` as a fallback path with separate client profiles. Validate externally before travel and keep a small recovery checklist.

**Tech Stack:** macOS, home router port forwarding, DNS `A` record or DDNS, Amnezia-capable stack, Outline Server, client profiles on macOS/iPhone/iPad

---

## File Structure

- Modify: `docs/superpowers/specs/2026-07-06-home-mac-mini-vpn-design.md`
  Only if the deployment reveals a design mismatch that must be reflected back into the spec.
- Create: `docs/superpowers/plans/2026-07-06-home-mac-mini-vpn.md`
  The step-by-step implementation plan for deployment and validation.
- Create: `docs/vpn/home-mac-mini-runbook.md`
  The operator runbook with the final chosen ports, router settings, DNS workflow, client import links, and recovery checklist.
- Create: `docs/vpn/client-checklist.md`
  A short travel checklist for the user's actual devices.
- Create: `docs/vpn/ddns/update-vpn-dns.sh`
  Optional helper script to update `vpn.crystalhuangdance.org` if the home public IP is dynamic and the DNS provider supports API updates.
- Create: `docs/vpn/ddns/README.md`
  Documents how to configure and test the DNS updater if it is needed.

### Task 1: Capture The Home Network Baseline

**Files:**
- Create: `docs/vpn/home-mac-mini-runbook.md`
- Test: home router admin page, `Mac mini` terminal, one external network such as phone hotspot

- [ ] **Step 1: Record the machine and network facts in the runbook**

Add this section to `docs/vpn/home-mac-mini-runbook.md` and fill in the blanks during deployment:

```md
# Home Mac mini VPN Runbook

## Environment

- Mac mini local hostname: `________________`
- Mac mini LAN IP target: `________________`
- Router admin URL: `________________`
- ISP/public IP at time of setup: `________________`
- Domain: `crystalhuangdance.org`
- VPN hostname: `vpn.crystalhuangdance.org`
- DNS provider: `________________`
- Public IP type: `static` or `dynamic`
```

- [ ] **Step 2: Verify the Mac mini gets a stable LAN IP**

Run on the `Mac mini`:

```bash
ipconfig getifaddr en0
networksetup -getcomputername
scutil --get LocalHostName
```

Expected: the machine shows a reachable LAN IP and stable host identity. Record the final reserved LAN IP in the runbook after setting a DHCP reservation on the router.

- [ ] **Step 3: Verify the public IP from inside the home network**

Run on the `Mac mini`:

```bash
curl https://ifconfig.me
```

Expected: a public IPv4 address is returned. Record it in the runbook and compare it to the router's WAN IP page to confirm they match.

- [ ] **Step 4: Decide whether DDNS is required**

Use this decision rule in the runbook:

```md
## DNS Mode

- If router WAN IP stays fixed across reboots and the ISP confirms static addressing, use a plain `A` record.
- If the public IP can change, enable a DDNS workflow and document the updater.
```

- [ ] **Step 5: Commit the baseline runbook**

```bash
git add docs/vpn/home-mac-mini-runbook.md
git commit -m "docs: add home vpn runbook baseline"
```

### Task 2: Point The Domain And Expose Only The Required Network Paths

**Files:**
- Modify: `docs/vpn/home-mac-mini-runbook.md`
- Create: `docs/vpn/ddns/README.md`
- Create: `docs/vpn/ddns/update-vpn-dns.sh`
- Test: DNS resolution from the `Mac mini` and from an external network

- [ ] **Step 1: Create the DNS record for the VPN hostname**

Create or update:

```text
Type: A
Name: vpn
Value: <current public IP>
TTL: 300
```

Expected: `vpn.crystalhuangdance.org` resolves to the current public IP within a few minutes.

- [ ] **Step 2: Verify DNS resolution locally**

Run on the `Mac mini`:

```bash
dig +short vpn.crystalhuangdance.org
nslookup vpn.crystalhuangdance.org
```

Expected: both commands return the same public IP recorded in the runbook.

- [ ] **Step 3: Document router forwarding placeholders before protocol install**

Add this section to `docs/vpn/home-mac-mini-runbook.md`:

```md
## Port Forwarding

- Mac mini reserved LAN IP: `________________`
- Primary protocol port(s): `________________`
- Fallback protocol port(s): `________________`
- No DMZ enabled: `yes`
- Only explicit forwarding rules enabled: `yes`
```

- [ ] **Step 4: If the public IP is dynamic, add a DNS update helper**

Create `docs/vpn/ddns/update-vpn-dns.sh`:

```bash
#!/bin/zsh
set -euo pipefail

if [[ -z "${DNS_API_TOKEN:-}" ]]; then
  echo "DNS_API_TOKEN is required" >&2
  exit 1
fi

if [[ -z "${DNS_ZONE_ID:-}" || -z "${DNS_RECORD_ID:-}" ]]; then
  echo "DNS_ZONE_ID and DNS_RECORD_ID are required" >&2
  exit 1
fi

CURRENT_IP="$(curl -fsSL https://ifconfig.me)"

curl -fsSL -X PUT "https://api.cloudflare.com/client/v4/zones/${DNS_ZONE_ID}/dns_records/${DNS_RECORD_ID}" \
  -H "Authorization: Bearer ${DNS_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"vpn.crystalhuangdance.org\",\"content\":\"${CURRENT_IP}\",\"ttl\":300,\"proxied\":false}"

echo "Updated vpn.crystalhuangdance.org -> ${CURRENT_IP}"
```

This example assumes Cloudflare. If the DNS provider is different, replace the endpoint and payload in this step before use.

- [ ] **Step 5: Document the DDNS helper and verify the script syntax**

Create `docs/vpn/ddns/README.md`:

```md
# VPN DNS Updater

This helper updates `vpn.crystalhuangdance.org` to the current home public IP.

## Environment

- `DNS_API_TOKEN`
- `DNS_ZONE_ID`
- `DNS_RECORD_ID`

## Dry Validation

Run:

```bash
zsh -n docs/vpn/ddns/update-vpn-dns.sh
```
```

Run:

```bash
zsh -n docs/vpn/ddns/update-vpn-dns.sh
```

Expected: no output and exit code `0`.

- [ ] **Step 6: Commit the DNS and exposure scaffolding**

```bash
git add docs/vpn/home-mac-mini-runbook.md docs/vpn/ddns/README.md docs/vpn/ddns/update-vpn-dns.sh
git commit -m "docs: add vpn dns and exposure setup"
```

### Task 3: Install The Primary Access Stack On The Mac mini

**Files:**
- Modify: `docs/vpn/home-mac-mini-runbook.md`
- Test: primary service admin UI or CLI on the `Mac mini`, one external client

- [ ] **Step 1: Prepare the Mac mini for always-on service**

Run on the `Mac mini`:

```bash
sudo systemsetup -setcomputersleep Never
sudo systemsetup -setdisplaysleep 30
sudo pmset -a sleep 0 disksleep 0 displaysleep 30
sudo pmset -a tcpkeepalive 1 powernap 1
```

Expected: the machine does not enter sleep while keeping the display timeout reasonable.

- [ ] **Step 2: Record the operating posture in the runbook**

Add this section to `docs/vpn/home-mac-mini-runbook.md`:

```md
## Mac mini Operating Posture

- Sleep disabled: `yes`
- Reboot after power loss enabled: `verify in system/firmware settings`
- Auto-login disabled unless operationally required: `________________`
- Remote admin path available: `________________`
```

- [ ] **Step 3: Install the primary stack using the chosen Amnezia-compatible workflow**

Document the exact install command or installer artifact actually used in the runbook under:

```md
## Primary Stack

- Product: `________________`
- Version: `________________`
- Install method: `________________`
- Primary listen port(s): `________________`
- Client import method: `________________`
```

Expected: the primary service is installed, starts successfully, and produces at least one client profile.

- [ ] **Step 4: Add the router forwarding rules for the primary stack**

Create explicit forwarding from the router WAN interface to the `Mac mini` LAN IP for only the port(s) chosen in Step 3.

Document the final values in the runbook:

```md
- Primary forwarding enabled: `yes`
- Router rule names: `________________`
```

- [ ] **Step 5: Validate that the primary endpoint is reachable from outside the home LAN**

From a different network, such as a phone hotspot or another offsite device, attempt the real client connection using the generated primary profile.

Expected:

- the client connects
- the traffic exits through a US IP
- blocked social media and YouTube open from that external test path

- [ ] **Step 6: Commit the primary-stack runbook details**

```bash
git add docs/vpn/home-mac-mini-runbook.md
git commit -m "docs: add primary home vpn deployment details"
```

### Task 4: Install And Prepare The Fallback Access Stack

**Files:**
- Modify: `docs/vpn/home-mac-mini-runbook.md`
- Create: `docs/vpn/client-checklist.md`
- Test: fallback client connection from an external network

- [ ] **Step 1: Install Outline or the chosen fallback stack on the Mac mini**

Record the exact deployment method in the runbook:

```md
## Fallback Stack

- Product: `Outline` or `________________`
- Version: `________________`
- Install method: `________________`
- Listen port(s): `________________`
- Client import method: `________________`
```

Expected: the fallback service is installed and can generate a separate client credential or access key.

- [ ] **Step 2: Add router forwarding only for the fallback ports**

Update the runbook section:

```md
- Fallback forwarding enabled: `yes`
- Router rule names: `________________`
```

Expected: the fallback listens on a different port set from the primary path unless the chosen product requires another layout.

- [ ] **Step 3: Prepare a device checklist for travel**

Create `docs/vpn/client-checklist.md`:

```md
# VPN Client Checklist

## Devices

- iPhone: primary installed, fallback installed
- MacBook: primary installed, fallback installed
- iPad: primary installed, fallback installed

## Labels

- `US Home Primary`
- `US Home Fallback`

## Before Travel

- verify both profiles import cleanly
- verify both profiles connect from a non-home network
- store recovery notes offline
```

- [ ] **Step 4: Validate the fallback path from an external network**

Using a non-home network, import the fallback profile and connect through it.

Expected:

- the fallback client connects successfully
- public IP geolocates to the US
- the target media sites load

- [ ] **Step 5: Commit the fallback and client preparation docs**

```bash
git add docs/vpn/home-mac-mini-runbook.md docs/vpn/client-checklist.md
git commit -m "docs: add fallback vpn and client checklist"
```

### Task 5: Add A Travel-Ready Validation And Recovery Routine

**Files:**
- Modify: `docs/vpn/home-mac-mini-runbook.md`
- Modify: `docs/vpn/client-checklist.md`
- Test: full end-to-end dry run before departure

- [ ] **Step 1: Add a pre-travel validation checklist to the runbook**

Append this section to `docs/vpn/home-mac-mini-runbook.md`:

```md
## Pre-Travel Validation

1. Confirm `vpn.crystalhuangdance.org` resolves to the current public IP.
2. Confirm router forwarding rules still exist.
3. Confirm the `Mac mini` is awake and reachable.
4. Test the primary profile from a non-home network.
5. Test the fallback profile from a non-home network.
6. Confirm the exit IP is in the US.
7. Open YouTube and one target social media site through each profile.
```

- [ ] **Step 2: Add a failure-handling table**

Append this section to `docs/vpn/home-mac-mini-runbook.md`:

```md
## Failure Handling

- Primary profile does not connect:
  Switch to fallback.
- Both profiles fail and DNS is stale:
  Update the `A` record or run the DDNS helper.
- Both profiles fail but DNS is correct:
  Check home power, router forwarding, and service status on the `Mac mini`.
- Video is slow but connection succeeds:
  Check home upload bandwidth and current household network load.
```

- [ ] **Step 3: Perform one full dry run before declaring the setup ready**

Run from an external network:

```bash
dig +short vpn.crystalhuangdance.org
curl https://ifconfig.me
```

Then connect each client profile and verify the post-connect public IP in a browser or terminal.

Expected:

- DNS resolves correctly
- primary profile works or fails over cleanly
- fallback profile works
- both routes present a US exit IP

- [ ] **Step 4: Update the client checklist to include departure and return workflows**

Append to `docs/vpn/client-checklist.md`:

```md
## During Travel

- try `US Home Primary` first
- switch to `US Home Fallback` if the first path stalls or is blocked
- avoid changing server settings from the road unless necessary

## After Return

- note which path worked
- rotate credentials if compromise is suspected
- update the runbook before the next trip
```

- [ ] **Step 5: Commit the validation and recovery routine**

```bash
git add docs/vpn/home-mac-mini-runbook.md docs/vpn/client-checklist.md
git commit -m "docs: add home vpn validation and recovery checklist"
```

## Self-Review

### Spec coverage

- The single-host `Mac mini` architecture is covered in Tasks 1 through 5.
- DNS and optional DDNS are covered in Task 2.
- Primary and fallback protocol preparation are covered in Tasks 3 and 4.
- Client readiness and travel workflows are covered in Tasks 4 and 5.
- Failure handling and pre-travel validation are covered in Task 5.

No spec requirement appears uncovered.

### Placeholder scan

- Remaining blanks in the runbook are intentional operator-filled values gathered during deployment, not implementation placeholders in the plan itself.
- The only provider-specific branch is the DDNS helper, and the plan explicitly says to replace the Cloudflare example if another DNS provider is used.

### Type consistency

- The same hostname `vpn.crystalhuangdance.org` is used consistently throughout.
- The same document set is reused consistently: runbook, client checklist, and optional DDNS helper.
- The same terminology is used consistently: `primary`, `fallback`, `Mac mini`, `public IP`, and `external network`.
