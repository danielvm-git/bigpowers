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
