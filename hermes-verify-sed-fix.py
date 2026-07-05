import subprocess
names=["kickoff-branch","develop-tdd","wire-observability","hook-commits","request-review","dispatch-agents","investigate-bug","define-language","assess-impact","guard-git","smoke-test","respond-review","enforce-first"]
errs=0
print("=== 1. Old sed vs new python3 ===")
for name in names:
    old=subprocess.run(["sed","-E",r"s/-/ /g; s/\b(.)/\U\1/g"],input=name,capture_output=True,text=True).stdout.strip()
    new=name.replace("-"," ").title()
    if old!=new:
        print(f"  BROKEN: {name:22s} old={old!r:22s} new={new!r}")
        errs+=1
print(f"  {errs}/13 broken")
print("\n=== 2. Generated files ===")
ok=0
for name in ["kickoff-branch","develop-tdd","wire-observability","dispatch-agents","guard-git"]:
    path=f"specs/skills-wiki/skills/{name}.md"
    expected="title: \\"%s\\""%name.replace("-"," ").title()
    actual="MISSING"
    try:
        with open(path) as f:
            for line in f:
                if line.startswith("title:"):actual=line.strip();break
    except:pass
    match="OK" if actual==expected else "MISMATCH"
    if match=="OK":ok+=1
    print(f"  {match:8s} {name}")
print(f"  {ok}/5 ok")
print("\n=== 3. validate-okf ===")
r=subprocess.run(["bash","scripts/validate-okf.sh","--dir","specs/skills-wiki/skills"],capture_output=True,text=True)
print(f"  exit={r.returncode}  pass_lines={r.stdout.count(chr(80)+chr(65)+chr(83)+chr(83))}")
print(f"\nVERDICT: {errs}/13 sed bug, {ok}/5 outputs correct, validate-okf exit={r.returncode}")
