import csv, statistics as st

rows = list(csv.DictReader(open("results/agent-bench_all-agents_cloud_2026-06-07.csv")))
TASKS = ["task1","task2","task3","task4","task5"]
TLAB = {"task1":"T1 write","task2":"T2 chain","task3":"T3 count","task4":"T4 append","task5":"T5 mem"}
agents = []
for r in rows:
    if r["agent"] not in agents:
        agents.append(r["agent"])

def cell(agent, task):
    rr = [r for r in rows if r["agent"]==agent and r["task"]==task]
    if not rr: return None
    secs=[float(r["seconds"]) for r in rr]; mem=[float(r["peak_mem_mb"]) for r in rr]
    npass=sum(1 for r in rr if r["success"]=="pass")
    return dict(n=len(rr), npass=npass, med=st.median(secs), mn=min(secs), mx=max(secs), mem=st.median(mem))

for a in agents:
    print(f"=== {a} ===")
    print("{:<9}{:>4}{:>6}{:>9}{:>8}{:>8}{:>9}".format("task","n","pass","med_s","min_s","max_s","med_MB"))
    tot=tp=0
    for t in TASKS:
        c=cell(a,t)
        if not c: continue
        tot+=c["n"]; tp+=c["npass"]
        print("{:<9}{:>4}{:>6}{:>9.2f}{:>8.2f}{:>8.2f}{:>9.1f}".format(TLAB[t],c["n"],c["npass"],c["med"],c["mn"],c["mx"],c["mem"]))
    mems=[float(r["peak_mem_mb"]) for r in rows if r["agent"]==a]
    print(f"TOTAL {tp}/{tot} passed | mem {min(mems):.1f}-{max(mems):.1f} MB\n")

print("=== MEDIAN LATENCY (s) by task ===")
print("{:<9}".format("task")+"".join(f"{a[:11]:>13}" for a in agents))
for t in TASKS:
    line="{:<9}".format(TLAB[t])
    for a in agents:
        c=cell(a,t); line += f"{c['med']:>13.2f}" if c else f"{'-':>13}"
    print(line)

print("\n=== MEDIAN PEAK MEMORY (MB) by task ===")
print("{:<9}".format("task")+"".join(f"{a[:11]:>13}" for a in agents))
for t in TASKS:
    line="{:<9}".format(TLAB[t])
    for a in agents:
        c=cell(a,t); line += f"{c['mem']:>13.1f}" if c else f"{'-':>13}"
    print(line)

print("\n=== SUCCESS (passed/total) by task ===")
print("{:<9}".format("task")+"".join(f"{a[:11]:>13}" for a in agents))
for t in TASKS:
    line="{:<9}".format(TLAB[t])
    for a in agents:
        c=cell(a,t); line += f"{str(c['npass'])+'/'+str(c['n']):>13}" if c else f"{'-':>13}"
    print(line)
