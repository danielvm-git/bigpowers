# Security Threats: STRIDE & Supply-Chain Defense

**Purpose:** Document security threats (STRIDE model) and supply-chain attack mitigations (slopcheck validation).

---

## STRIDE Model

| Threat | Example | Mitigation |
|--------|---------|-----------|
| **Spoofing** (Identity) | Attacker impersonates user | Authentication (OAuth, MFA) |
| **Tampering** (Data) | Attacker modifies data in transit | TLS encryption, code signing |
| **Repudiation** (Denial) | User denies action | Audit logs, non-repudiation |
| **Information Disclosure** | Attacker reads secrets | Encryption, access controls |
| **Denial of Service** | Attacker crashes service | Rate limiting, circuit breakers |
| **Elevation of Privilege** | Attacker gains admin access | RBAC, least privilege |

---

## Supply-Chain Security in Bigpowers

**Threat:** Hallucinated packages, typosquatters, malicious post-install hooks

**Examples:**
- `colors` (2021) — Protest: deliberately logged ANSI art in output
- `node-ipc` (2022) — Malicious post-install hook wiped node_modules
- `@babel/core` vs `@babel-core` — Typosquatter with 100K+ installs

**Bigpowers Mitigation:** slopcheck integration in plan-work

---

## Slopcheck Verdicts

### [OK] — Safe, Recommended

```bash
slopcheck install lodash --json
# Output: {"package": "lodash", "verdict": "OK", "reason": "widely-used, no known issues"}
```

**Meaning:** Package is known good, widely-trusted, no red flags  
**Action:** Include in recommendations [OK] lodash v4.17.21

### [SUS] — Suspicious, Requires Human Review

```bash
slopcheck install colors@2.0.0 --json
# Output: {"package": "colors", "verdict": "SUS", "reason": "Typosquatter of colors.js, post-install hook detected"}
```

**Meaning:** Package has warning signs (unusual activity, new maintainer, post-install hooks)  
**Action:** Pause at human-verify checkpoint; require explicit user approval

**Common [SUS] Flags:**
- Post-install hook detected
- Unusual network activity
- Similar name to popular package (typosquatter risk)
- Recently transferred to new maintainer
- High-entropy code (obfuscated/minified production code)

### [SLOP] — Dangerous, Reject

```bash
slopcheck install malware-pkg --json
# Output: {"package": "malware-pkg", "verdict": "SLOP", "reason": "Known malware signature matched"}
```

**Meaning:** Package is known malicious or has clear attacks  
**Action:** Remove from recommendations entirely; emit warning

**Common [SLOP] Flags:**
- Matches known malware signatures
- Keylogger/credential stealer detected
- Explicit security advisory from npm/CISA
- Archive bomb or resource exhaustion

---

## Integration: slopcheck in plan-work

**Workflow:**

```
plan-work creates PLAN.md:

Step 1: Install dependency @openai/api@4.28.0
Step 2: Configure API client
Step 3: Implement request handler

During planning, before recommending packages:
┌─ Call slopcheck for each package
│  ├─ @openai/api → [OK]
│  └─ colors → [SUS]
│
├─ Tag packages in PLAN.md:
│  ├─ [OK] @openai/api v4.28.0
│  └─ [SUS] colors v2.0.0 — **requires human verification**
│
└─ If any [SLOP]:
   └─ Remove from recommendations + emit warning
   └─ Emit human-verify checkpoint for [SUS] packages
```

---

## Verification: Slopcheck Verdicts

```bash
# Step 1: Every package in PLAN.md has a verdict tag
verify: grep -q "\[OK\]\|\[SUS\]\|\[SLOP\]" specs/PLAN.md && echo "✅ All packages tagged"

# Step 2: No [SLOP] packages remain
verify: ! grep -q "\[SLOP\]" specs/PLAN.md && echo "✅ No dangerous packages"

# Step 3: All [SUS] packages were approved by user
verify: grep -q "\[SUS\]" specs/PLAN.md && \
        grep "human-verify\|approved by user" specs/PLAN.md | grep -q "[SUS]" && \
        echo "✅ [SUS] packages approved"
```

---

## Defense Checklist (audit-code)

- [ ] No hallucinated package names (verified via slopcheck)
- [ ] All packages are [OK] or [SUS] with user approval (no [SLOP])
- [ ] Post-install hooks reviewed ([SUS] flag triggers review)
- [ ] No typosquatters (slopcheck checks package name similarity)
- [ ] Dependency pinning: versions locked (not ^, ~, *, latest)
- [ ] No supply-chain escalation: devDependencies sandboxed from production

---

## Common Vulnerabilities (Beyond Packages)

### Injection Attacks (SQL, Command, Template)

**Risk:** User input interpreted as code  
**Mitigation:** Parameterized queries, shell escaping, template auto-escaping  
**Check:** grep -r "query(" src/ | grep -v "?" (unparameterized queries)

### Authentication/Authorization

**Risk:** Weak session management, missing RBAC  
**Mitigation:** Strong session tokens, role-based access, minimal scope  
**Check:** grep -r "password\|token" src/ | wc -l (audit all auth code)

### Cryptography

**Risk:** Weak algorithms, hardcoded keys, improper salting  
**Mitigation:** Use bcrypt/Argon2, store keys in env, unique salts  
**Check:** grep -r "sha1\|md5\|hardcoded.*key" src/ (weak crypto patterns)

### Information Disclosure

**Risk:** Secrets in logs, stack traces, comments  
**Mitigation:** Log filtering, error message generalization  
**Check:** grep -r "TODO.*secret\|password\|API_KEY" src/ | grep -v test

---

## Security Audit Checklist

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All auth flows use strong algorithms (OAuth, bcrypt, not MD5)
- [ ] No SQL injection vulnerabilities (parameterized queries)
- [ ] No command injection (shell escaping via execFile, not exec)
- [ ] HTTPS enforced in production
- [ ] Error messages don't leak sensitive info (stack traces hidden)
- [ ] Dependency audit passes: npm audit (no critical vulnerabilities)
- [ ] Rate limiting prevents brute force
- [ ] CORS properly configured (not wildcard)
- [ ] CSRF tokens on state-changing operations

---

## See Also

- gates.md — How security gates enforce validations
- model-profiles.md — Which model for security reviews?
- plan-work (SKILL.md) — slopcheck integration workflow
- verify: npm audit --audit-level=moderate
