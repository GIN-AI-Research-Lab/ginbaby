<div align="center">

<img src="docs/assets/icon.png" alt="GinBaby" width="112" />

# GinBaby

**A calm, private, evidence-informed companion for new parents — built Vietnamese-first.**

Feeding · Pumping · Sleep · Diapers · Vaccines · Growth · Postpartum mental health · Milestones · Family money

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/platform-PWA%20%7C%20iOS%20(planned)-E5666F)
![Offline first](https://img.shields.io/badge/offline--first-yes-4F8A6B)
![Tests](https://img.shields.io/badge/tests-97%20passing-4F8A6B)
![Ads](https://img.shields.io/badge/ads-none-9B7CF0)
![Focus](https://img.shields.io/badge/focus-maternal%20%26%20child%20health%20research-E5666F)

<img src="docs/screenshots/hero.jpg" alt="GinBaby screenshots in light and dark mode" width="100%" />

</div>

<div align="center">

### See it in action

<img src="docs/demo/demo.gif" alt="GinBaby demo: log a bottle by dragging the milk level, browse the Utilities hub, switch to dark mode and view insights" width="280" />

<sub>Drag-to-fill bottle with instant age-aware guidance, then the Utilities hub, dark mode and weekly insights. &nbsp;·&nbsp; <a href="docs/demo/demo.mp4">Download MP4</a></sub>

</div>

---

## Summary

New parents track dozens of small, repetitive events every day — every feed, every pump session, every nap, every diaper — usually at 3 a.m., one-handed, while sleep-deprived. The tools they have are either **cluttered and ad-driven**, **English-centric**, **cloud-account-first** (privacy and trust problems), or **laggy**.

**GinBaby** is a research prototype of a mobile-first parenting companion that makes logging take seconds and turns the logs into calm, age-appropriate guidance: *"Is my baby drinking enough? When is the next nap? Is this stool colour okay? Is Mum okay?"*

It is **offline-first and private by design** (data stays on the device, no account, no ads), it covers the **pumping mother** — the most under-served segment of existing apps — and it is **localised for Vietnam** (national immunisation schedule, Vietnamese-language UX, family finance patterns such as gold savings and lucky-money gifts).

> **Status:** working prototype, installable today as a Progressive Web App on iPhone/Android, ~15.6k lines of Dart, 97 automated tests, 30+ features across 7 areas. It is the platform for the research programme described below: clinician-validated content, a pilot study with parents, family sync, and a safe, grounded AI assistant (see [Research programme](#research-programme) and [Roadmap](#roadmap-and-use-of-funds)).
>
> **Not a commercial product.** The app is free, ad-free and collects no personal data. This repository is the basis of a research and public-health project.

---

## Why now

- **Large, recurring market.** Vietnam has roughly **1.5 million births a year**, and Southeast Asia several million more. Every family is a new user for ~24 months of intensive use.
- **Smartphone-native parents.** Parents already live in their phone at 3 a.m.; they want one fast, trustworthy tool, not five.
- **Trust is the opening.** Parents are actively looking for alternatives to apps that lag, lose data, or monetise attention. "No ads, your data stays on your phone" is a real differentiator, and it makes ethical research data collection (opt-in, aggregate, consented) possible.
- **Maternal mental health is under-addressed.** WHO estimates that roughly 1 in 8 women worldwide experience a mental health condition after childbirth, with higher rates in lower-income countries. A parenting app is a natural, stigma-free place for screening and support.
- **Generative AI changes unit economics** for content, illustration, and (next) conversational guidance — if built with strong medical guardrails.

---

## What makes GinBaby different

### 1. Built for the pumping mother
Most apps treat pumping as an afterthought. GinBaby has a dedicated pumping flow: **dual-side timer**, per-side volume, daily session schedule with reminders, a **daily output target**, and a **milk stash** (fridge / freezer, storage windows based on CDC guidance, first-in-first-out use, waste tracking when a bottle is not finished). Total daily milk **includes estimated direct breastfeeding**, so a combination-feeding mother sees one honest number.

### 2. Drag-to-fill milk bottle
Logging a bottle is a gesture, not a form: **drag the milk level on a realistic animated bottle** (haptic snap at 10 ml marks). The app instantly shows whether the amount fits the baby's age and weight, citing its reference (AAP guidance; Kent et al. 2006 on breast-milk intake).

### 3. EASY routine engine
An adaptive **Eat-Activity-Sleep-Your-time** schedule (E2.5 → E4, auto-selected by age) predicts the next nap window, shows today's rhythm, and nudges gently — rule-based, transparent, and editable.

### 4. Stool diary with red-flag guidance
Colour, texture and amount selectors with **photo attachments** and a built-in explainer of which colours are normal and which need a doctor's visit (e.g. pale/white, red, black stools). Designed so a parent can show the diary to a paediatrician.

### 5. Postpartum mental-health companion
A mood diary, **EPDS (Edinburgh Postnatal Depression Scale) self-screening**, and guided breathing exercises, with clear "this is screening, not diagnosis — talk to a professional" framing. *(The Vietnamese EPDS translation is a reference translation pending clinical validation; see [Health content policy](#health-content-policy).)*

### 6. Milestone journal and shareable memory cards
Cultural milestones (**full-month, 100-day, first-birthday**) plus 14 "firsts" and custom moments, each with photo, date and note. One tap produces a **watercolour memory card** sized for sharing — a built-in organic growth loop.

### 7. Family money and the child's fund
A baby-expense ledger (tags, SKU/barcode field, quantity × unit price, receipts as photos, monthly budget alerts) **plus a "child's fund"** that tracks cash, savings accounts, **gold** and other assets with goals and a savings jar — reflecting how Vietnamese families actually save for children.

### 8. Vietnam-first health content
National **Expanded Programme on Immunization (TCMR) + optional paid-vaccine schedule** with overdue tracking, **WHO 2006 growth standards** (weight / length / head circumference, percentile bands), solids introduction with allergen tracking, 14 sourced care articles, and a Wonder Weeks calendar with an honest note on limited scientific evidence.

### 9. Calm, fast, delightful UI
A consistent **hand-painted watercolour design system**, light and dark themes (soft-purple dusk palette), optional iOS-style frosted glass, press effects and swipe-back navigation modelled on iOS, accessible text sizing, and **press-to-log in ≤ 3 taps** for the core flows.

### 10. Privacy and reliability as product features
- **Local-first**: all data stays on the device (IndexedDB); **no account, no ads, no tracking**.
- **True offline**: a custom service worker caches the entire app (≈35 MB) on first launch with a visible progress bar, updates incrementally via file hashes, and runs without a connection.
- **One-tap full backup/restore** (JSON, including photos) and doctor-ready report / CSV export.

---

## AI and automation

Being precise about what is shipped versus planned:

| | Status | Details |
|---|---|---|
| **AI-generated illustration pipeline** | ✅ Shipped | The whole watercolour icon and illustration set (~50 assets) was generated with **Google Gemini on Vertex AI**, then post-processed automatically (background removal, edge defringing, saturation boost, **auto-generated dark-mode variants**). The pipeline is reproducible from this repo (`design/tool/`). |
| **Smart insights (rule-based)** | ✅ Shipped | Intake adequacy by age/weight, next-nap prediction from the EASY engine, week-over-week trend callouts, auto-written weekly recap card. Transparent logic with cited references — no black box. |
| **Voice-to-log ("Hey Siri, log 120 ml")** | 🛠 Designed | Mothers define their own spoken phrases ("bottle + number", "pump left + number", with relative times). A Vietnamese phrase parser fills the log automatically; works hands-free via iOS Shortcuts / Google Assistant routines. |
| **Gin — grounded AI assistant** | 🗓 Planned (RQ4) | Retrieval-augmented answers **grounded in the app's cited, clinician-reviewed content**, personalised with the baby's own logs, with safety guardrails, red-flag escalation and no diagnosis. |
| **Photo-assisted stool-colour triage** | 🗓 Planned (needs clinical review) | On-device colour analysis of the diaper photo to help parents spot red-flag colours earlier. |
| **Predictive feed / sleep** | 🗓 Planned | Personalised on-device models once enough baby-specific history exists. |

---

## Screens

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/home.jpg" width="200"/><br/><sub><b>Today</b><br/>quick-log tiles, reminders</sub></td>
    <td align="center"><img src="docs/screenshots/bottle.jpg" width="200"/><br/><sub><b>Drag-to-fill bottle</b><br/>age-aware guidance</sub></td>
    <td align="center"><img src="docs/screenshots/pump.jpg" width="200"/><br/><sub><b>Pumping</b><br/>dual-side timer</sub></td>
    <td align="center"><img src="docs/screenshots/milk-stash.jpg" width="200"/><br/><sub><b>Milk stash</b><br/>expiry, FIFO</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/diaper.jpg" width="200"/><br/><sub><b>Stool diary</b><br/>colour, texture, flags</sub></td>
    <td align="center"><img src="docs/screenshots/easy.jpg" width="200"/><br/><sub><b>EASY rhythm</b><br/>next-nap prediction</sub></td>
    <td align="center"><img src="docs/screenshots/stats.jpg" width="200"/><br/><sub><b>Insights</b><br/>day / week / month</sub></td>
    <td align="center"><img src="docs/screenshots/history.jpg" width="200"/><br/><sub><b>Timeline</b><br/>filter and search</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/vaccine.jpg" width="200"/><br/><sub><b>Vaccination</b><br/>national schedule</sub></td>
    <td align="center"><img src="docs/screenshots/growth.jpg" width="200"/><br/><sub><b>WHO growth</b><br/>percentile bands</sub></td>
    <td align="center"><img src="docs/screenshots/leaps.jpg" width="200"/><br/><sub><b>Wonder Weeks</b><br/>with evidence note</sub></td>
    <td align="center"><img src="docs/screenshots/mind.jpg" width="200"/><br/><sub><b>Mum's corner</b><br/>mood, EPDS, breathing</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/milestones.jpg" width="200"/><br/><sub><b>Milestone journal</b><br/>full-month, 100-day…</sub></td>
    <td align="center"><img src="docs/screenshots/milestone-card.jpg" width="200"/><br/><sub><b>Memory card</b><br/>shareable</sub></td>
    <td align="center"><img src="docs/screenshots/money.jpg" width="200"/><br/><sub><b>Family money</b><br/>expenses and child's fund</sub></td>
    <td align="center"><img src="docs/screenshots/utilities.jpg" width="200"/><br/><sub><b>Utilities hub</b><br/>customisable menu</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/home-dark.jpg" width="200"/><br/><sub><b>Dark mode</b></sub></td>
    <td align="center"><img src="docs/screenshots/bottle-dark.jpg" width="200"/><br/><sub><b>Dark bottle</b></sub></td>
    <td align="center"><img src="docs/screenshots/stats-dark.jpg" width="200"/><br/><sub><b>Dark insights</b></sub></td>
    <td align="center"><img src="docs/screenshots/utilities-dark.jpg" width="200"/><br/><sub><b>Dark utilities</b></sub></td>
  </tr>
</table>

---

## Research programme

GinBaby is designed as an open, privacy-preserving platform for applied research in **maternal and child health, digital parenting support, and safe health-AI in a lower-resource language.**

### Proposed research questions

| # | Question | Approach |
|---|---|---|
| RQ1 | Does ultra-low-friction logging (≤ 3 taps, gesture input, voice) improve **logging adherence and parental confidence** in the first six months compared with form-based apps? | Pilot with ~100 mothers; opt-in aggregate usage data plus validated confidence scales |
| RQ2 | Can **rule-based, age-aware feeding and sleep guidance** reduce unnecessary parental worry while preserving timely escalation of red flags? | Clinician agreement study on guidance and red-flag rules; parent-reported outcomes |
| RQ3 | How well does a **Vietnamese EPDS translation** perform for postpartum screening, and does a mood diary plus guided breathing support help-seeking? | Linguistic and clinical validation of the translation; small mixed-methods study |
| RQ4 | Can a **retrieval-grounded assistant** answer common newborn questions safely in Vietnamese, with citations, calibrated uncertainty and reliable escalation? | Red-team and clinician-graded evaluation set; refuse-and-escalate benchmark |
| RQ5 | Does **offline-first, local-only design** increase trust and sustained use compared with cloud-first apps? | Qualitative interviews, retention analysis |

*These are proposed questions; no user study has been run yet.*

### Evaluation and ethics

- **No personal data leaves the device by default.** Any research data is collected only with explicit opt-in, de-identified and aggregated.
- Health content is **sourced and cited in-app** and reviewed by paediatricians and lactation consultants before each study.
- The app **never diagnoses**; it screens, informs and escalates (see [Health content policy](#health-content-policy)).
- Findings, evaluation sets and the Vietnamese-language guidance corpus are intended to be released as **open resources** where licences and ethics approvals allow.

### Expected impact

- A **free, ad-free tool** for families, with potential distribution through clinics, immunisation programmes and community health networks.
- A **validated Vietnamese-language resource set** (EPDS translation, guidance rules, red-flag lists) reusable by other researchers and public-health programmes.
- A **reproducible AI-assisted content pipeline** (illustration, localisation) that lowers the cost of building culturally adapted health tools.

---

## Roadmap and use of funds

| Milestone | Scope | Status |
|---|---|---|
| **M1 — Core logging + EASY** | Quick logs, bottle gesture, EASY engine, stool diary | ✅ Done (PWA) |
| **M2 — Milk stash + insights** | Pumping, stash, day/week/month analytics, shareable recap | ✅ Done (PWA) |
| **M3 — Health, knowledge, money** | Vaccines, WHO growth, solids, articles, mental-health corner, expenses + child's fund, milestone journal | ✅ Done (PWA) |
| **M4 — Native iOS + clinical review** | Native iOS build for study participants (TestFlight), widgets and Siri shortcuts, **clinician review of all health content**, EPDS translation validation | ⏳ Next |
| **M5 — Pilot study + family sync** | Pilot with parents (RQ1, RQ5); end-to-end encrypted sync between parents' devices | ⏳ Next |
| **M6 — Grounded AI assistant + voice** | Retrieval-grounded assistant and evaluation set (RQ4), voice-to-log, predictive insights | 🗓 Planned |
| **M7 — Open release and regional adaptation** | Open resources, localisation for other Southeast-Asian languages; Android | 🗓 Planned |

**Proposed use of funds** *(indicative, to be tailored to the programme)*:

| Area | Share | Why |
|---|---|---|
| Clinical advisory and content validation | ~25% | Paediatrician and lactation-consultant review; validated EPDS translation |
| Pilot study and user research | ~25% | Recruitment, interviews, instruments, ethics approval, data analysis |
| Native iOS/Android build and device QA | ~20% | Smooth 120 Hz experience, widgets, Siri, notifications for study participants |
| AI assistant: retrieval, evaluation sets, safety red-teaming | ~15% | RQ4: grounded, cited, safe answers in Vietnamese |
| Family-sync backend and security review | ~10% | End-to-end encryption without breaking the local-first promise |
| Open-science release, documentation, legal and privacy compliance | ~5% | Reusable datasets and guidance; compliance from day one |

---

## Health content policy

GinBaby is an **informational tool, not a medical device**. It never diagnoses. Every reference range is shown with its source (WHO, AAP, CDC, Kent et al., Edinburgh/Cox et al., Vietnamese national immunisation schedule). Content with limited evidence (e.g. Wonder Weeks) is labelled as such. **All health content is slated for clinician review before public release**, and the Vietnamese EPDS translation must be replaced with a validated version first.

---

## Tech overview

| Layer | Choice |
|---|---|
| Framework | **Flutter 3.47 / Dart 3** — one codebase for PWA today, iOS and Android next |
| State and storage | In-memory domain store + **sembast** (IndexedDB on web, file on mobile); photos stored locally; versioned JSON backup |
| Domain logic | Pure Dart, unit-tested (age, EASY, feeding/pump references, WHO LMS growth, vaccines, EPDS, leaps, stats, exports) |
| Offline | Custom **service worker** with hash-based incremental caching, first-run progress UI, install-as-app manifest |
| UI | Custom design system (watercolour art, light/dark palettes, optional frosted glass), iOS-style navigation and haptics |
| Quality | `flutter analyze` clean, **97 automated tests** including overflow smoke tests of every screen at 320 px / 125 % text with the real font |
| Art pipeline | Gemini (Vertex AI) generation → automatic cutout, defringe, dark-mode derivation (`design/tool/`) |

```
app/
  lib/core      design system, platform bridge, notifications, deep links
  lib/data      models, persistence, demo data
  lib/domain    pure logic: EASY, feeding & pumping references, WHO growth, vaccines, EPDS, milestones…
  lib/ui        screens
  web/          PWA shell, service worker, offline bridge
  test/         domain and per-screen tests
design/         icon prompts and image-generation / post-processing tools
docs/           roadmap, theme notes, screenshots
```

### Run it locally

```bash
cd app
flutter pub get
flutter run -d chrome      # development
flutter test               # 97 tests
flutter build web --release --no-web-resources-cdn
```

Useful deep links in a running web build: `/?go=feed`, `/?go=pump`, `/?go=diaper`, `/?go=vaccine`, `/?go=growth`, `/?go=memory`, `/?go=tab5` (Utilities hub).

Image tooling (optional) lives in `design/tool/` — see [`design/icons/PROMPTS.md`](design/icons/PROMPTS.md). It uses your own Google Cloud login (`GCP_PROJECT` environment variable); no keys are stored in the repository.

---

## Contact

Maintained by GitHub [@trituenguyen97](https://github.com/trituenguyen97).
Research funders, paediatric and lactation advisors, universities and clinic partners are welcome to open an issue or reach out through GitHub. A live demo build is available on request.

---

<sub>© 2026 GinBaby project. All rights reserved. Illustrations are AI-generated for this project. Health information is for general reference only and is not a substitute for professional medical advice.</sub>
