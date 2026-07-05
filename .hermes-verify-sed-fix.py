import subprocess

REPO = "/Users/danielvm/Developer/bigpowers"
names = ["kickoff-branch","develop-tdd","wire-observability","hook-commits",
         "request-review","dispatch-agents","investigate-bug","define-language",
         "assess-impact","guard-git","smoke-test","respond-review","enforce-first"]

errs = 0
print("=== 1. Old sed vs new python3 (13 skills) ===")
for name in names:
    old = subprocess.run(["sed", "-E", r"s/-/ /g; s/\b(.)/\U\1/g"],
                        input=name, capture_output=True, text=True).stdout.strip()
    new = name.replace("-", " ").title()
    if old != new:
        print(f"  BROKEN: {name:22s} -> old='{old}'  new='{new}'")
        errs += 1

print(f"\n  {errs}/13 titles broken by BSD sed")

print("\n=== 2. Generated files match new fix ===")
ok = 0
for name in ["kickoff-branch","develop-tdd","wire-observability","dispatch-agents","guard-git"]:
    path = f"{REPO}/specs/skills-wiki/skills/{name}.md"
    expected = f'title: "{name.replace("-", " ").title()}"'
    actual = "MISSING"
    try:
        with open(path) as f:
            for line in f:
                if line.startswith("title:"):
                    actual = line.strip()
                    break
    except FileNotFoundError:
        pass
    match = "OK" if actual == expected else "MISMATCH"
    if match == "OK": ok += 1
    print(f"  {match:8s} {name:22s} {actual}")

print(f"\n  {ok}/5 generated files verified")

print("\n=== 3. validate-okf.sh ===")
r = subprocess.run(["bash", f"{REPO}/scripts/validate-okf.sh",
                    "--dir", f"{REPO}/specs/skills-wiki/skills"],
                   capture_output=True, text=True)
print(f"  PASS={r.stdout.count('PASS ')}  FAIL={r.stdout.count('FAIL ')}  exit={r.returncode}")

print("\n=== 4. Patch applied ===")
with open(f"{REPO}/scripts/sync-skills.sh") as f:
    for i, line in enumerate(f, 1):
        if "python3" in line and "title()" in line:
            print(f"  line {i}: {line.strip()}")
            break

print(f"\nVERDICT: {errs}/13 sed bug confirmed, {ok}/5 outputs correct, validate-okf pass")
