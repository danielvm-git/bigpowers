# Análise de Consolidação: GSD → Nomes Simples + Ciclo BMAD

**Data:** 2026-05-18  
**Status:** Proposta de ação para eliminar redundância entre STATE.md, RELEASE-PLAN.md, PLAN.md e README.md

---

## 1. Diagnóstico: Redundância Atual

### 1.1 O Problema

Você tem **4 artefatos que se sobrepõem**:

| Artefato | Propósito Declarado | Realidade | Problema |
|---|---|---|---|
| `README.md` | Documentação pública (install, skill index) | Lista 36 skills em tabela de fase | Fase da skill é *descrição* visual, não *governança* |
| `PLAN.md` (raiz) | Plano de implementação (27 KB) | Cópia literal do que foi aprovado; nunca atualizado pós-v1.0 | Stale; duplica RELEASE-PLAN.md |
| `specs/RELEASE-PLAN.md` | Roadmap vivo (v1.11 → v1.21) | Sequência com WSJF, status, detalhes de cada release | Fonte viva de verdade ✓ |
| `specs/STATE.md` | Estado da sessão + audit score | Milestone atual, hash git, status de releases completadas | Resumido; não governa o dia-a-dia |
| `specs/PLAN-v1.*.md` (×16 arquivos) | Plano por release (por ex: v1.14.0) | Detalhe tático: tarefas, checkboxes, learnings | Útil per-release, mas nunca consolidado |

**Resultado:** Um desenvolvedor olha 3 lugares diferentes e não sabe qual é a verdade.

---

### 1.2 Redundâncias Específicas

#### 1. README.md vs. RELEASE-PLAN.md

- **README.md linha 19-59:** Lista todas as 36 skills com fase
- **RELEASE-PLAN.md linhas 11-25:** Mesmo índice, mas com WSJF e status
- **Quem ganha?** RELEASE-PLAN.md tem mais contexto (WSJF, status, pré-requisitos)

#### 2. PLAN.md vs. RELEASE-PLAN.md

- **PLAN.md é literalmente o documento anterior** — uma "cópia de aprovação"
- **RELEASE-PLAN.md é o mesmo documento, mas agora atualizado com v1.14–v1.21**
- **Solução:** Delete PLAN.md. RELEASE-PLAN.md é o canônico.

#### 3. README.md vs. PLAN.md (estrutura)

- Ambos definem "Naming Convention" e "Workflow Arc"
- README tem diagramas ASCII; PLAN tem tabelas detalhadas
- **Solução:** README fica minimalista (instalar, quickstart). Detalhe vai para CONVENTIONS.md ou docs/ separados.

#### 4. Múltiplos PLAN-v*.md vs. RELEASE-PLAN.md

- 16 arquivos históricos (v1.2.0 → v1.16.0) nunca consolidas
- Serve para auditoria? Sim. Serve para planejamento? Não — é tudo passado.
- **Solução:** Arquivar em `specs/archive/` e manter histórico, mas não no caminho crítico.

---

## 2. O que GSD Faz Bem (O que Manter)

### 2.1 Nomes de Skills — Simples & Compreensíveis

Seus skill names **são excelentes** — verb-noun pairs, buscáveis, sem ruído:

✅ `develop-tdd` (entendível)  
✅ `validate-fix` (ação clara)  
✅ `challenge-design` (inteligível)  
✅ `define-success` (didático)  

### 2.2 O Ciclo BMAD — Estrutura Clara

BMAD divide o ciclo em **fases bem definidas**:

```
Discover (investigar) 
  → Elaborate (refinar) 
  → Plan (planejar) 
  → Build (construir, escrever código) 
  → Sustain (manter, revisar, liberar)
```

---

## 3. Solução Proposta: Consolidação com Clareza de Fases

### 3.1 Hierarquia de Artefatos (Nova Verdade Única)

```
Nível             Artefato           Responsabilidade
──────────────────────────────────────────────────────
Executivo         STATE.md           Milestone + status de releases
(sessão atual)

Tático            RELEASE-PLAN.md    Roadmap v1.17–v1.21 + histórico 
(próximas 5       
 releases)

Operacional       PLAN-v*.md         Tarefas por release (archive pós-completion)
(per-release)

Referência        README.md          Instalar, ciclo BMAD, link a SKILL-INDEX
(documentação)

Consolidado       SKILL-INDEX.md     ← NOVO: tabela canônica de 38 skills
(skill catalog)

Convênios         CONVENTIONS.md     Código, testes, git, specs/
(toda sessão)
```

### 3.2 O que Deletar

| Arquivo | Ação | Razão |
|---|---|---|
| `PLAN.md` (raiz) | **Deletar** | Congelado em v1.0. RELEASE-PLAN.md é o vivo. |
| `specs/PLAN-v*.md` (×16) | **Arquivar** → `specs/archive/releases/` | Histórico; não crítico para o forward. |
| Skill index em 3 lugares | **Consolidar** → `SKILL-INDEX.md` | Uma tabela, referenciada em 3 docs. |

### 3.3 O que Fica

```
specs/
├── STATE.md                 ← "Milestone v1.17, branch main, hash ba7d054"
├── RELEASE-PLAN.md          ← "Próximas 5 releases com WSJF, pré-requisitos"
├── archive/releases/        ← Histórico de PLAN-v1.*.md
├── CONTEXT.md, UBIQUITOUS_LANGUAGE.md, SCOPE.md, TASKS.md, PLAN.md
└── adr/, SPIKE-*, DIAGNOSIS.md, BUG-LOG.md

SKILL-INDEX.md              ← NOVO: 38 skills × fase × status × fonte
README.md                   ← Referencia SKILL-INDEX.md (não copia)
CONVENTIONS.md              ← Convênios, referencia SKILL-INDEX.md
```

---

## 4. Consolidação de Skills (BMAD Phases)

### Mapeamento de Nomes Simples → Fases BMAD

| Fase BMAD | Skills | Descrição | Status |
|---|---|---|---|
| **Discover** | survey-context, elaborate-spec | Questionamento & refino inicial | ✅ Claro |
| **Elaborate** | model-domain, define-language, challenge-design, grill-with-docs, deepen-architecture | Design & arquitetura | ✅ Claro |
| **Plan** | scope-work, slice-tasks, define-success, plan-work, plan-refactor | Planejamento detalhado | ✅ Claro |
| **Spike** | spike-prototype | Prototipagem exploratória | ✅ Claro |
| **Build** | kickoff-branch, guard-git, hook-commits, develop-tdd, delegate-task, dispatch-agents, execute-plan, wire-observability | Implementação + testes + observabilidade | ✅ Claro |
| **Bug** | investigate-bug, diagnose-root, validate-fix | Debugging & fix | ✅ Claro |
| **Review** | audit-code, request-review, respond-review | Revisão de qualidade | ✅ Claro |
| **Integrate** | commit-message, release-branch | Integração & release | ✅ Claro |
| **Sustain** | inspect-quality, organize-workspace | Manutenção & limpeza | ✅ Claro |
| **Utility** | terse-mode, craft-skill, edit-document | Transversais (qualquer fase) | ✅ Claro |
| **Bootstrap** | using-bigpowers, seed-conventions | One-time setup | ✅ Claro |

---

## 5. Plano de Ação (Ordem de Execução)

### Fase 1: Preparação (30 min)
- [ ] ✅ Criar `SKILL-INDEX.md` (tabela canônica) — **DONE**
- [ ] Verificar que todos os 37-38 skills estão listados
- [ ] Revisar linhas 1 e 11-25 de README.md (índice antigo)

### Fase 2: Consolidação (1h)
- [ ] Deletar `PLAN.md` (raiz)
- [ ] Criar `specs/archive/releases/` e mover `PLAN-v*.md` pra lá
- [ ] Atualizar README.md: referenciar SKILL-INDEX.md ao invés de copiar tabela

### Fase 3: Revisão de Referências (30 min)
- [ ] Confirmar RELEASE-PLAN.md está correto e completo
- [ ] Confirmar STATE.md é apenas "estou aqui, próximo é isso"
- [ ] Encontrar todo `grill-me` em documentação, corrigir para `challenge-design`

### Fase 4: Documentação (30 min)
- [ ] Adicionar comentário no topo de README, STATE, RELEASE-PLAN explicando hierarquia
- [ ] Seção "Single Source of Truth" em CONVENTIONS.md

---

## 6. Resumo de Benefícios

| Antes | Depois |
|---|---|
| Skill index em 3 lugares (README, RELEASE-PLAN, PLAN) | Skill index em 1 lugar; referenciado em 3 |
| PLAN.md stale coexiste com RELEASE-PLAN.md vivo | 1 canônico, histórico arquivado |
| 16 PLAN-v*.md dispersos em specs/ | Histórico limpo em archive/ |
| Hierarquia de artefatos implícita | Explícita: STATE → RELEASE-PLAN → SKILL-INDEX |
| Fases BMAD descritas em prosa em múltiplos lugares | Diagrama visual único em README + SKILL-INDEX |
| README 450 linhas; PLAN.md 450 linhas; redundância óbvia | README < 200 linhas; referencia SKILL-INDEX (11 KB) |

---

## 7. Próximos Passos Recomendados

1. **Revisar ambos os arquivos** (este + SKILL-INDEX.md)
2. **Executar Fase 1–4** acima
3. **Git commit:** `feat(docs): consolidate skill index + BMAD lifecycle`
4. **Validar:** rodar testes, compliance check, etc.
