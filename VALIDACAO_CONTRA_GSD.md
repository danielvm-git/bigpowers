# Validação Cruzada: Bigpowers vs. GSD (Get Shit Done)

**Data:** 2026-05-18  
**Scope:** Comparar consolidação proposta com arquitetura de artefatos de GSD

---

## 1. Comparação de Estrutura

### GSD (Get Shit Done)
```
.planning/
├── PROJECT.md       ← Contexto do projeto (validado vs. em escopo)
├── ROADMAP.md       ← Fases + plans + success criteria
├── STATE.md         ← Estado atual (< 100 linhas)
├── {phase}-{plan}-PLAN.md    ← Planos individuais
└── todos/pending/            ← Ideias capturadas

templates/             ← 30+ templates
references/            ← 60+ docs de referência técnica
workflows/             ← 93+ workflows (comandos CLI)
```

### Bigpowers (Proposta de Consolidação)
```
specs/
├── STATE.md              ← Estado atual (59 linhas) ✅
├── RELEASE-PLAN.md       ← Roadmap vivo ✅
├── PLAN-v*.md            ← Histórico → archive/ ✅
├── archive/releases/     ← Novo: histórico consolidado
├── CONTEXT.md, UBIQUITOUS_LANGUAGE.md, etc.
└── ...

SKILL-INDEX.md           ← Novo: tabela canônica
README.md                ← Simplificado
CONVENTIONS.md           ← Existente
```

---

## 2. Gap Analysis: O Que Falta em Bigpowers

### 2.1 Falta: PROJECT.md (Contexto do Projeto)

**GSD tem:**
```markdown
# PROJECT.md

## What This Is
[Descrição atual do projeto]

## Core Value
[Uma coisa que importa mais]

## Requirements
- Validated (já enviado, comprovado)
- Active (em construção)
- Out of Scope (com razão do exclusão)

## Context
[Background técnico e de usuário]

## Constraints
[Limitações: stack, timeline, etc.]

## Key Decisions
[Histórico de decisões significativas]
```

**Bigpowers não tem equivalente.** Tem CLAUDE.md (comandos, stack, arquitetura), mas não tem:
- ❌ Requisitos (Validated/Active/Out of Scope)
- ❌ Core Value (a uma coisa que importa)
- ❌ Decisões significativas rastreadas
- ❌ Constraints formalizadas

**Recomendação:** Criar `specs/PROJECT.md` para bigpowers com:
- What This Is: "38 agent skills for spec-driven TDD by solo developers"
- Core Value: "Maintain quality (audit score) while scaling skill count"
- Active Requirements: Feature completeness, testing mandates, etc.
- Out of Scope: Domain-specific skills (scaffold-exercises), plugins, marketplace
- Key Decisions: verb-noun naming, local-first (sem GitHub issues), BMAD phases, etc.

---

### 2.2 ROADMAP.md vs. RELEASE-PLAN.md

**GSD usa ROADMAP.md:**
- Fases numeradas (1, 2, 3, ...)
- Decimal phases para inserts (2.1 = "critical fix inserted between 2 and 3")
- Success Criteria (observable behaviors)
- Plans count per phase
- Progress table com milestone column

**Bigpowers usa RELEASE-PLAN.md:**
- Releases (v1.11, v1.12, ...)
- WSJF scoring
- Status (✅, ⏳)
- Focus area (Benchmarks, Auditor, Karpathy, etc.)
- Detailed action items per release

**Análise:**
- ✅ RELEASE-PLAN.md é mais rico que ROADMAP (tem WSJF, status, detalhes)
- ✅ Ambas rastreiam progresso
- ⚠️ Bigpowers não tem "Success Criteria" formalizados (deveriam estar em STATE ou PROJECT)

**Recomendação:** Manter RELEASE-PLAN.md, mas adicionar "Success Criteria" por release:
```markdown
### v1.17.0 — Guardrails (WSJF 3.2) ⏳

**Success Criteria:**
- [ ] "Zoom-out mandate" implemented in plan-work as HARD-GATE
- [ ] Surgical changes checklist in audit-code passes 100% of tests
- [ ] CONVENTIONS.md explicitly forbids "touch unrelated code"
```

---

### 2.3 Artefatos Intermediários (Templates)

**GSD tem 30+ templates:**
- AI-SPEC.md, DEBUG.md, VALIDATION.md
- discovery.md, research.md, spec.md
- planner-subagent-prompt.md
- continue-here.md

**Bigpowers tem:**
- Implícitos em cada skill (não há templates separados)
- Rely em CONVENTIONS.md

**Recomendação:** Criar `templates/` subdir em bigpowers:
```
templates/
├── spec.md              (→ specs/PLAN.md output format)
├── phase-discussion.md  (→ output de elaborate-spec)
├── diagnosis.md         (→ output de investigate-bug)
└── ...
```

---

### 2.4 Referências Técnicas (References)

**GSD tem 60+ references:**
- gates.md (quais gates bloquear, quais permitir)
- planner-antipatterns.md (o que não fazer)
- verification-patterns.md (como testar)
- thinking-models-*.md (modelos de pensamento por agente)
- tdd.md, executor-examples.md

**Bigpowers tem:**
- AUDIT.md (auditoria de cobertura de Clean Code)
- COMPARISON.md (comparação com superpowers, BMAD, etc.)
- Skills source em SKILL.md (inline docs)

**Recomendação:** Segregar em `references/`:
```
references/
├── clean-code-mapping.md     (como cada skill implementa Clean Code)
├── gates-and-guardrails.md   (HARD-GATEs em cada skill)
├── skill-antipatterns.md     (o que não fazer em cada skill)
├── bmad-lifecycle.md         (phases BMAD detalhadas)
└── ...
```

---

## 3. Validação: Minha Proposta vs. GSD

### O Que Está Certo em Minha Proposta

✅ **Hierarquia de artefatos**
- STATE → RELEASE-PLAN → SKILL-INDEX → README
- GSD faz: PROJECT → ROADMAP → STATE → PLAN
- Abordagens equivalentes, estilos diferentes

✅ **Consolidação de redundância**
- Deletar PLAN.md (stale) ← mesma que GSD faria
- Arquivar PLAN-v*.md ← GSD collapsa em `<details>` tags
- Single skill index ← GSD não tem equivalent, é um win para bigpowers

✅ **Nomes simples (verb-noun)**
- Bigpowers: `develop-tdd`, `validate-fix`, etc.
- GSD: `/gsd-new-project`, `/gsd-plan-phase`, etc. (verb-noun style)
- ✓ Bigpowers está bem aqui

✅ **Clareza de fases (BMAD)**
- Bigpowers: Discover → Elaborate → Plan → Build → Sustain
- GSD: Phase 1, 2, 3, ... (fases numeradas)
- Ambas funcionam; BMAD é mais descritivo

### O Que Está Incompleto em Minha Proposta

❌ **Falta PROJECT.md**
- GSD começa aqui: "What This Is", "Core Value", "Requirements"
- Bigpowers tem CLAUDE.md, mas não `specs/PROJECT.md`
- **Ação:** Adicionar PROJECT.md como canônico de contexto do projeto

❌ **Falta Success Criteria formalizados**
- GSD em ROADMAP: "Observable behaviors that must be TRUE"
- Bigpowers em RELEASE-PLAN: Apenas "Focus Area" e "Objective"
- **Ação:** Adicionar Success Criteria por release em RELEASE-PLAN.md

❌ **Falta templates/ e references/**
- GSD segrega templates (30+) e references (60+)
- Bigpowers tem tudo inline em SKILL.md
- **Ação:** Opcional; se fizer, criar `templates/` e `references/` como em GSD

❌ **Falta "Skill Antipatterns" ou "Gates"**
- GSD tem gates.md (quais gates bloquear)
- Bigpowers tem mandates em prose, não formalizados
- **Ação:** Criar `references/gates-and-guardrails.md`

---

## 4. Recomendação: Incorporar Melhores Práticas de GSD

### Fase 1: Imediato (Incorporar em Análise/SKILL-INDEX)

- [ ] Criar `specs/PROJECT.md` com:
  - What This Is
  - Core Value
  - Active Requirements
  - Out of Scope
  - Key Decisions (a tabela de ADRs existentes)

- [ ] Atualizar RELEASE-PLAN.md com Success Criteria por release

- [ ] Manter SKILL-INDEX.md como proposto (similar a nada em GSD, é um win único)

### Fase 2: Médio Prazo (30 min de trabalho)

- [ ] Criar `templates/` com estruturas esperadas (spec.md, diagnosis.md, etc.)

- [ ] Criar `references/bmad-phases.md` (ciclo BMAD detalhado)

- [ ] Criar `references/gates-and-guardrails.md` (HARD-GATEs por skill)

### Fase 3: Longo Prazo (Nice-to-Have)

- [ ] Criar `references/skill-antipatterns.md` (o que não fazer)

- [ ] Criar `references/clean-code-mapping.md` (como cada skill implementa Clean Code)

---

## 5. Tabela: Estrutura Final Recomendada

| Nível | Artefato | Propósito | GSD Equivalente |
|---|---|---|---|
| **Visão** | specs/PROJECT.md | Contexto, requisitos, decisões | PROJECT.md |
| **Roadmap** | specs/RELEASE-PLAN.md | Sequência de releases + success criteria | ROADMAP.md |
| **Estado** | specs/STATE.md | Posição atual (< 100 linhas) | STATE.md |
| **Skill Catalog** | SKILL-INDEX.md | Tabela canônica de 38 skills | (N/A em GSD) |
| **Templates** | templates/*.md | Estruturas esperadas | templates/ |
| **Referência** | references/*.md | Gates, antipatterns, ciclo BMAD | references/ |
| **Documentação** | README.md | Install, quickstart | README.md |
| **Convênios** | CONVENTIONS.md | Code, test, git, specs/ standards | CONVENTIONS.md |
| **Histórico** | specs/archive/releases/PLAN-v*.md | Planos completados | (Collapsed em ROADMAP) |

---

## 6. Validação Final: Aplicar ao Projeto Skills

**Antes (Atual):**
```
PLAN.md (stale, 453 linhas)
        ↓
specs/RELEASE-PLAN.md (vivo, 104 linhas)
      ↓
specs/STATE.md (59 linhas) ✓
      ↓
specs/PLAN-v*.md (16 arquivos, dispersos)
      ↓
README.md (191 linhas, copia RELEASE-PLAN)
```

**Depois (Proposto + GSD Best Practice):**
```
specs/PROJECT.md (novo)           ← Core Value, Requirements, Decisions
        ↓
specs/RELEASE-PLAN.md (revisado)  ← Roadmap + Success Criteria
        ↓
specs/STATE.md (mantém)           ← Current Position
        ↓
SKILL-INDEX.md (novo)             ← Tabela canônica
        ↓
README.md (simplificado)          ← Install, quickstart, link a SKILL-INDEX
        ↓
templates/ (novo, opcional)       ← Estruturas esperadas
references/ (novo, opcional)      ← Gates, antipatterns, BMAD phases
```

**Resultado:**
- ✅ Sem redundância entre PLAN.md, RELEASE-PLAN, README
- ✅ Hierarquia clara: PROJECT → RELEASE-PLAN → STATE → SKILL-INDEX
- ✅ Incorpora melhores práticas de GSD sem copiar excessivamente
- ✅ Nomes simples (verb-noun) mantidos
- ✅ Fases BMAD explícitas em PROJECT.md ou documento separado

---

## 7. Checklist Final

- [x] Minha análise identificou redundâncias corretas (PLAN.md, PLAN-v*.md, skill index)
- [x] Minha hierarquia proposta é consistente com GSD (STATE → ROADMAP → skills)
- [x] Faltou: PROJECT.md (contexto do projeto)
- [x] Faltou: Success Criteria formalizados
- [x] Faltou: templates/ e references/ (nice-to-have)
- [x] SKILL-INDEX.md é único valor adicionado vs. GSD (bom!)
- [x] Nomes simples e ciclo BMAD estão corretos
- [x] Recomendação: Incorporar PROJECT.md + Success Criteria antes de executar

---

## 8. Próximos Passos Imediatos

1. ✅ Criar `specs/PROJECT.md` com estrutura de GSD
2. ✅ Atualizar `specs/RELEASE-PLAN.md` com Success Criteria
3. ✅ Finalmente: Deletar `PLAN.md`, arquivar `PLAN-v*.md`, simplificar README
4. 📝 Opcional: Criar `templates/` e `references/` conforme GSD

