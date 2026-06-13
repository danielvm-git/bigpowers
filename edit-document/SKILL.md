---
name: edit-document
model: sonnet
description: Edit and improve documents by restructuring sections, improving clarity, and tightening prose. Use when user wants to edit, revise, restructure, or improve any document — including specs/ files, articles, READMEs, or technical writing.
---

# Edit Document

**Distinct from `write-document`:** Use this skill when the document already exists and needs restructuring, clarity, or prose improvements. Use `write-document` to create a document from scratch.

> **HARD GATE** — Document edits must preserve intent and accuracy. Do NOT remove or contradict existing content without understanding why it was written. Check git history for context.

## Process

1. First, divide the document into sections based on its headings. Think about the main points made in each section.

Consider that information is a directed acyclic graph, and that pieces of information can depend on other pieces of information. Make sure that the order of the sections and their contents respects these dependencies.

Confirm the sections with the user.

2. For each section:

2a. Rewrite the section to improve clarity, coherence, and flow. Use maximum 240 characters per paragraph.
