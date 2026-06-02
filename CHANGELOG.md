## [1.3.2](https://github.com/danielvm-git/bigpowers/compare/v1.3.1...v1.3.2) (2026-06-02)


### Bug Fixes

* **ci:** guard sync-skills description and manifest version ([f1d5ac3](https://github.com/danielvm-git/bigpowers/commit/f1d5ac35c2fe543aa5b65ab8cb6e929476e357e3))

## [1.3.1](https://github.com/danielvm-git/bigpowers/compare/v1.3.0...v1.3.1) (2026-06-02)


### Bug Fixes

* **ci:** repair sync-skills sed and refresh package-lock ([29d6e7c](https://github.com/danielvm-git/bigpowers/commit/29d6e7cee82ab25eae5188628d1ae2bc73c99e57))
* **ci:** use Node 22 for semantic-release workflow ([43edf78](https://github.com/danielvm-git/bigpowers/commit/43edf7801ef06714861e16ed833e6b8b4c3eb66c))

# [1.3.0](https://github.com/danielvm-git/bigpowers/compare/v1.2.3...v1.3.0) (2026-06-02)


### Features

* **specs:** complete YAML cockpit cohesion migration ([0a3cf16](https://github.com/danielvm-git/bigpowers/commit/0a3cf16b8030ef6b87ad5113b15265c76ea012c5))

## [1.2.3](https://github.com/danielvm-git/bigpowers/compare/v1.2.2...v1.2.3) (2026-05-31)


### Bug Fixes

* **ci:** portable SKILL-SEARCH-INDEX generation for Linux runners ([da6db2c](https://github.com/danielvm-git/bigpowers/commit/da6db2c500a8b5562f458fbbc9a4d5b071843c0d))

## [1.2.2](https://github.com/danielvm-git/bigpowers/compare/v1.2.1...v1.2.2) (2026-05-31)


### Bug Fixes

* **ci:** deterministic sync verify and release artifact hooks ([9370e35](https://github.com/danielvm-git/bigpowers/commit/9370e351a5b1f290de4297919d4d547bd9f64a27))

## [1.2.1](https://github.com/danielvm-git/bigpowers/compare/v1.2.0...v1.2.1) (2026-05-31)


### Bug Fixes

* **ci:** verify sync artifacts instead of bot push to main ([663e226](https://github.com/danielvm-git/bigpowers/commit/663e22627eaa5b759a8d057fca634e5408dbb331))

# [1.2.0](https://github.com/danielvm-git/bigpowers/compare/v1.1.2...v1.2.0) (2026-05-31)


### Features

* **maintain-wiki:** add LLM wiki layer and Obsidian cockpit profile ([d2e2c5b](https://github.com/danielvm-git/bigpowers/commit/d2e2c5b3d29a68b5dabf83e484778fd44290d69b))

## [1.1.2](https://github.com/danielvm-git/bigpowers/compare/v1.1.1...v1.1.2) (2026-05-31)


### Bug Fixes

* **ci:** add contents:write permission and bump checkout to v4 in sync workflow ([f684bcd](https://github.com/danielvm-git/bigpowers/commit/f684bcd4b3ef5b8e3a206c43d79b56463a8acae7))

## [1.1.1](https://github.com/danielvm-git/bigpowers/compare/v1.1.0...v1.1.1) (2026-05-31)


### Bug Fixes

* **scripts:** exit 0 to prevent false failure when OPN_TARGET is unset ([76bffd8](https://github.com/danielvm-git/bigpowers/commit/76bffd8cb7dd58f1e1e620017857d5491f10399e))

# [1.1.0](https://github.com/danielvm-git/bigpowers/compare/v1.0.0...v1.1.0) (2026-05-31)


### Bug Fixes

* **ci:** pass NODE_AUTH_TOKEN for setup-node npmrc auth ([03d58ee](https://github.com/danielvm-git/bigpowers/commit/03d58ee1c9a6b4f7c6c34f822f98363e1493f93e))


### Features

* **skills:** add and update a large number of skills ([a51d802](https://github.com/danielvm-git/bigpowers/commit/a51d802ccb1ebcd327e6ff7ef9d7e1471d62ca8e))
* **skills:** add Project README artifact type to write-document ([43f9f84](https://github.com/danielvm-git/bigpowers/commit/43f9f8473f221374ba8bfe326f8bf604cc213d7e))
* **workflow:** add solo git profile with land-branch.sh ([1840cd0](https://github.com/danielvm-git/bigpowers/commit/1840cd0011fc522825b72bb10a3f8d16886d902e))

# 1.0.0 (2026-05-23)


### Bug Fixes

* align Gemini CLI extension with v0.42.0 requirements ([6f2b7a4](https://github.com/danielvm-git/bigpowers/commit/6f2b7a4e91727d21c980c2b7f733810b50592f23))
* **arch:** harden karpathy gates, token economy, and architecture mandates ([300981d](https://github.com/danielvm-git/bigpowers/commit/300981d1f892a4ecf36bc94475c3a03b5529feb6))
* **ci:** point semantic-release at correct GitHub repository ([ee17aba](https://github.com/danielvm-git/bigpowers/commit/ee17abae150c0779aabf0c12e188919f8fbf6441))
* **commit:** refine release mapping to match semantic-release defaults ([#9](https://github.com/danielvm-git/bigpowers/issues/9)) ([1c536e5](https://github.com/danielvm-git/bigpowers/commit/1c536e53f0ddef340025f6aa5cf9a62bd13cdfee))
* **execute-plan, plan-work:** replace PLAN.md with RELEASE-PLAN.md ([d125789](https://github.com/danielvm-git/bigpowers/commit/d1257895679e4cb241ae7db5e0c9d62861a5a193))
* **git:** enforce feature branching gates across all skills ([454b64a](https://github.com/danielvm-git/bigpowers/commit/454b64af33df9799c29594e5f6df879ae82199da))
* **hooks:** harden CC regex to prevent 'type/' typos ([#10](https://github.com/danielvm-git/bigpowers/issues/10)) ([ff13689](https://github.com/danielvm-git/bigpowers/commit/ff1368999f02c813b77a3a3362407efdccb3097c))
* **karpathy.feature:** correct formatting and remove extraneous text from compliance feature ([4390ef0](https://github.com/danielvm-git/bigpowers/commit/4390ef0ecc7fc7b22bc3f5bb240657a9d61c1f82))
* **skills:** rename to fix-report and try to trigger discovery ([7a83eb7](https://github.com/danielvm-git/bigpowers/commit/7a83eb7206a521edf693c40bb04054fc3be15e6b))
* **skills:** simplify description and remove from lock for auto-discovery ([b698a58](https://github.com/danielvm-git/bigpowers/commit/b698a584d9e7f2540cbb6464e1db5841674e95ca))


### Features

* add automated bootstrap, visual dashboard, and global hook configuration ([a708e63](https://github.com/danielvm-git/bigpowers/commit/a708e63d79b96ec7cff14c2519bdab985d8f76a1))
* add local installation script and project-specific lockfile support ([d49d107](https://github.com/danielvm-git/bigpowers/commit/d49d107c92258a890510ca08fe7295fcc60a5674))
* add prepare-semantic-commit skill ([59ffddc](https://github.com/danielvm-git/bigpowers/commit/59ffddc877c80a8aa00d0d851a795011db0efa89))
* **agent:** add stream continuity guards to prevent idle timeouts ([#14](https://github.com/danielvm-git/bigpowers/issues/14)) ([977c388](https://github.com/danielvm-git/bigpowers/commit/977c388d32c13c98eaf055438892e371342aa913))
* **audit:** implement agentic gherkin compliance harness ([#2](https://github.com/danielvm-git/bigpowers/issues/2)) ([e4e8dec](https://github.com/danielvm-git/bigpowers/commit/e4e8decd9a90b432470ca74fa6182559ffe71dd3))
* **audit:** implement evidence scripts ([bd9006e](https://github.com/danielvm-git/bigpowers/commit/bd9006e3ef0583f0668ff8c8188dbe7456602572))
* **commit:** add advanced CC patterns and verification gate ([#7](https://github.com/danielvm-git/bigpowers/issues/7)) ([adc9552](https://github.com/danielvm-git/bigpowers/commit/adc955204aa219a181eced8a84a6c2a3fd7f08a4))
* **compliance:** enforce Conventional Commits and SemVer in CONVENTIONS.md ([e590955](https://github.com/danielvm-git/bigpowers/commit/e590955fda914061ed2d4bf4387682d36497fd91))
* **compliance:** restore lifecycle discipline and retroactive plans ([281254c](https://github.com/danielvm-git/bigpowers/commit/281254c8adef239d3f4022a318410f2bececadfb))
* **core:** add initial project structure and configuration ([5a1feab](https://github.com/danielvm-git/bigpowers/commit/5a1feabc2060061cf0690c382edd6441427405ea))
* **develop-tdd:** bake 'Commit-on-Green' requirement into the TDD loop ([8cbeec6](https://github.com/danielvm-git/bigpowers/commit/8cbeec66972b5651ad08a1d96a319aec53083543))
* **guard:** implement PreToolUse hook for Conventional Commits & main-branch protection ([7ffda7c](https://github.com/danielvm-git/bigpowers/commit/7ffda7c2a2199b46372c5447079517814bf9597a))
* **kickoff:** harden git-worktree lifecycle and automated cleanup ([8082213](https://github.com/danielvm-git/bigpowers/commit/808221382d99240c71cb5a93da8e968c0778fe06))
* **opencode:** automate opencode.json and AGENTS.md generation ([#13](https://github.com/danielvm-git/bigpowers/issues/13)) ([598e177](https://github.com/danielvm-git/bigpowers/commit/598e177cb345ad450ac237ab08d8986ff850699a))
* refactor to bigpowers — 38 spec-driven lifecycle skills ([f0d37af](https://github.com/danielvm-git/bigpowers/commit/f0d37afbd3c3b1ffe26bc434dc5ca79befd7add2))
* **release:** align with semantic-release and semver ([#8](https://github.com/danielvm-git/bigpowers/issues/8)) ([9836881](https://github.com/danielvm-git/bigpowers/commit/9836881e7089d10498097e9ff29fae4c7928056b))
* **session-state:** implement git metadata sync and finalize v1.9.0 plan ([e114514](https://github.com/danielvm-git/bigpowers/commit/e1145149dea152310568fc435a27b9d88c2fd43a))
* **skill:** add write-document with BMAD principles and context circuit breakers ([548c2bd](https://github.com/danielvm-git/bigpowers/commit/548c2bdda214b67585af36deedbc46dc7e1b3954))
* **skills:** add fix-and-report skill ([c3f624b](https://github.com/danielvm-git/bigpowers/commit/c3f624bd73be261fd5b876ab18c95af11e8e5e95))
* **skills:** add stream continuity guards to output-heavy skills ([#11](https://github.com/danielvm-git/bigpowers/issues/11)) ([8c7a823](https://github.com/danielvm-git/bigpowers/commit/8c7a823885560ac141e7643e86480c4703775fd7))
* **skills:** add test-skill to debug discovery ([acbf545](https://github.com/danielvm-git/bigpowers/commit/acbf5450e8ea274ca70ce92410b7b999df3ae7e8))
* **skills:** consolidate redundant skills and add release planning chain ([#3](https://github.com/danielvm-git/bigpowers/issues/3)) ([40825e3](https://github.com/danielvm-git/bigpowers/commit/40825e340a95f8b0fee7fdcc1ca3da0bfbdd2b6c))
* **skills:** implement HARD-GATE callout blocks for critical execution points ([31bed65](https://github.com/danielvm-git/bigpowers/commit/31bed65b5cfb55dccbd6eb57461377fcefddc7ea))
* **skills:** introduce Discovery Mandate, Visual Slices, and The Gatekeeper guardrails ([1106f6a](https://github.com/danielvm-git/bigpowers/commit/1106f6ae9b0544e7e98dcbef593fece4c9d6a295))
* **skills:** optimize fix-report skill for agent performance ([a9cae87](https://github.com/danielvm-git/bigpowers/commit/a9cae87d92d41f7c8d460873ad4e8344f259330a))
* **skills:** register fix-and-report in manifest and README ([b9ebdb1](https://github.com/danielvm-git/bigpowers/commit/b9ebdb1e53d026bb50cf4182267bc4fc4697a690))
* **survey:** introduce map-codebase skill for high-fidelity surveying ([6d26e2f](https://github.com/danielvm-git/bigpowers/commit/6d26e2f5d438f6119a9ae8bf0666aeaf90a81e6d))
* update .gitignore and enhance README for clarity on agent skills ([fa21c8c](https://github.com/danielvm-git/bigpowers/commit/fa21c8cdc6bdb3a787e89d84c01ed4dbd8422e97))
* **utility:** introduce session-state and harden process gates ([8fa8524](https://github.com/danielvm-git/bigpowers/commit/8fa85248eba2a6c0c1d95566dc5883fe60f24458))
* **v1.12.0:** harden compliance harness and remediate Clean Code Chapter 17 ([09a5429](https://github.com/danielvm-git/bigpowers/commit/09a5429d9ac57157240fedf8e829044efeb8c9c1))
* **v1.12.1:** harden CONVENTIONS.md with 10 missing Clean Code heuristics ([#4](https://github.com/danielvm-git/bigpowers/issues/4)) ([a6bf36a](https://github.com/danielvm-git/bigpowers/commit/a6bf36a291fe0b005988ca8d72577da0f08d5649))
* **v1.13.0:** add harness falsification suite and npm run compliance ([#5](https://github.com/danielvm-git/bigpowers/issues/5)) ([501e98b](https://github.com/danielvm-git/bigpowers/commit/501e98b4d67e270c19c04a57c72380b2f44fb64f))
* **v1.14.0:** add Karpathy behavioral mandates and evidence scripts ([6207082](https://github.com/danielvm-git/bigpowers/commit/6207082340f3f2c9b42422db85538f7fed3ad182))
* **v1.14.0:** add Karpathy behavioral mandates to planning and execution skills ([42b1456](https://github.com/danielvm-git/bigpowers/commit/42b1456fc9d1498326924b45da363119faecfb9b))
* **v1.15.0:** add Superpowers gates and evidence scripts ([3cdd81a](https://github.com/danielvm-git/bigpowers/commit/3cdd81abb27433aea77b1cf3b5b03657eb2c7b22))
* **v1.16.0:** add testing mandates and evidence scripts ([ba7d054](https://github.com/danielvm-git/bigpowers/commit/ba7d054d9724b0866c0279fa8992061a451d2212))
* **v1.17.0:** add guardrails - zoom-out mandate and surgical-changes discipline ([c2ee71b](https://github.com/danielvm-git/bigpowers/commit/c2ee71bd92d23ea072e6579c2462681287f2a39a))
* **v1.18.0:** wire decision logging and minimal brief discipline into execution loop ([9619068](https://github.com/danielvm-git/bigpowers/commit/9619068e0fea068572b5c84d404e42bae64d639a))
* **v2.0.0:** add reference library and orchestrate skill ([bc9b437](https://github.com/danielvm-git/bigpowers/commit/bc9b43767ed8087c8ee53de09be6ba8f0031c26c))
* **v2.0.0:** complete orchestration framework and reference library ([a303c64](https://github.com/danielvm-git/bigpowers/commit/a303c64e8abfc6074f767b40938717120ad7763d))
* **workflow:** implement verification-first loop and remove AI attribution ([#15](https://github.com/danielvm-git/bigpowers/issues/15)) ([8286ef3](https://github.com/danielvm-git/bigpowers/commit/8286ef32d6104be06f0af75d53247790594e8f3d))
* **workflow:** mandate bigpowers skill usage and prevent direct coding ([ebf539e](https://github.com/danielvm-git/bigpowers/commit/ebf539e928512ab6f97fb958961e1a8b424acc50))
