import csv, statistics as st

rows = list(csv.DictReader(open("results/data.csv")))
labels = {"task1":"T1 write","task2":"T2 chain","task3":"T3 count",
          "task4":"T4 append","task5":"T5 mem"}

def stats(agent):
    out = {}
    for t in ["task1","task2","task3","task4","task5"]:
        rr = [r for r in rows if r["agent"]==agent and r["task"]==t]
        if not rr:
            continue
        secs = [float(r["seconds"]) for r in rr]
        mem  = [float(r["peak_mem_mb"]) for r in rr]
        npass = sum(1 for r in rr if r["success"]=="pass")
        out[t] = (len(rr), npass, st.median(secs), min(secs), max(secs), st.median(mem))
    return out

for agent in ["picoclaw"]:
    p = stats(agent)
    print(f"=== {agent.upper()} (cloud, google/gemini-3.1-pro-preview) ===")
    hdr = ("task","n","pass","med_s","min_s","max_s","med_MB")
    print("{:<9}{:>3}{:>6}{:>9}{:>8}{:>8}{:>9}".format(*hdr))
    tot = tp = 0
    for t, v in p.items():
        n, npass, med, mn, mx, mem = v
        tot += n; tp += npass
        print("{:<9}{:>3}{:>6}{:>9.2f}{:>8.2f}{:>8.2f}{:>9.1f}".format(
              labels[t], n, npass, med, mn, mx, mem))
    print(f"TOTAL: {tp}/{tot} passed")
    allmem = [float(r["peak_mem_mb"]) for r in rows if r["agent"]==agent]
    print(f"overall peak-mem range: {min(allmem):.1f}-{max(allmem):.1f} MB")
