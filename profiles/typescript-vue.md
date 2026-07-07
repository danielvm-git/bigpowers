# Stack Profile: TypeScript + Vue

Opt-in conventions fragment for `seed-conventions`.

## Commands

| Action | Command |
|--------|---------|
| Test | `npm run test` or `vitest run` |
| Lint | `npm run lint` |
| Build | `npm run build` |
| Dev | `npm run dev` |

## Architecture

- Vue 3 Composition API + `<script setup>`
- Pinia for shared state; composables for reusable logic

## Conventions

- SFC order: `<script setup>` → `<template>` → `<style scoped>`
- Prettier for format; named exports in composables
- Vitest for unit tests; Vue Test Utils for components

## Never

- Never use Options API for new components unless extending legacy
- Never commit `dist/`, `node_modules/`, `.env`


<!-- story: e10s01 -->
