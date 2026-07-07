import type { PlanningStatus, Task } from "@/lib/okf"
import { pct } from "@/lib/format"
import { cn } from "@/lib/utils"

const statusMeta: Record<string, { label: string; dot: string; text: string }> = {
  done: { label: "done", dot: "bg-primary", text: "text-muted-foreground line-through" },
  in_progress: { label: "active", dot: "bg-warning animate-pulse", text: "text-foreground" },
  todo: { label: "queued", dot: "bg-muted-foreground/30", text: "text-muted-foreground" },
  planned: { label: "planned", dot: "bg-muted-foreground/30", text: "text-muted-foreground" },
}

export function ExecutionPanel({
  tasks,
  planning,
}: {
  tasks: Task[]
  planning: PlanningStatus
}) {
  const done = tasks.filter((t) => t.status === "done").length
  const ratifyRatio = planning.specs_total ? planning.specs_ratified / planning.specs_total : 0

  return (
    <div className="flex h-full flex-col rounded-lg border border-border bg-card p-5 sm:p-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold tracking-tight text-foreground">Execution</h2>
        <span className="font-mono text-xs text-muted-foreground">
          {done}/{tasks.length} tasks
        </span>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-3 font-mono text-xs">
        <div className="rounded-md border border-border bg-background/40 p-3">
          <div className="text-foreground">
            {planning.specs_ratified}/{planning.specs_total}
          </div>
          <div className="mt-1 text-[10px] uppercase tracking-widest text-muted-foreground">
            specs ratified · {pct(ratifyRatio)}
          </div>
        </div>
        <div className="rounded-md border border-border bg-background/40 p-3">
          <div className="text-foreground">{planning.open_questions}</div>
          <div className="mt-1 text-[10px] uppercase tracking-widest text-muted-foreground">
            open questions
          </div>
        </div>
      </div>

      <ul className="mt-4 flex flex-1 flex-col divide-y divide-border overflow-y-auto">
        {tasks.map((task) => {
          const meta = statusMeta[task.status] || { label: task.status, dot: "bg-muted-foreground/30", text: "text-muted-foreground" }
          return (
            <li key={task.id} className="flex items-center gap-3 py-2.5">
              <span className={cn("h-1.5 w-1.5 shrink-0 rounded-full", meta.dot)} />
              <span className="font-mono text-[11px] text-muted-foreground">{task.id}</span>
              <span className={cn("flex-1 truncate text-sm", meta.text)}>{task.title}</span>
              <span className="font-mono text-[10px] uppercase tracking-wider text-muted-foreground/70">
                {meta.label}
              </span>
            </li>
          )
        })}
      </ul>
    </div>
  )
}
