import type { Bug, MetricDoc } from "@/lib/okf"
import { pct } from "@/lib/format"
import { cn } from "@/lib/utils"

const severityColor: Record<Bug["severity"], string> = {
  critical: "text-destructive",
  high: "text-destructive",
  medium: "text-warning",
  low: "text-muted-foreground",
}

export function BugPulse({ bugs, trace }: { bugs: Bug[]; trace?: MetricDoc }) {
  const open = bugs.filter((b) => b.status === "open")
  const resolved = bugs.filter((b) => b.status === "resolved")
  const coverage = Number(trace?.data.coverage_pct ?? 0)
  const tested = Number(trace?.data.requirements_tested ?? 0)
  const reqs = Number(trace?.data.requirements_total ?? 0)
  const drift = Number(trace?.data.drift_items ?? 0)

  return (
    <div className="flex h-full flex-col rounded-lg border border-border bg-card p-5 sm:p-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold tracking-tight text-foreground">Bug &amp; Test Pulse</h2>
        <span className="font-mono text-xs text-muted-foreground">specs/bugs</span>
      </div>

      {/* counts */}
      <div className="mt-5 grid grid-cols-2 gap-3">
        <div className="rounded-md border border-destructive/30 bg-destructive/10 p-4">
          <div className="font-mono text-2xl font-semibold text-destructive tabular-nums">
            {open.length}
          </div>
          <div className="mt-1 font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
            open bugs
          </div>
        </div>
        <div className="rounded-md border border-primary/30 bg-primary/10 p-4">
          <div className="font-mono text-2xl font-semibold text-primary tabular-nums">
            {resolved.length}
          </div>
          <div className="mt-1 font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
            resolved
          </div>
        </div>
      </div>

      {/* coverage bar */}
      <div className="mt-5">
        <div className="flex items-center justify-between font-mono text-xs">
          <span className="text-muted-foreground">tested requirements</span>
          <span className="text-foreground">
            {tested}/{reqs} · {pct(coverage)}
          </span>
        </div>
        <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-secondary">
          <div className="h-full rounded-full bg-primary" style={{ width: pct(coverage) }} />
        </div>
        <p className="mt-2 font-mono text-[11px] text-muted-foreground">
          {drift} traceability drift items flagged
        </p>
      </div>

      {/* open bug list */}
      <ul className="mt-5 flex flex-1 flex-col gap-2 border-t border-border pt-4">
        {open.map((bug) => (
          <li key={bug.id} className="flex items-start gap-3">
            <span className={cn("mt-1 h-1.5 w-1.5 shrink-0 rounded-full", severityColor[bug.severity].replace("text-", "bg-"))} />
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-mono text-xs text-muted-foreground">{bug.id}</span>
                <span className={cn("font-mono text-[10px] uppercase tracking-wider", severityColor[bug.severity])}>
                  {bug.severity}
                </span>
              </div>
              <p className="truncate text-sm text-foreground/90">{bug.title}</p>
            </div>
          </li>
        ))}
        {open.length === 0 ? (
          <li className="text-sm text-muted-foreground">No open bugs. All clear.</li>
        ) : null}
      </ul>
    </div>
  )
}
