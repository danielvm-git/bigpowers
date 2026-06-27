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
