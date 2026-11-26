# What mobile-perf.sh measured → build/perf.json, build/perf.md; exit 1 above a budget.
#   mobile-perf.py <integration_response_data.json> <output folder> <cold start ms>...
import json
import statistics
import sys
from pathlib import Path

COLD_MS = 1500
FRAME_MS = 1000 / 60

frames = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
out = Path(sys.argv[2])
cold = sorted(int(x) for x in sys.argv[3:])
median = statistics.median(cold)
rows = [("Cold start to cached news, median", f"{median:.0f} ms", f"< {COLD_MS} ms", median < COLD_MS)]
result = {"cold_start_ms": cold, "cold_start_median_ms": median}
for name in ("feed", "shorts"):
    f = frames[name]
    build = f["90th_percentile_frame_build_time_millis"]
    raster = f["90th_percentile_frame_rasterizer_time_millis"]
    result[name] = {"frames": f["frame_count"], "build_p90_ms": build, "raster_p90_ms": raster}
    rows.append((f"{name}: build, p90", f"{build:.1f} ms", f"< {FRAME_MS:.1f} ms", build < FRAME_MS))
    # The emulator draws with its processor, not a graphics chip: reported, judged on a phone (G3).
    rows.append((f"{name}: raster, p90", f"{raster:.1f} ms", "reported", True))
(out / "perf.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
table = "| Profile build, Android emulator | Measured | Budget |\n|---|---|---|\n"
table += "".join(f"| {a} | {b} | {c}{'' if ok else ' **missed**'} |\n" for a, b, c, ok in rows)
(out / "perf.md").write_text(table, encoding="utf-8")
print(table)
print("PERF " + json.dumps(result))
sys.exit(0 if all(r[3] for r in rows) else 1)
