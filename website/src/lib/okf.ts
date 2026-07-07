import fs from "node:fs"
import path from "node:path"
import yaml from "yaml"

const SPECS_DIR = path.join(process.cwd(), "..", "specs")

function parseYaml(raw: string): unknown {
  return yaml.parse(raw)
}

function parseFrontmatter(raw: string) {
  const match = raw.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/)
  if (match) {
    return {
      data: yaml.parse(match[1]),
      content: match[2]
    }
  }
  return { data: {}, content: raw }
}

/* ---------- types ---------- */

export type Phase = "Discover" | "Plan" | "Build" | "Verify" | "Release" | "Operate"

export interface ProjectState {
  project: string
  description: string
  version: string
  updated: string
  loop: { phases: Phase[] }
  active_epic: {
    id: string
    title: string
    phase: Phase
    started: string
    owner: string
    progress: number
  }
}

export interface PlanningStatus {
  epic: string
  specs_total: number
  specs_ratified: number
  open_questions: number
  last_planning_session: string
}

export type EpicStatus = "shipped" | "active" | "planned"

export interface Epic {
  id: string
  title: string
  status: EpicStatus
  shipped?: string
  summary: string
}

export interface Task {
  id: string
  title: string
  status: "done" | "in_progress" | "todo"
}

export interface Bug {
  id: string
  title: string
  severity: "low" | "medium" | "high" | "critical"
  status: "open" | "resolved"
  opened: string
  resolved?: string
  epic: string
}

export interface MetricDoc {
  id: string
  title: string
  body: string
  data: Record<string, number | string>
}

/* ---------- helpers ---------- */

function readYaml<T>(file: string, fallback: T): T {
  try {
    const raw = fs.readFileSync(path.join(SPECS_DIR, file), "utf8")
    return (parseYaml(raw) as T) ?? fallback
  } catch {
    return fallback
  }
}

function readDir(sub: string): string[] {
  try {
    return fs
      .readdirSync(path.join(SPECS_DIR, sub))
      .filter((f) => f.endsWith(".okf.md"))
      .map((f) => path.join(SPECS_DIR, sub, f))
  } catch {
    return []
  }
}

/* ---------- loaders ---------- */

export function getState(): ProjectState {
  const data = readYaml<Partial<ProjectState>>("state.yaml", {})
  return {
    project: data.project ?? "bigpowers",
    description: data.description ?? "",
    version: data.version ?? "0.0.0",
    updated: data.updated ?? "",
    loop: data.loop ?? { phases: ["Discover", "Plan", "Build", "Verify", "Release", "Operate"] },
    active_epic: typeof data.active_epic === "object" && data.active_epic ? (data.active_epic as any) : {
      id: typeof data.active_epic === "string" ? data.active_epic : "—",
      title: "Active Epic",
      phase: "Build" as Phase,
      started: "",
      owner: "",
      progress: 0,
    },
  }
}

export function getPlanning(): PlanningStatus {
  const data = readYaml<Partial<PlanningStatus>>("planning-status.yaml", {})
  return {
    epic: data.epic ?? "—",
    specs_total: data.specs_total ?? 0,
    specs_ratified: data.specs_ratified ?? 0,
    open_questions: data.open_questions ?? 0,
    last_planning_session: data.last_planning_session ?? "",
  }
}

export function getEpics(): Epic[] {
  const plan = readYaml<{ epics: Epic[] }>("release-plan.yaml", { epics: [] })
  return [...plan.epics].sort((a, b) => {
    const bd = b.shipped ?? ""
    const ad = a.shipped ?? ""
    if (ad !== bd) return bd.localeCompare(ad)
    return a.id.localeCompare(b.id)
  })
}

export function getTasks(): Task[] {
  const data = readYaml<{ development_status?: Record<string, string> }>("execution-status.yaml", {})
  if (!data.development_status) return []
  return Object.entries(data.development_status).map(([id, status]) => ({
    id,
    title: id,
    status: status as Task["status"]
  }))
}

export function getMetrics(): Record<string, MetricDoc> {
  const out: Record<string, MetricDoc> = {}
  for (const file of readDir("metrics")) {
    const parsed = parseFrontmatter(fs.readFileSync(file, "utf8"))
    const data = parsed.data as Record<string, number | string>
    out[String(data.id)] = {
      id: String(data.id),
      title: String(data.title ?? data.id),
      body: parsed.content.trim(),
      data,
    }
  }
  return out
}

export function getBugs(): Bug[] {
  const bugs: Bug[] = []
  for (const file of readDir("bugs")) {
    const parsed = parseFrontmatter(fs.readFileSync(file, "utf8"))
    bugs.push(parsed.data as Bug)
  }
  return bugs.sort((a, b) => (b.opened ?? "").localeCompare(a.opened ?? ""))
}

/* ---------- aggregate for the cockpit ---------- */

export interface Cockpit {
  state: ProjectState
  planning: PlanningStatus
  epics: Epic[]
  tasks: Task[]
  bugs: Bug[]
  metrics: Record<string, MetricDoc>
}

export function getCockpit(): Cockpit {
  return {
    state: getState(),
    planning: getPlanning(),
    epics: getEpics(),
    tasks: getTasks(),
    bugs: getBugs(),
    metrics: getMetrics(),
  }
}
