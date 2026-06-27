---
name: security-review
description: "> AI-powered security analysis of code changes — traces data flow, detects injection, auth bypass, secrets exposure, and unsafe deserialization across files. Use when reviewing pending changes, before release-branch, during verify-work Phase 5, during build-epic Step 0 threat modeling, or when the user says \"security review\" or \"scan for vulns\"."
---


# Security Review

> **HARD GATE** — Requires git context (branch with merge-base or diff). Never
> writes files outside `specs/security/`. Findings below confidence 8/10 are
> suppressed. **→ verify:** `git rev-parse HEAD >/dev/null 2>&1 && echo "ok" || echo "BLOCKED"`

## 5-phase scan

| # | Phase | What |
|---|-------|------|
| 1 | **Scope Resolution** | Detect diff via `git diff --merge-base origin/HEAD`; resolve languages/frameworks from dependency files |
| 2 | **Context Research** | Identify existing security patterns, sanitization, auth model in the codebase |
| 3 | **Vulnerability Assessment** | Trace user input → sink; check auth boundaries, crypto, deserialization, path ops |
| 4 | **False-Positive Filtering** | Cross-check each finding against exclusion rules; reject confidence < 8 |
| 5 | **Report Generation** | Output structured markdown: file:line, severity, category, exploit scenario, fix |

## Categories

Covered: SQLi, XSS, SSRF, command injection, auth bypass, unsafe deserialization, path traversal, IDOR, crypto flaws, secrets exposure, template injection, NoSQLi

## Integration points

| Skill | Touchpoint |
|-------|------------|
| `build-epic` | Step 0 — threat-model epic scope → `specs/security/epics/<id>/THREAT_MODEL.md` |
| `plan-work` | `security:` field (none/low/medium/high) on story tasks |
| `plan-release` | +2 WSJF risk boost for HIGH+ risk epics |
| `audit-code` | Checklist: "diff scanned — no unaddressed HIGH findings" |
| `request-review` | Inject threat model categories + false-positive rules into reviewer prompt |
| `investigate-bug` | Security-impact assessment in RCA (NONE→CRITICAL) |
| `validate-fix` | Recurrence hardening check for security bugs |
| `verify-work` | Phase 5 — blocks on HIGH findings ≥ 8 confidence |
| `release-branch` | Hard gate — blocks merge if unresolved HIGH findings |

## Report format

Each finding: **`File:Line` — Severity — Category**
- Description: how the vulnerability manifests
- Exploit scenario: concrete attack path
- Recommendation: fix with code example

## Reference files

- [Vuln categories](REFERENCE-vuln-categories.md) — detection guidance per vuln type
- [False positives](REFERENCE-false-positives.md) — hard exclusions + precedent
- [Confidence rubric](REFERENCE-confidence-rubric.md) — scoring methodology (0–10)

## Verify

```bash
test -d specs/security && echo "OK: specs/security/ exists" || mkdir -p specs/security
grep -q "Merge-base\|merge.base\|git diff" SKILL.md && echo "OK: git context verified"
```

---

# Confidence Scoring Rubric

Every finding that survives Phase 4 false-positive filtering receives a confidence
score from 1 (speculative) to 10 (certain). Only findings ≥ 8 are reported.

## Score 9–10: Certain Exploit Path

**Criteria:**
- Concrete, testable exploit with clear reproduction steps
- No assumptions about uncommon configurations
- No chain of multiple unlikely conditions
- Attacker has full control over the input vector

**Examples:**
- User-supplied SQL in a `SELECT` statement with no parameterization
- `os.system(f"rm {user_path}")` where user controls the path
- Pickle deserialization of user-supplied data without any wrapping

**Severity:** HIGH

## Score 8: Clear Vulnerability Pattern

**Criteria:**
- Well-known vulnerability pattern with standard exploitation method
- Requires specific conditions but conditions are commonly met
- Exploitability is well-documented in OWASP / CVE databases

**Examples:**
- JWT without signature verification in authentication middleware
- SSRF where attacker controls the full URL including host
- Hardcoded AWS secret key in source code

**Severity:** HIGH or MEDIUM

## Score 7: Suspicious Pattern

**Criteria:**
- Unusual code that may indicate a vulnerability
- Requires specific conditions that may not be present
- Alternative secure interpretation is equally likely
- Defense-in-depth concern rather than direct exploit

**Examples:**
- A function accepting user input that passes through multiple layers before reaching a sink (unclear if sanitized)
- Custom encryption implementation (likely weak, but may not process sensitive data)
- Path construction that looks safe but has a subtle bypass

**Severity:** LOW or suppress

## Score < 7: Do Not Report

**Criteria:**
- Theoretical concern without exploit path
- Requires unrealistic attacker capabilities
- Violates one or more hard exclusion rules
- Better handled by separate tooling (dependency scanner, SAST, secret scanner)
- Purely stylistic or best-practice concern without security impact

**Examples:**
- "This function doesn't validate all inputs" without proving the validated input is the attack surface
- "This uses MD5" where the hash is not used for security (e.g., cache key)
- "This function could consume too much memory" (DOS exclusion)

**Action:** Suppress entirely. Do not include in report.

## Severity Mapping

Once confidence ≥ 8 is confirmed, map to severity:

| Severity | Impact | Examples |
|----------|--------|---------|
| **CRITICAL** | Remote compromise, full data breach | RCE, auth bypass with admin escalation, SQLi with data exfiltration |
| **HIGH** | Significant security boundary crossed | SSRF to internal services, hardcoded cloud credentials, insecure deserialization |
| **MEDIUM** | Limited impact or requires conditions | Stored XSS behind auth, IDOR on non-sensitive data, weak but not broken crypto |
| **LOW** | Defense-in-depth, minimal blast radius | Missing security header, verbose error messages in non-production |

## Quality Gate

The confidence rubric double-checks each finding against three lenses:

| Lens | Question |
|------|----------|
| **Exploitability** | Can a real attacker trigger this from a trust boundary? |
| **Actionability** | Would a security engineer accept a fix recommendation for this? |
| **Precedent** | Has this type of finding passed/failed human review before? |

---

# False-Positive Exclusion Rules

Applied during Phase 4 of the scan. Findings matching any hard exclusion are
automatically suppressed. Precedents from prior reviews guide borderline cases.

## Hard Exclusions

Automatically exclude findings matching these patterns:

| # | Rule | Rationale |
|---|------|-----------|
| 1 | **Denial of Service (DOS)** — resource exhaustion, CPU/memory attacks | Handled separately; not actionable in code review |
| 2 | **Secrets on disk** if otherwise secured | Secrets management is a separate concern |
| 3 | **Rate limiting** concerns | Operational, not a code vulnerability |
| 4 | **Memory consumption / CPU exhaustion** | Not actionable in diff review |
| 5 | **Input validation on non-security-critical fields** without proven exploit path | Theoretical, not concrete |
| 6 | **GitHub Actions input sanitization** unless clearly triggerable via untrusted input | Most workflow vulns are not exploitable |
| 7 | **Lack of hardening measures** | Code is not expected to implement all best practices |
| 8 | **Race conditions / timing attacks** that are theoretical | Only report if concretely problematic |
| 9 | **Outdated third-party libraries** | Managed separately by dependency scanners |
| 10 | **Memory safety** in Rust or other memory-safe languages | Impossible by language guarantees |
| 11 | **Unit test files only** | Not production risk |
| 12 | **Log spoofing** | Outputting unsanitized input to logs is not a vuln |
| 13 | **SSRF that only controls path** | Only host/protocol control is exploitable |
| 14 | **User-controlled content in AI system prompts** | Not a security vulnerability |
| 15 | **Regex injection** | Injecting untrusted content into regex is not a vuln |
| 16 | **Regex DOS** | Excluded alongside general DOS |
| 17 | **Documentation files** (.md, .txt) | Insecure docs are not code vulnerabilities |
| 18 | **Lack of audit logs** | Not a vulnerability |

## Precedent Rules

These guide borderline cases based on prior human review decisions:

| # | Precedent | Reasoning |
|---|-----------|-----------|
| 1 | **Logging high-value secrets in plaintext IS a vuln.** Logging URLs is safe. | Secrets in logs = credential exposure; URLs are not secrets |
| 2 | **UUIDs are unguessable** — no validation needed | Cryptographic property of UUID v4/v7 |
| 3 | **Environment variables and CLI flags are trusted values** | Attackers cannot modify these in secure environments |
| 4 | **Resource management issues** (memory leaks, fd leaks) are NOT valid | Operational, not security |
| 5 | **Tabnabbing, XS-Leaks, prototype pollution, open redirects** — do NOT report unless extremely high confidence | Subtle, low-impact, high false-positive rate |
| 6 | **React/Angular XSS** — safe unless `dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`, etc. | Framework auto-escapes |
| 7 | **GitHub Action workflow vulns** — verify concrete attack path before reporting | Most are theoretical |
| 8 | **Client-side JS/TS auth checks** — not a vuln; server is authoritative | Client code is untrusted |
| 9 | **IPython notebook vulns** — only report if concrete untrusted-input trigger | Most are not exploitable |
| 10 | **Logging non-PII data** — not a vuln even if sensitive. Only PII/secrets/passwords. | Intent: operational logging vs credential exposure |
| 11 | **Shell script command injection** — only report if concrete untrusted-input path | Most shell scripts don't process untrusted input |

## Confidence Scoring

Findings that survive exclusions get a confidence score (1–10):

| Range | Meaning | Action |
|-------|---------|--------|
| 9–10 | Certain exploit path, testable | Report as HIGH |
| 8 | Clear vulnerability pattern | Report as HIGH/MEDIUM |
| 7 | Suspicious, needs conditions | Report as LOW or suppress |
| <7 | Too speculative | **Do not report** |

**Hard threshold:** Only report findings with confidence ≥ 8.

## Signal Quality Criteria

For remaining findings, assess:
1. Is there a concrete, exploitable vulnerability with a clear attack path?
2. Does this represent a real security risk (vs theoretical best practice)?
3. Are there specific code locations and reproduction steps?
4. Would this finding be actionable for a security team?

---

# Vulnerability Categories — Detection Guidance

Each category: vulnerable pattern → safe pattern → code example.

## SQL Injection

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | String interpolation in SQL queries: `f"SELECT * FROM users WHERE id = {uid}"` |
| **Safe** | Parameterized queries / ORM: `cursor.execute("SELECT * FROM users WHERE id = %s", (uid,))` |
| **Look for** | f-strings, `+` concatenation, `format()` in query builders; raw SQL in ORM `.raw()` / `.execute()` |
| **False-positive guard** | Not a FP if the input is user-controlled (HTTP param, file, env var, CLI arg). Env vars are trusted (see exclusion rules). |

## Cross-Site Scripting (XSS)

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | `element.innerHTML = userInput`, `dangerouslySetInnerHTML={{__html: userInput}}` |
| **Safe** | `element.textContent = userInput`, React JSX (auto-escaped), template engines with auto-escaping |
| **Look for** | `.innerHTML`, `document.write()`, `dangerouslySetInnerHTML`, `v-html` (Vue), `bypassSecurityTrustHtml` (Angular) |
| **False-positive guard** | React/Angular components without unsafe methods are NOT vulnerable (see exclusion rules). |

## Server-Side Request Forgery (SSRF)

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | User-controlled URL passed to server-side HTTP client: `requests.get(user_url)` |
| **Safe** | URL allowlist validation, internal-network blocking, protocol/host restriction |
| **Look for** | User input → `fetch`, `requests.get`, `axios.get`, `urllib`, `curl`, `http.get`; host control only (path-only is excluded) |

## Command Injection

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | User input in shell commands: `os.system(f"ping {host}")`, `subprocess.run(f"grep {pattern} file", shell=True)` |
| **Safe** | `subprocess.run(["ping", host])` with arguments as list; `shlex.quote()` |
| **Look for** | `shell=True`, `os.system`, `os.popen`, `exec()`, `eval()`, `$()`, backticks |
| **False-positive guard** | Shell scripts without untrusted user input are generally not exploitable. |

## Authentication/Authorization Bypass

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | Missing auth check on protected endpoint; JWT without signature verification; hardcoded admin tokens |
| **Safe** | Consistent auth middleware; JWT with `RS256`/`HS256` verification; role-based access control |
| **Look for** | Routes without auth decorators; `@login_required` / `@require_auth` missing; JWT without `.verify()`; client-side auth checks only |

## Unsafe Deserialization

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | `pickle.load(user_data)`, `yaml.load(user_input)`, `JSON.parse()` on untrusted tokens, `eval(input())` |
| **Safe** | `yaml.safe_load()`, `json.loads()` (safe for JSON), `pickle.load(weights_only=True)` (PyTorch), schema validation |
| **Look for** | `pickle.load`, `yaml.load` (not safe_load), `torch.load(weights_only=False)`, `eval`, `marshal.load`, `node-serialize` |

## Path Traversal

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | User input in file paths: `open(f"/data/{filename}")`, `path.join(base, user_path)` |
| **Safe** | Path normalization + prefix check: `os.path.realpath(path).startswith(BASE_DIR)`; allowlist of valid filenames |
| **Look for** | `open()`, `read_file()`, `os.path.join` with user input; `../` traversal without normalization |

## Insecure Direct Object Reference (IDOR)

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | API endpoint uses user-supplied ID without ownership check: `GET /api/order/{order_id}` — returns any user's order |
| **Safe** | Ownership verification: verify `order.user_id == current_user.id` before returning data |
| **Look for** | CRUD endpoints that accept IDs without authorization; horizontal/vertical privilege checks missing |

## Weak Cryptography

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | MD5/SHA1 for passwords; ECB mode; hardcoded keys; `random` module (not `secrets`); short key lengths |
| **Safe** | `bcrypt`/`argon2` for passwords; AES-GCM; `secrets` module; RSA 2048+; proper IV generation |
| **Look for** | `md5`, `sha1`, `DES`, `ECB`, `PKCS1_v1_5`, `random` for crypto, hardcoded `key=`, `Crypto.Cipher` without AEAD |

## Secrets Exposure

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | Hardcoded API keys, passwords, tokens in source code; secrets in logs; secrets in client-side code |
| **Safe** | Environment variables; secret manager (AWS Secrets Manager, HashiCorp Vault); `.env` excluded from VCS |
| **Look for** | `API_KEY=`, `password=`, `secret=`, `token=` in code; AWS keys, GitHub tokens, Stripe keys, JWTs in source |
| **False-positive guard** | Secrets stored on disk but otherwise secured ARE excluded. Logging high-value secrets IS a vuln. Logging URLs is safe. |

## Template Injection (SSTI)

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | User input in template rendering: `Template(user_input).render()`, `render_template_string(user_input)` |
| **Safe** | Static templates; input passed as context variable, not template string |
| **Look for** | `render_template_string`, `Template()()` with user string; `eval` in template context; `${user_input}` in JS template literals on server |

## NoSQL Injection

| Aspect | Detail |
|--------|--------|
| **Vulnerable** | User input in MongoDB queries: `db.users.find({username: user_input})` where input is `{"$gt": ""}` |
| **Safe** | Schema validation; type checking on query params; ORM sanitization |
| **Look for** | MongoDB `$where`, `$gt`, `$regex` from user input; raw mongo queries without type coercion |
