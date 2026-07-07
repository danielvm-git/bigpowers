import type { ProjectState } from "@/lib/okf"
import { formatDate, pct } from "@/lib/format"
import { cn } from "@/lib/utils"

export function LoopTracker({ state }: { state: ProjectState }) {
  const phases = state.loop.phases
  const activeIndex = phases.indexOf(state.active_epic.phase)

  return (
    <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold tracking-tight text-foreground">Delivery Loop</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Active epic{" "}
            <span className="font-mono text-foreground/80">{state.active_epic.id}</span> —{" "}
            {state.active_epic.title}
          </p>
        </div>
        <div className="text-right font-mono text-xs text-muted-foreground">
          <div className="text-primary">{pct(state.active_epic.progress)} complete</div>
          <div>started {formatDate(state.active_epic.started)}</div>
        </div>
      </div>

      {/* phase rail */}
      <ol className="mt-6 grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-6">
        {phases.map((phase, i) => {
          const done = i < activeIndex
          const active = i === activeIndex
          return (
            <li
              key={phase}
              className={cn(
                "relative flex flex-col gap-2 rounded-md border p-3",
                active
                  ? "border-primary/50 bg-primary/10"
                  : done
                    ? "border-border bg-secondary"
                    : "border-border bg-background/40",
              )}
            >
              <div className="flex items-center justify-between">
                <span className="font-mono text-[11px] text-muted-foreground">
                  {String(i + 1).padStart(2, "0")}
                </span>
                <span
                  className={cn(
                    "h-2 w-2 rounded-full",
                    active
                      ? "bg-primary animate-pulse"
                      : done
                        ? "bg-primary/60"
                        : "bg-muted-foreground/30",
                  )}
                />
              </div>
              <span
                className={cn(
                  "text-sm font-medium",
                  active ? "text-primary" : done ? "text-foreground" : "text-muted-foreground",
                )}
              >
                {phase}
              </span>
              <span className="font-mono text-[10px] uppercase tracking-wider text-muted-foreground/70">
                {active ? "in progress" : done ? "complete" : "queued"}
              </span>
            </li>
          )
        })}
      </ol>

      {/* progress bar */}
      <div className="mt-5">
        <div className="h-1.5 w-full overflow-hidden rounded-full bg-secondary">
          <div
            className="h-full rounded-full bg-primary transition-all"
            style={{ width: pct(state.active_epic.progress) }}
          />
        </div>
      </div>
    </div>
  )
}
