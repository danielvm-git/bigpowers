---
story_id: e20s01
title: "change-request conversational intake — parse natural-language requests"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e20s01: conversational intake

Add a conversational intake path to `change-request/SKILL.md` so users don't need
to paste pre-formatted change requests. In big-token-saver, the user pasted the full
SKILL.md + WSJF reference twice because they didn't know the format.

## Acceptance Criteria

- [ ] `change-request/SKILL.md` has a "Conversational Mode" section
- [ ] The section describes the 5-step conversational flow (Capture → Locate → Draft → Score → Place)
- [ ] Existing Mode A/B kept for programmatic/experienced users

## Conversational Flow

1. **Capture:** Parse the natural-language request for what, why, where
2. **Locate:** Identify which epic/capability the request affects
3. **Draft:** Present a structured draft for confirmation
4. **Score:** Estimate WSJF with explanation
5. **Place:** Confirm final epic placement before writing files

## Verification

```bash
grep -c "Conversational Mode\|conversational\|natural.language\|clarifying" change-request/SKILL.md | awk '{if($1>=2) print "OK: conversational mode"; else print "FAIL: only " $1 " refs"}'
```

## Gherkin Scenarios

```gherkin
Given a user types "Add skill for npm publishing"
And the message doesn't match the structured Mode A/B format
When change-request enters conversational mode
Then it asks: "What problem does npm publishing solve for bigpowers users?"
And after 2-3 clarifying exchanges, it drafts a change request
And presents the draft for user confirmation before writing epic files
```

## Implementation Notes

- Enter conversational mode when user input doesn't match Mode A or B format
- Max 3 clarifying questions before drafting
- Score step explains WSJF calculation so user understands prioritization
