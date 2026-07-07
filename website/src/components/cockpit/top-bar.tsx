import type { ProjectState } from "@/lib/okf"
import { formatDate } from "@/lib/format"

export function TopBar({ state }: { state: ProjectState }) {
  return (
    <header className="sticky top-0 z-30 border-b border-border bg-background/80 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3 sm:px-6">
        <div className="flex items-center gap-3">
          <span className="relative flex h-2.5 w-2.5">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-primary opacity-60" />
            <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-primary" />
          </span>
          <span className="font-mono text-sm font-semibold tracking-tight text-foreground">
            bigpowers
          </span>
          <span className="hidden font-mono text-xs text-muted-foreground sm:inline">
            / management-cockpit
          </span>
        </div>

        <div className="flex items-center gap-4 font-mono text-xs text-muted-foreground">
          <span className="hidden items-center gap-1.5 md:flex">
            <span className="text-muted-foreground/60">v</span>
            {state.version}
          </span>
          <span className="hidden items-center gap-1.5 sm:flex">
            <span className="text-muted-foreground/60">sync</span>
            {formatDate(state.updated)}
          </span>
          <span className="flex items-center gap-1.5 rounded border border-primary/30 bg-primary/10 px-2 py-1 text-primary">
            OKF LIVE
          </span>
        </div>
      </div>
    </header>
  )
}
