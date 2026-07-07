import type { Epic } from "@/lib/okf"
import { formatDate } from "@/lib/format"
import { cn } from "@/lib/utils"

const statusMeta: Record<Epic["status"], { label: string; ring: string; dot: string }> = {
  shipped: { label: "Shipped", ring: "border-border", dot: "bg-primary" },
  active: { label: "In Flight", ring: "border-primary/50 bg-primary/5", dot: "bg-primary animate-pulse" },
  planned: { label: "Planned", ring: "border-dashed border-border", dot: "bg-muted-foreground/40" },
}

export function Roadmap({ epics }: { epics: Epic[] }) {
  return (
    <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold tracking-tight text-foreground">Roadmap</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Epic momentum from{" "}
            <span className="font-mono text-foreground/80">release-plan.yaml</span>
          </p>
        </div>
        <span className="font-mono text-xs text-muted-foreground">{epics.length} epics</span>
      </div>

      <ol className="mt-6 space-y-0">
        {epics.map((epic, i) => {
          const meta = statusMeta[epic.status as keyof typeof statusMeta] || { label: epic.status, dot: "bg-muted-foreground/30", ring: "border-border" }
          return (
            <li key={epic.id} className="relative flex gap-4 pb-6 last:pb-0">
              {/* rail */}
              <div className="flex flex-col items-center">
                <span className={cn("mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full", meta.dot)} />
                {i < epics.length - 1 ? (
                  <span className="mt-1 w-px flex-1 bg-border" aria-hidden="true" />
                ) : null}
              </div>

              <div
                className={cn(
                  "flex-1 rounded-md border p-4 transition-colors",
                  meta.ring,
                )}
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs text-muted-foreground">{epic.id}</span>
                    <span className="text-sm font-medium text-foreground">{epic.title}</span>
                  </div>
                  <span
                    className={cn(
                      "font-mono text-[10px] uppercase tracking-widest",
                      epic.status === "active"
                        ? "text-primary"
                        : epic.status === "planned"
                          ? "text-muted-foreground/70"
                          : "text-muted-foreground",
                    )}
                  >
                    {meta.label}
                    {epic.shipped ? ` · ${formatDate(epic.shipped)}` : ""}
                  </span>
                </div>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{epic.summary}</p>
              </div>
            </li>
          )
        })}
      </ol>
    </div>
  )
}
