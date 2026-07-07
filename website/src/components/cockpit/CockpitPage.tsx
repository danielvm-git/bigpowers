import { getCockpit } from "@/lib/okf"
import { TopBar } from "@/components/cockpit/top-bar"
import { HeroStats } from "@/components/cockpit/hero-stats"
import { LoopTracker } from "@/components/cockpit/loop-tracker"
import { BugPulse } from "@/components/cockpit/bug-pulse"
import { ExecutionPanel } from "@/components/cockpit/execution-panel"
import { Roadmap } from "@/components/cockpit/roadmap"

function SectionLabel({ index, title }: { index: string; title: string }) {
  return (
    <div className="mb-4 flex items-center gap-3">
      <span className="font-mono text-xs text-primary">{index}</span>
      <h2 className="font-mono text-xs uppercase tracking-widest text-muted-foreground">{title}</h2>
      <span className="h-px flex-1 bg-border" />
    </div>
  )
}

export default function Home() {
  const cockpit = getCockpit()
  const trace = cockpit.metrics["MET-traceability"]

  return (
    <div className="min-h-screen">
      <TopBar state={cockpit.state} />
      <main>
        <HeroStats cockpit={cockpit} />

        <div className="mx-auto max-w-6xl space-y-14 px-4 py-14 sm:px-6">
          {/* Module A — Engineering Cockpit */}
          <section>
            <SectionLabel index="A" title="Engineering Cockpit" />
            <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
              <BugPulse bugs={cockpit.bugs} trace={trace} />
              <ExecutionPanel tasks={cockpit.tasks} planning={cockpit.planning} />
            </div>
          </section>

          {/* Module B — Project Story */}
          <section>
            <SectionLabel index="B" title="Project Story" />
            <div className="space-y-3">
              <LoopTracker state={cockpit.state} />
              <Roadmap epics={cockpit.epics} />
            </div>
          </section>
        </div>
      </main>

      <footer className="border-t border-border">
        <div className="mx-auto flex max-w-6xl flex-col gap-2 px-4 py-8 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <p className="font-mono text-xs text-muted-foreground">
            bigpowers · management cockpit · built from the OKF spec spine
          </p>
          <p className="font-mono text-xs text-muted-foreground/70">
            aggregated at build time from{" "}
            <span className="text-foreground/70">specs/</span>
          </p>
        </div>
      </footer>
    </div>
  )
}
