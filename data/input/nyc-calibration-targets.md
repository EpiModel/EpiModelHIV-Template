# NYC calibration targets — sourced values, derivations and caveats

Verification pass against primary NYC DOHMH sources for the 16 targets in the Atlanta
calibration spec. All figures re-read from the source PDFs listed in §7.

**Headline finding:** NYC publishes the HIV care continuum and mortality stratified by
race/ethnicity, but **only for all transmission categories combined**. No NYC report
cross-tabulates continuum stage × race × MSM. The only NYC data that is simultaneously
MSM-specific and race-stratified is the NHBS-MSM venue survey, which has n = 137–483
depending on cycle and whose race cells drop to n = 16. Three targets
(`cc.dx`, `cc.vsupp`, `disease.mr100`) therefore have good non-MSM anchors; three
(`i.prev.dx`, `cc.prep`, `ir100.*`) have only weak MSM anchors.

---

## 1. Summary table

Tier: **A** = published NYC figure, MSM-specific or near enough; **B** = published NYC
figure, all transmission categories (not MSM); **C** = derived from NHBS-MSM small
samples, wide CIs; **D** = no usable NYC value, needs a data request.

| Target | Atlanta value | NYC candidate | Tier | Basis |
|---|---|---|---|---|
| `cc.dx.B` | 0.847 | **0.94** | B | Care continuum 2024, Black, all txn cat. |
| `cc.dx.H` | 0.818 | **0.93** | B | Care continuum 2024, Latino |
| `cc.dx.W` | 0.862 | **0.97** | B | Care continuum 2024, white |
| `cc.dx.B` (alt, MSM) | — | 0.93 | C | 1 − unaware, NHBS-MSM5 2017 |
| `cc.dx.H` (alt, MSM) | — | 0.86 | C | idem |
| `cc.dx.W` (alt, MSM) | — | 1.00 | C | idem — degenerate, do not use |
| `cc.vsupp.B` | 0.602 | **0.82** | B | VS ÷ dx, 2024 (point-in-time VL) |
| `cc.vsupp.H` | 0.620 | **0.87** | B | idem |
| `cc.vsupp.W` | 0.712 | **0.91** | B | idem |
| `cc.vsupp` overall (sustained) | — | **0.74** | B | sustained VS among diagnosed — see §3.2 |
| `ir100.gono` | 12.81 | **12–16** | C | NHBS-MSM self-report, 2017 / 2023 |
| `ir100.chla` | 14.59 | **9–14** | C | idem |
| `ir100.syph` | 2 | **5–19** | C | idem — unstable, see §4 |
| `i.prev.dx.B` | 0.33 | **0.278** | C | NHBS-MSM5 2017, prev × awareness |
| `i.prev.dx.H` | 0.127 | **0.188** | C | idem |
| `i.prev.dx.W` | 0.084 | **0.104** | C | idem |
| `cc.prep.B` | 0.199 | **0.30 / 0.58** | C | NHBS 2017 / 2023, past-12-mo use |
| `cc.prep.H` | 0.229 | **0.26 / 0.71** | C | idem |
| `cc.prep.W` | 0.321 | **0.35 / 0.62** | C | idem |
| `disease.mr100` | 0.273 | **0.18** | B | HIV-related deaths, 2023, all txn cat. |
| `disease.mr100` by race | — | 0.165 / 0.133 / 0.078 | B | all-cause × 19% HIV-related, see §6 |
| MSM×race continuum | — | — | D | DOHMH data request required |

---

## 2. `cc.dx` — diagnosed among infected

### 2.1 Route A — NYC care continuum, 2024 (Tier B)

Direct read, all transmission categories (*People With HIV — NYC, 2024*, slide 46):

| | Overall | Black | Latino | White |
|---|---|---|---|---|
| Est. people with HIV | 91,300 | 40,000 | 33,400 | 14,100 |
| HIV-diagnosed | 94% | 94% | 93% | 97% |
| Received care | 87% | 86% | 88% | 91% |
| Prescribed ART | 83% | 81% | 84% | 88% |
| Virally suppressed | 81% | 77% | 81% | 89% |

Consistency check against the 2024 Annual Report executive summary: 85,800 diagnosed /
91,300 total = 0.9398 ≈ 94%. ✔

Note the white column has VS (89%) > prescribed ART (88%). The report flags this
explicitly: continuum stages come from different data sources (ART prescription is
imputed from MMP chart review), so stages are not strictly nested. Do not treat the
continuum as a monotone cascade.

### 2.2 Route B — NHBS-MSM5 2017, MSM-specific (Tier C)

`cc.dx` = 1 − (proportion unaware of HIV-positive status), among those testing positive
(n = 79 positives of n = 435 tested):

| | Overall | Latino | Black | White |
|---|---|---|---|---|
| HIV-positive | 18.2% | 21.8% | 29.9% | 10.4% |
| Unaware | 8.9% | 13.8% | 6.9% | 0% |
| ⇒ `cc.dx` | 0.911 | 0.862 | 0.931 | 1.000 |

**Internal validation.** Reconstructing the positive-case mix from the sample
composition (Latino 31%, Black 22%, white 40%) × race-specific prevalence gives shares
of roughly 38 / 37 / 23%. Weighted unaware = 0.38(13.8) + 0.37(6.9) + 0.23(0) = 7.8%,
against a published overall of 8.9% — the residual is the 'other' race stratum.
The race table is therefore internally coherent. ✔

**But the parallel age table is not**: it reports 39.2% unaware among ages 30–39 against
an 8.9% overall, which no weighting can reconcile. Something is wrong in that slide.
Treat the deck as partially unreliable and, if these values matter, confirm with DOHMH.

**Do not use the white cell.** A point estimate of 10.4% with a published CI of
0.0–25.7% on n ≈ 172 is not a binomial interval (binomial SE ≈ 2.3%, CI ≈ 6–15%).
Either the design effect for venue clustering is enormous or the figure is mis-rendered.
The implied `cc.dx.W = 1.000` is an artefact of zero unaware cases, not a finding.

### 2.3 Reconciliation

Routes A and B agree closely for Black MSM (0.94 vs 0.93) and diverge for Latino
(0.93 vs 0.86). Both sit well above the Atlanta values of 0.847 / 0.818 / 0.862 —
NYC diagnosis coverage is genuinely higher. **Recommend 0.94 / 0.90 / 0.97**, taking the
midpoint for Latino to acknowledge the disagreement, and widening tolerance there.

---

## 3. `cc.vsupp` — virally suppressed, conditional on diagnosis

### 3.1 Two independent derivations, 2024 (Tier B)

**Route A1 — continuum ratio.** VS among all PWH ÷ diagnosed among all PWH:

- Black: 0.77 / 0.94 = **0.819**
- Latino: 0.81 / 0.93 = **0.871**
- White: 0.89 / 0.97 = **0.918**

**Route A2 — UNAIDS 95-95-95 chain** (slide 47), second target × third target, i.e.
(ART among diagnosed) × (VS among those on ART):

| | 1st (dx) | 2nd (ART\|dx) | 3rd (VS\|ART) | product |
|---|---|---|---|---|
| Black | 94% | 86% | 95% | **0.817** |
| Latino | 93% | 90% | 97% | **0.873** |
| White | 97% | 91% | 99% | **0.901** |

The two routes agree to within 0.02 despite using different published quantities.
That convergence is the strongest evidence in this document.

**Men-only cut** (Annual Report Fig. 11.2, VS among all PWH): Black 77%, Latino 81%,
white 89% — identical to the all-gender values, so restricting to men changes nothing.
Still not MSM.

### 3.2 Definitional issue — point-in-time vs sustained suppression

This is where the gap with the Atlanta values (0.602 / 0.620 / 0.712) mostly lives.

NYC's continuum "virally suppressed" = **last VL of the calendar year < 200 copies/mL**.
NYC also publishes **sustained** suppression = *all* VLs in the year < 200:

- Among people in HIV medical care, 2024: 90% point-in-time, **80% sustained**
- In-care among diagnosed = received care ÷ diagnosed = 87 / 94 = 0.926
- ⇒ sustained VS among diagnosed ≈ 0.926 × 0.80 = **0.740**

So the choice of metric moves the target from ~0.87 to ~0.74 — a 0.13 shift, larger than
any race contrast in the data. **If the model's `cc.vsupp` represents durable suppression
(the transmission-relevant quantity), the sustained metric is the right one** and closes
roughly half the distance to the Atlanta values.

The race breakdown of sustained suppression exists (Annual Report Fig. 10.4) but the
value-to-category mapping is not recoverable from the PDF text layer — read that figure
visually before using it.

---

## 4. `ir100.*` — STI incidence per 100 PY

### 4.1 Why the surveillance report is not a drop-in

NYC's STI Surveillance Annual Report gives **reported case rates per 100,000 general
population by sex** — wrong denominator (all men, not MSM), wrong unit (reported
diagnoses, not incident infections), no MSM stratification.

2024 rates per 100,000, converted to per 100 PY (÷1,000):

| Infection | Citywide | Women | Men | Men, per 100 PY |
|---|---|---|---|---|
| Chlamydia | 760.16 | 801.00 | 712.88 | 0.713 |
| Gonorrhea | 398.27 | 138.55 | 676.02 | 0.676 |
| P&S syphilis | 17.76 | 3.47 | 32.89 | 0.0329 |
| Early latent syphilis | 34.41 | 7.59 | 62.55 | 0.0626 |
| Early syphilis (P&S + EL) | 52.17 | 11.06 | 95.44 | 0.954 |

Implied enrichment needed to reach the Atlanta targets: gonorrhea 12.81 / 0.676 ≈ **19×**,
chlamydia 14.59 / 0.713 ≈ **20×**. The consistency of that factor is reassuring — it is
what restricting from all men to MSM plus higher screening intensity should produce.
Syphilis is the outlier: 2 / 0.954 ≈ 2× against early syphilis, but 2 / 0.033 ≈ **61×**
against P&S alone. Decide which syphilis case definition the model's `ir100.syph`
represents before setting that target.

P&S syphilis among men by race, 2024 (per 100,000): **Black 43.6, Latino 41.1,
white 13.9**, citywide men 32.89. Roughly 3× disparity, consistent across 2019–2024.

### 4.2 The better NYC anchor — NHBS self-reported diagnoses (Tier C)

Self-reported STI diagnosis in the past 12 months among MSM is *directly* a per-100-PY
quantity in the right population:

| | 2017 (n = 371) | 2023 (n = 135) | Atlanta target |
|---|---|---|---|
| Gonorrhea | 12% | 16% | 12.81 |
| Chlamydia | 9% | 14% | 14.59 |
| Syphilis | 5% | 19% | 2 |
| Any STI | — | 37% | — |

Gonorrhea and chlamydia targets sit inside the 2017–2023 NYC range. **Syphilis does not**:
the Atlanta value of 2 is below even the 2017 NYC figure and far below 2023. The 2023
syphilis figure (19%, and 27% among white participants on n = 32) is not credible as a
population value — but the direction is consistent with the surveillance report's
documented syphilis epidemic among NYC men.

By race, 2023 (n = 135): gonorrhea Latino 15% / Black 18% / white 15%; chlamydia
16 / 12 / 9%; syphilis 16 / 12 / 27%. Cell sizes of 16–32 — noise, not signal.

### 4.3 Sanity check via rectal specimens

Rectal GC/CT cases among men, 2024: **17,420** (2023: 20,217) — an MSM-specific numerator
with no published denominator. Back-solving the DOHMH male denominator from the
chlamydia table: 28,240 cases ÷ (712.88/100,000) ≈ **3.96M men**. At an NYC MSM share of
5–7% of adult men (N ≈ 200k–280k), 17,420 rectal GC/CT cases gives ≈ 6–9 per 100 PY for
rectal-site infections alone; adding urethral and pharyngeal sites lands plausibly near
the 27 per 100 PY implied by the combined GC + CT targets. This is my own illustrative
derivation, not a DOHMH figure — use it as a plausibility check only.

---

## 5. `i.prev.dx` and `cc.prep`

### 5.1 `i.prev.dx` — diagnosed HIV prevalence in the race-specific MSM population

Not published anywhere for NYC; it requires an independent MSM population-size
denominator by race, which NYC does not report. Derivable from NHBS as
`prevalence × awareness`:

**2017 cycle (n = 435 tested), the more usable one:**

| | prevalence | × `cc.dx` | = `i.prev.dx` | Atlanta |
|---|---|---|---|---|
| Black | 0.299 (CI 0.208–0.390) | 0.931 | **0.278** | 0.33 |
| Latino | 0.218 (CI 0.148–0.288) | 0.862 | **0.188** | 0.127 |
| White | 0.104 (CI 0.000–0.257) | 1.000 | **0.104** | 0.084 |

Ordering B > H > W is preserved; NYC runs higher for Latino and white MSM.

**2023 cycle (n = 133) — prevalence only, no awareness published:**
Black 37.5% (CI 15.2–64.6), Latino 29.4% (CI 20.0–40.3), white 31.3% (CI 16.1–50.0).
Applying citywide dx fractions gives 0.353 / 0.273 / 0.304. **The white value is not
usable** — 31.3% prevalence among white MSM contradicts the 2017 cycle, every prior NYC
estimate, and the surveillance denominators; it rests on n = 32 with a CI spanning a
factor of three.

**Sampling bias, both cycles.** Venue-based recruitment (bars, clubs, sex environments)
over-samples older, more sexually active, and HIV-positive MSM. The 2023 deck states
outright that findings may not be representative. Both cycles likely bias `i.prev.dx`
upward. Also note the 2023 sample was 61% Latino and 63% foreign-born — a demographically
unusual draw even for NYC.

### 5.2 `cc.prep` — PrEP coverage

Past-12-month PrEP use among HIV-negative/unknown-status MSM:

| | 2017 (n = 371) | 2023 (n = 101) | Atlanta |
|---|---|---|---|
| Black | 30% | 58% | 0.199 |
| Latino | 26% | 71% | 0.229 |
| White | 35% | 62% | 0.321 |
| Overall | 31% | 67% | — |

**Definitional mismatch, and it cuts both ways.** The model's `cc.prep` is normally
*current* coverage among *CDC-indicated* HIV-negative MSM. NHBS measures *any use in the
past 12 months* among *all* HIV-negative/unknown MSM. The first difference inflates the
NHBS number, the second deflates it; net direction is not determinable without the
microdata.

A partial correction using daily-adherence data (2023, among past-30-day users, n = 55):
`took PrEP past 12 mo × took PrEP every day` = Latino 0.71 × 0.51 = 0.36,
Black 0.58 × 0.17 = 0.10, white 0.62 × 0.67 = 0.42. This is a crude lower bound on
current daily coverage and it is the one place where a NYC-specific Black/white gradient
appears clearly. The 17% daily-adherence figure for Black participants rests on very few
observations.

Note the 2017 cycle shows *flatter* PrEP use by race than the Atlanta targets imply,
and the DOHMH analysis explicitly interprets that flatness as a **coverage disparity**,
since need is far higher among Black and Latino MSM. If the model's `cc.prep` denominator
is indication-restricted, that argument implies the true race-specific coverage gradient
is steeper than the raw NHBS percentages.

---

## 6. `disease.mr100` — HIV-attributable mortality

**Use 2023, not 2024.** The 2024 death data are explicitly incomplete in both reports:
all-cause age-adjusted mortality among PWH reads 7.1 per 1,000 for 2024 against
9.8 per 1,000 for 2023 — a 27% apparent drop that is an artefact of reporting lag
(NDI and Death Master File matches are partial at publication).

2023 decomposition (Fig. 12.1), per 1,000 PWH, age-adjusted:

- All-cause **9.8**
- Non-HIV-related **7.8**
- **HIV-related 1.8 ⇒ `disease.mr100` = 0.18 per 100 PY**

Cause-of-death split, 2023: 80% non-HIV-related, 19% HIV-related, 1% unknown. Leading
non-HIV causes among PWH: cardiovascular disease, cancer, accidents. NYC's all-cause PWH
death rate (9.8) against the general NYC population rate (5.8 in 2022) gives the excess.

**By race**, from 2024 all-cause rates per 1,000 PWH (Black 8.7, Latino 7.0, white 4.1;
men overall 6.6), scaled by the 19% HIV-related share:

- Black: 8.7 × 0.19 = 1.65 per 1,000 = **0.165 per 100 PY**
- Latino: 7.0 × 0.19 = 1.33 = **0.133**
- White: 4.1 × 0.19 = 0.78 = **0.078**
- Men: 6.6 × 0.19 = 1.25 = **0.125**

Assuming a constant HIV-related share across race groups is an approximation and almost
certainly wrong in the direction of understating the Black/white gap (HIV-related deaths
concentrate where suppression is lower). Race-specific HIV-related rates are published
(Figs. 12.3 / 12.4) but the value-to-series mapping is not recoverable from the PDF text
layer — **read those figures visually before using them.** My earlier verbal assignment
of those series was not reliable and should be discarded.

The Atlanta target of 0.273 is ~1.5× NYC's 2023 HIV-related rate. Part of that is real
(NYC has better suppression), part is definitional: EpiModelHIV's `disease.mr100`
denominator is all infected including undiagnosed, while NYC's denominator is estimated
PWH, and the model may absorb some excess non-HIV mortality into the disease-specific
hazard.

---

## 7. Sources

All accessed 2026-09-22.

1. **People With HIV — New York City, 2024.** NYC DOHMH HIV Epidemiology Program,
   published December 2025.
   `https://www.nyc.gov/assets/doh/downloads/pdf/dires/hiv-overall-2024.pdf`
   → care continuum by race (slide 46), UNAIDS 95-95-95 (47), death rates by
   demographic group (49), cause of death (51), continuum technical notes (55).

2. **HIV Surveillance Annual Report, 2024.** NYC DOHMH, published December 2025.
   `https://www.nyc.gov/assets/doh/downloads/pdf/dires/hiv-surveillance-annualreport-2024.pdf`
   → PWH by transmission category and race (Tables 1–2), linkage/VS by demographic
   group (Figs. 10.2, 10.4), continuum (11.1), VS by gender × race (11.2), mortality
   (12.1–12.4), continuum definitions (Technical Notes p. 41).

3. **Sexually Transmitted Infections Surveillance Annual Report, 2024.** NYC DOHMH,
   published February 2026.
   `https://www.nyc.gov/assets/doh/downloads/pdf/std/sti-2024-report.pdf`
   → case numbers and rates by sex (Table 1, Panel 1), rectal GC/CT among men
   (Fig. 1A), P&S syphilis by race among men (Fig. 4A).

4. **Sexual and Substance Use Behaviors and HIV Prevalence Among MSM in NYC — 2023
   NHBS.** NYC DOHMH, June 2025.
   `https://www.nyc.gov/assets/doh/downloads/pdf/dires/sexual-and-substance-use-behaviors-men-2025.pdf`
   → n = 139 interviewed, 137 with confirmed HIV test; prevalence, PrEP, self-reported
   STIs, doxy-PEP, all by race.

5. **HIV Risk and Prevalence among MSM in NYC — 2017 NHBS (MSM5).** NYC DOHMH.
   `https://www.nyc.gov/assets/doh/downloads/pdf/dires/hiv-risk-among-msm-in-nyc-2017study.pdf`
   → n = 483 analysed, 435 with confirmed test; prevalence and unawareness by race,
   PrEP, self-reported and lab-confirmed extragenital STIs.

---

## 8. Corrections to my earlier verbal summary

- Men's 2024 chlamydia rate is **712.88** per 100,000, not 801 — 801.00 is the *women's*
  rate. Men's gonorrhea 676.02 was correct.
- The race-specific HIV-related mortality series (Figs. 12.3/12.4) were assigned by me to
  race groups on the basis of an ambiguous PDF text extraction. **That assignment is not
  reliable.** §6 substitutes an unambiguous derivation from slide 49.
- `disease.mr100` should be anchored to **2023**, not 2024; 2024 death data are incomplete.
- On CDC AtlasPlus: it supports transmission category × race cross-tabs at state level,
  but sub-state / MSA availability for that particular combination should be verified
  before relying on it. It is worth a look, but it is not a guaranteed substitute for a
  DOHMH request.

---

## 9. Closing the gaps

**DOHMH custom data request** — `hivreport@health.nyc.gov`, minimum two weeks turnaround,
stated in the Annual Report. Worth requesting as a single package:

1. Care continuum stages (diagnosed / in care / on ART / VS point-in-time / VS sustained)
   cross-tabulated by **race × MSM transmission category**, 2024.
2. HIV-related and all-cause death rates among PWH by **race × MSM**, 2023.
3. PWH counts by **race × MSM** as of 31 Dec 2024 (the denominator for `i.prev.dx`).
4. Rectal and urethral GC/CT case counts among men by race, 2024.

**MSM population size denominators by race for NYC** — needed for `i.prev.dx` and for the
STI rates regardless of what DOHMH supplies. The Emory / Grey *et al.* MSM
population-size-estimate work is the standard source in this modelling lineage; using it
keeps the denominator consistent with how the Atlanta targets were constructed.

**Calibration design implication.** For the six targets resting on NHBS
(`i.prev.dx.*`, `cc.prep.*`, and implicitly `ir100.*`), the sampling variance in the
source data is larger than the between-race contrasts you are trying to fit. Treating
those as point targets with tight tolerance would be fitting noise. Either widen their
tolerance bands to at least the published CI widths, down-weight them relative to the
Tier B continuum targets, or hold them fixed and calibrate only against `cc.dx`,
`cc.vsupp` and `disease.mr100` in the first NYC test run.
