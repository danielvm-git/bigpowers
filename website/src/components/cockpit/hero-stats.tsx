import type { Cockpit } from "@/lib/okf"
import { compactNumber, usd, pct } from "@/lib/format"

function StatCard({
  label,
  value,
  unit,
  sub,
}: {
  label: string
  value: string
  unit?: string
  sub: string
}) {
  return (
    <div className="group relative flex flex-col justify-between gap-6 rounded-lg border border-border bg-card p-5 transition-colors hover:border-primary/40">
      <div className="flex items-center justify-between">
        <span className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
          {label}
        </span>
        <span className="h-1.5 w-1.5 rounded-full bg-primary/50 transition-colors group-hover:bg-primary" />
      </div>
      <div>
        <div className="flex items-baseline gap-1.5">
          <span className="font-mono text-3xl font-semibold tracking-tight text-foreground tabular-nums">
            {value}
          </span>
          {unit ? <span className="font-mono text-sm text-muted-foreground">{unit}</span> : null}
        </div>
        <p className="mt-1.5 text-xs text-muted-foreground">{sub}</p>
      </div>
    </div>
  )
}

export function HeroStats({ cockpit }: { cockpit: Cockpit }) {
  const { metrics, state } = cockpit
  const dora = metrics["MET-dora"]?.data ?? {}
  const cost = metrics["MET-agent-cost"]?.data ?? {}
  const effort = metrics["MET-effort"]?.data ?? {}

  return (
    <section className="relative overflow-hidden border-b border-border bg-grid">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-primary/40 to-transparent" />
      <div className="mx-auto max-w-6xl px-4 py-14 sm:px-6 sm:py-20">
        <div className="max-w-2xl">
          <span className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-3 py-1 font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
            Engineering Cockpit
          </span>
          <h1 className="mt-5 text-balance text-4xl font-semibold tracking-tight text-foreground sm:text-5xl">
            The live state of{" "}
            <span className="text-primary">bigpowers</span>, aggregated from its own specs.
          </h1>
          <p className="mt-4 max-w-xl text-pretty leading-relaxed text-muted-foreground">
            {state.description} Every metric below is parsed at build time from the{" "}
            <span className="font-mono text-foreground/80">specs/</span> OKF spine and refreshes on
            every merged commit.
          </p>
        </div>

        <div className="mt-10 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            label="Median Lead Time"
            value={String(dora.lead_time_hours_median ?? "—")}
            unit="hrs"
            sub={`${dora.deployments_total ?? 0} deploys · ${pct(Number(dora.change_fail_rate ?? 0))} change-fail`}
          />
          <StatCard
            label="Agent Tokens"
            value={compactNumber(Number(cost.tokens_total ?? 0))}
            sub={`${usd(Number(cost.cost_usd ?? 0))} across ${cost.runs_total ?? 0} runs`}
          />
          <StatCard
            label="Cumulative Effort"
            value={String(effort.effort_hours_total ?? "—")}
            unit="hrs"
            sub={`${effort.effort_hours_agent ?? 0}h agent · ${effort.effort_hours_human ?? 0}h human`}
          />
          <StatCard
            label="Deploy Frequency"
            value={String(dora.deploy_frequency_per_week ?? "—")}
            unit="/wk"
            sub={`MTTR ${dora.mttr_hours ?? "—"}h · ${effort.commits_total ?? 0} commits`}
          />
        </div>
      </div>
    </section>
  )
}
