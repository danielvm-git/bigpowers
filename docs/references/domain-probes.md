# Domain Probes: Grill-Me Questions for Each Domain

**Purpose:** Provide domain-specific probing questions for the grill-me skill during Discover and Elaborate phases.

---

## Web Applications

### Data Storage & Persistence
- What's the expected data volume? (KB, MB, GB, TB?)
- What's the query pattern? (Read-heavy? Write-heavy? Balanced?)
- What's the retention policy? (Keep forever? Archive after N days?)
- Do you need transactions? Multi-record consistency?
- What's the backup/recovery RTO/RPO?

### User Authentication & Authorization
- How many users? (1K, 1M, 1B?)
- Do users have roles? What's the permission model?
- Should users be able to delegate permissions?
- What's the session timeout?
- Do you need multi-factor authentication?

### Performance & Scalability
- What's the expected QPS (queries per second)?
- What's the acceptable latency? (p50, p95, p99?)
- Should the system auto-scale?
- How much traffic variance? (10x peak vs. baseline?)
- Do you cache? What's the cache invalidation strategy?

### Deployment & Operations
- Where does it run? (Cloud, on-prem, hybrid?)
- What's the deployment frequency? (Daily, weekly, monthly?)
- How do you handle rolling updates? (Blue-green, canary, immediate?)
- What's the monitoring/alerting strategy?
- Do you need disaster recovery? Cross-region failover?

---

## Data Pipelines

### Data Flow
- What's the data source? (API, database, files, streams?)
- What's the destination? (Data warehouse, ML model, dashboard?)
- What's the frequency? (Real-time, hourly, daily, batch?)
- How much data? (GB, TB, PB per day?)
- What transformations? (Aggregation, enrichment, filtering?)

### Data Quality
- How do you detect data issues? (Schema validation, thresholds?)
- What's the SLA for data freshness?
- How do you handle missing values? (Imputation, skip, error?)
- Do you version historical data?

### Failure Handling
- What happens if the source fails? (Retry? Skip? Fail loudly?)
- What happens if transformation fails? (Quarantine? Alert?)
- How do you backfill missing data?
- What's the recovery time objective (RTO)?

---

## ML Models

### Model Training
- How much training data? (100s, 1000s, millions of examples?)
- How long does training take? (Minutes, hours, days?)
- How often do you retrain? (Daily, weekly, on-demand?)
- How do you prevent overfitting? (Regularization? Validation set?)
- What's the acceptable error rate?

### Model Deployment
- How do you A/B test new models?
- How do you rollback a bad model?
- What's the latency requirement? (ms, seconds, batch?)
- How do you monitor model drift?
- Do you need explanations for predictions?

### Data & Privacy
- What's the sensitivity of training data? (PII, medical, financial?)
- How do you handle data retention? (Delete after N days?)
- Do you need differential privacy?
- Is the model subject to GDPR/CCPA?

---

## Mobile Applications

### Platform & Devices
- Which platforms? (iOS, Android, both?)
- What's the minimum OS version? (Affects features, market size)
- Do you support tablets?
- Should the app work offline?
- How much storage? (MB limits?)

### Network
- What's the connection assumption? (4G? WiFi? Slow 2G?)
- Can the app resume after connection loss?
- What size are the requests/responses? (Bytes vs. KB?)
- Do you sync in background?

### User Experience
- What's the expected session length? (Minutes, hours?)
- How often do users update the app?
- Do you need push notifications?
- Should data be local or remote?

---

## APIs

### Interface Design
- What's the API style? (REST, GraphQL, gRPC, WebSocket?)
- What's the versioning strategy? (URL path, header, separate endpoint?)
- What's the response format? (JSON, XML, protobuf?)
- Do you support pagination? Filtering? Sorting?

### Authentication & Security
- How do you authenticate? (API key, OAuth, JWT?)
- Do you rate-limit? Per user, IP, or global?
- Do you need encryption in transit/at rest?
- How do you handle secrets? (Rotation policy?)

### Reliability
- What's the SLA uptime? (99%, 99.9%, 99.99%?)
- How do you version the API?
- How do you deprecate endpoints? (Sunset period?)
- Do you have backwards compatibility requirements?

---

## Infrastructure & DevOps

### Deployment
- What's the target environment? (Kubernetes, Lambda, VMs?)
- Do you use containers? (Docker? Image size limits?)
- How do you manage secrets? (Vault, parameter store?)
- How do you do configuration management?

### Monitoring & Alerting
- What metrics do you track? (CPU, memory, disk, custom?)
- What's the alert threshold? (When should ops page be triggered?)
- How do you correlate logs across services?
- Do you use distributed tracing?

### Disaster Recovery
- What's the RPO (Recovery Point Objective)? (Data loss tolerance?)
- What's the RTO (Recovery Time Objective)? (Downtime tolerance?)
- Do you test recovery procedures? How often?
- Do you replicate across regions?

---

## Using Domain Probes in Grill-Me

**Workflow:**

1. **User says:** "Build me a web app"
2. **Grill-me checks domain:** Web Applications
3. **Grill-me asks probes from relevant sections:**
   - "What's the expected data volume?"
   - "How many users?"
   - "What's the acceptable latency?"
4. **User answers:** Builds up context
5. **Grill-me locks decisions:** "So we're targeting 1K users, <500ms latency, 1GB data. Correct?"

---

## See Also

- grill-me (SKILL.md) — How to ask questions
- elaborate-spec (SKILL.md) — Design decisions based on answers
- orchestration.md — When does grill-me happen? (Discover, Elaborate)
- verify: cd /Users/danielvm/Developer/skills && grep -c "What\|How" docs/references/domain-probes.md
