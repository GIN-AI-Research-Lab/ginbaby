# -*- coding: utf-8 -*-
"""Chuyển README sang hướng hồ sơ tài trợ nghiên cứu (bỏ Premium và mô hình kinh doanh), nhúng GIF demo."""
import io
import re

p = r'F:\Project Ai\GinBaby\README.md'
s = io.open(p, encoding='utf-8').read()


def rep(a, b):
    global s
    assert a in s, a[:80]
    s = s.replace(a, b, 1)


rep("![Ads](https://img.shields.io/badge/ads-none-9B7CF0)",
    "![Ads](https://img.shields.io/badge/ads-none-9B7CF0)\n![Focus](https://img.shields.io/badge/focus-maternal%20%26%20child%20health%20research-E5666F)")
rep("## The pitch in 30 seconds", "## Summary")
rep("**GinBaby** is a mobile-first parenting companion", "**GinBaby** is a research prototype of a mobile-first parenting companion")
rep("> **Status:** working product, installable today as a Progressive Web App on iPhone/Android, ~15.6k lines of Dart, 97 automated tests, 30+ features across 7 areas. Native iOS build, family sync, and an AI assistant are the next funded milestones (see [Roadmap](#roadmap-and-use-of-funds)).",
    "> **Status:** working prototype, installable today as a Progressive Web App on iPhone/Android, ~15.6k lines of Dart, 97 automated tests, 30+ features across 7 areas. It is the platform for the research programme described below: clinician-validated content, a pilot study with parents, family sync, and a safe, grounded AI assistant (see [Research programme](#research-programme) and [Roadmap](#roadmap-and-use-of-funds)).\n>\n> **Not a commercial product.** The app is free, ad-free and collects no personal data. This repository is the basis of a research and public-health project.")
rep("- **Trust is the opening.** Parents are actively looking for alternatives to apps that lag, lose data, or monetise attention. \"No ads, your data stays on your phone\" is a real differentiator.",
    "- **Trust is the opening.** Parents are actively looking for alternatives to apps that lag, lose data, or monetise attention. \"No ads, your data stays on your phone\" is a real differentiator, and it makes ethical research data collection (opt-in, aggregate, consented) possible.")

rep("</div>\n\n---\n\n## Summary",
    "</div>\n\n<div align=\"center\">\n\n### See it in action\n\n<img src=\"docs/demo/demo.gif\" alt=\"GinBaby demo: log a bottle by dragging the milk level, browse the Utilities hub, switch to dark mode and view insights\" width=\"280\" />\n\n<sub>Drag-to-fill bottle with instant age-aware guidance, then the Utilities hub, dark mode and weekly insights. &nbsp;·&nbsp; <a href=\"docs/demo/demo.mp4\">Download MP4</a></sub>\n\n</div>\n\n---\n\n## Summary")

a = s.index("## Business model")
b = s.index("## Roadmap and use of funds")
research = """## Research programme

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

"""
s = s[:a] + research + s[b:]

rep("| **M4 — Native iOS + trust** | App Store / TestFlight release, widgets and Live Activities, Siri shortcuts, **clinician review of all health content**, EPDS translation validation | ⏳ Next |",
    "| **M4 — Native iOS + clinical review** | Native iOS build for study participants (TestFlight), widgets and Siri shortcuts, **clinician review of all health content**, EPDS translation validation | ⏳ Next |")
rep("| **M5 — Family sync** | End-to-end encrypted sync between parents' devices | ⏳ Next |",
    "| **M5 — Pilot study + family sync** | Pilot with parents (RQ1, RQ5); end-to-end encrypted sync between parents' devices | ⏳ Next |")
rep("| **M6 — Gin AI assistant + voice** | Grounded assistant, voice-to-log, predictive insights | 🗓 Planned |",
    "| **M6 — Grounded AI assistant + voice** | Retrieval-grounded assistant and evaluation set (RQ4), voice-to-log, predictive insights | 🗓 Planned |")
rep("| **M7 — Regional expansion** | Localisation for Indonesia, Thailand, Philippines; Android | 🗓 Planned |",
    "| **M7 — Open release and regional adaptation** | Open resources, localisation for other Southeast-Asian languages; Android | 🗓 Planned |")

a = s.index("**Proposed use of funds**")
b = s.index("---\n\n## Health content policy")
funds = """**Proposed use of funds** *(indicative, to be tailored to the programme)*:

| Area | Share | Why |
|---|---|---|
| Clinical advisory and content validation | ~25% | Paediatrician and lactation-consultant review; validated EPDS translation |
| Pilot study and user research | ~25% | Recruitment, interviews, instruments, ethics approval, data analysis |
| Native iOS/Android build and device QA | ~20% | Smooth 120 Hz experience, widgets, Siri, notifications for study participants |
| AI assistant: retrieval, evaluation sets, safety red-teaming | ~15% | RQ4: grounded, cited, safe answers in Vietnamese |
| Family-sync backend and security review | ~10% | End-to-end encryption without breaking the local-first promise |
| Open-science release, documentation, legal and privacy compliance | ~5% | Reusable datasets and guidance; compliance from day one |

"""
s = s[:a] + funds + s[b:]

rep("| **Gin — AI parenting assistant** | 🗓 Planned | Retrieval-augmented answers **grounded in the app's cited, clinician-reviewed content**, personalised with the baby's own logs, with medical safety guardrails, red-flag escalation and no diagnosis. |",
    "| **Gin — grounded AI assistant** | 🗓 Planned (RQ4) | Retrieval-augmented answers **grounded in the app's cited, clinician-reviewed content**, personalised with the baby's own logs, with safety guardrails, red-flag escalation and no diagnosis. |")
rep("Investors, grant programmes, paediatric advisors and clinic partners are welcome to open an issue or reach out through GitHub. A live demo build is available on request.",
    "Research funders, paediatric and lactation advisors, universities and clinic partners are welcome to open an issue or reach out through GitHub. A live demo build is available on request.")
rep("<sub>© 2026 GinBaby. All rights reserved. Illustrations are AI-generated and owned by the project. Health information is for general reference only and is not a substitute for professional medical advice.</sub>",
    "<sub>© 2026 GinBaby project. All rights reserved. Illustrations are AI-generated for this project. Health information is for general reference only and is not a substitute for professional medical advice.</sub>")

io.open(p, 'w', encoding='utf-8').write(s)
hits = [m.group(0) for m in re.finditer('(?i)premium|subscription|business model|revenue|freemium', s)]
print('remaining commercial words:', hits)
