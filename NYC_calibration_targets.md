# NYC calibration targets


Race groups follow DOHMH's mutually exclusive scheme (Latino = any race; other groups
non-Latino). **W = white + other** (Asian/PI, Native American, Multiracial), weighted as
noted per target.

## Summary

| Target | B | H | W/other | Source | Status |
|---|---|---|---|---|---|
| `cc.dx` | 0.940 | 0.930 | 0.962 | MSM p31 | published, MSM × race |
| `cc.linked1m` | 0.810 | 0.880 | 0.869 | MSM p22 | published, MSM × race |
| `cc.vsupp` (\| dx) | 0.830 | 0.892 | 0.922 | MSM p31, VS ÷ dx | published, MSM × race |
| `i.prev.dx` | 0.285 | 0.234 | 0.0995 | §3, derived | denominator-dependent |
| `ir100.hiv.dx` | 0.772 | 0.772 | 0.134 | §3, derived | denominator-dependent |
| `cc.prep` | 0.58 | 0.71 | 0.62 | §4, NHBS 2023 | level uncertain, wide tolerance |
| `cc.prep` (overall) | 0.64 | | | §4, NHBS 2023 weighted | single value |
| `disease.mr100` | 0.193 | | | §5, MSM p32 + p35 | single value |
| `ir100.gono` | 17.4 | | | §6, NHBS 2023 | single value, wide tolerance |
| `ir100.chla` | 16.3 | | | §6, NHBS 2023 | single value, wide tolerance |
| `ir100.syph` | 5.1 | | | §6, NHBS 2017 | single value, probably low |
| `num` (MSM 18+) | 49,811 | 66,671 | 124,433 | §1 | total 240,914 |

"MSM p.X" = *HIV Among MSM – NYC, 2024* (`hiv-among-men-sex-with-men-2024.pdf`), slide
number = PDF page. All MSM-report figures include MSM-IDU.

### As an R target vector

```r
  c(
    # 1st calibration set (all independant)
    cc.dx.B         = 0.940,
    cc.dx.H         = 0.930,
    cc.dx.W         = 0.962,
    # 2nd calibration set (all independant)
    cc.vsupp.B      = 0.830,
    cc.vsupp.H      = 0.892,
    cc.vsupp.W      = 0.922,
    # STIs
    ir100.gono      = 17.4,
    ir100.chla      = 16.3,
    ir100.syph      = 5.1,    # NHBS 2017; 2023 gives 21.1 (outer bound)
    # 3rd calibration set
    i.prev.dx.B     = 0.285,
    i.prev.dx.H     = 0.234,
    i.prev.dx.W     = 0.0995,
    ir100.hiv.dx.B  = 0.772,
    ir100.hiv.dx.H  = 0.772,
    ir100.hiv.dx.W  = 0.134,
    cc.prep.B       = 0.58,
    cc.prep.H       = 0.71,
    cc.prep.W       = 0.62,
    cc.prep         = 0.64,   # race values weighted to NYC MSM; raw NHBS overall 0.68
    disease.mr100   = 0.193
    # not in the Atlanta set:
    # cc.linked1m.B = 0.810,
    # cc.linked1m.H = 0.880,
    # cc.linked1m.W = 0.869
  )
```

---

## 1. `num` — MSM population

### 1.1 Total

**240,914 MSM aged 18+.**

Grey et al. 2016 county percentages (MSM in past 5 years, % of adult men), assumed still
valid, applied to 2025 adult men from the census CSV; Staten Island filled with Bennett's
3.3% (no Grey value available). Adult men = `pop × (1 − female%) × (1 − under18%)`.

| Borough | Pop 2025 | Male | 18+ | Adult men | MSM % | Source | MSM |
|---|---|---|---|---|---|---|---|
| Manhattan (New York) | 1,664,862 | 0.470 | 0.871 | 681,545 | 13.8 | Grey | 94,053 |
| Brooklyn (Kings) | 2,653,963 | 0.474 | 0.793 | 997,577 | 6.7 | Grey | 66,838 |
| Queens | 2,358,182 | 0.484 | 0.818 | 933,633 | 5.3 | Grey | 49,483 |
| Bronx | 1,406,332 | 0.468 | 0.765 | 503,495 | 4.8 | Grey | 24,168 |
| Staten Island (Richmond) | 501,290 | 0.484 | 0.796 | 193,129 | 3.3 | Bennett | 6,373 |
| **NYC** | 8,584,629 | | | 3,309,378 | 7.3 | | **240,914** |

The Staten Island fill mixes definitions (Grey: NYC-specific, past 5 years; Bennett:
national), but the borough is 2.6% of the total: a true share of 2% or 5% would move the
total by −1.0% or +1.4%.

Raw 2013 Grey counts for the other four boroughs sum to 215,349; rescaling to 2025 adult
men adds 9%. Only Manhattan (87,556; 13.8%) is verified against the Grey abstract.

### 1.2 Why not Census × Bennett (3.3%)

`8,584,629 × 0.48 × 0.798 × 0.033 = 108,512`, where:

- 8,584,629 = NYC population, July 2025 (CSV)
- **0.48 = male share of the whole population**: 1 − 0.520 (CSV "Female persons, percent")
- 0.798 = share aged 18+: 1 − 0.202 (CSV "Persons under 18 years, percent")
- 0.033 = Bennett 2024 MSM share of adult men

The first three factors give adult men; the last gives MSM among them. Multiplying an
all-ages male share by an all-ages adult share assumes sex and age are independent.
Children are slightly more often male and older adults more often female, so this
overstates adult men by roughly 1–2% (if under-18s are 51% male, the adult male share is
47.2%, not 48%). The §1.1 borough counts use the same approximation, so the comparison
between the two methods is unaffected.

Rejected because it applies a **national** percentage to a city where MSM concentrate
(Grey: Manhattan 13.8% vs 3.9% nationally). Against the DOHMH numerators it implies total
HIV prevalence of 0.63 among Black MSM and 0.53 among Latino MSM, far above any NYC survey
estimate. The §1.1 total gives 0.186 overall (44,770 / 240,914), matching NHBS-MSM5
2017's measured 18.2%.

The PPN spreadsheet (106,879 for New York) is **not** an MSM population count: its
columns (MSM / heterosexual women / heterosexual men / PWID) are PrEP-indication risk
groups, so these are persons with PrEP need — and the row is New York **State**. Its
agreement with 108,512 is coincidental and cannot corroborate it.

### 1.3 Race split

Each borough's 2025 race shares (CSV) applied to that borough's MSM from §1.1, then
summed. Assumes equal MSM prevalence across race groups within a borough, and that the
borough's race composition (reported for the whole population) holds for adult men.

The CSV's "Black alone" includes Hispanic Black people, so it overlaps with Hispanic
(Bronx: 45.2% + 57.0% > 100%). Non-Hispanic Black is therefore taken as the residual:

- H = Hispanic or Latino
- W/other = White alone not Hispanic + Asian alone + NHPI alone
- B = 1 − H − W/other (also absorbs the small non-Hispanic Native American and
  multiracial groups, which have no clean CSV column)

| Borough | MSM | B % | H % | W/other % | MSM B | MSM H | MSM W/other |
|---|---|---|---|---|---|---|---|
| Manhattan | 94,053 | 14.6 | 25.3 | 60.1 | 13,732 | 23,795 | 56,526 |
| Brooklyn | 66,838 | 28.9 | 19.8 | 51.3 | 19,316 | 13,234 | 34,288 |
| Queens | 49,483 | 18.7 | 29.5 | 51.8 | 9,253 | 14,597 | 25,632 |
| Bronx | 24,168 | 28.2 | 57.0 | 14.8 | 6,815 | 13,776 | 3,577 |
| Staten Island | 6,373 | 10.9 | 19.9 | 69.2 | 695 | 1,268 | 4,410 |
| **NYC** | **240,914** | **20.7** | **27.7** | **51.7** | **49,811** | **66,671** | **124,433** |

Check: weighting the same borough shares by adult men instead of MSM gives B 21.9 /
H 29.3 / W/other 48.7, close to DOHMH's own population split (22 / 28 / 50, *People With
HIV – NYC 2024*, slide 15), which supports the residual method for B. The MSM split is
whiter because 39% of NYC MSM live in Manhattan.

Caveats: Latino and Black New Yorkers are younger on average, so their share of adult men
is somewhat below their share of the whole population — the B and H denominators are
likely slightly high. And the numerator W/other includes 470 Native American and
multiracial MSM with HIV, whose population sits mostly in the B residual.

### 1.4 MSM with HIV (numerators) — MSM p31, p10

| | B | H | W | Asian/PI | Native | Multi | W/other |
|---|---|---|---|---|---|---|---|
| Est. MSM with HIV (dx + undx) | 15,100 | 16,800 | 10,700 | 1,700 | 110 | 360 | 12,870 |
| Diagnosed (× `cc.dx`) | 14,194 | 15,624 | 10,379 | 1,564 | 107 | 331 | 12,381 |
| New diagnoses 2024 | 268 | 385 | 85 | 49 | 1 | 15 | 150 |

W/other weights — by PWH: 83.14 / 13.21 / 0.85 / 2.80%; by new dx: 56.67 / 32.67 /
0.67 / 10.00%. Race-specific PWH sum to 44,770 vs the published overall 45,700
(race-specific diagnosed fractions, per p31 footnote 4).

These continuum estimates are migration-adjusted (p39). Do **not** use the Annual
Report Table 1 count (64,084 MSM "reported in NYC and presumed living"), which
includes people who have left NYC.

---

## 2. Care continuum

### `cc.dx` — MSM p31

B **0.94**, H **0.93**, W/other **0.962**
(`0.8314×.97 + 0.1321×.92 + 0.0085×.97 + 0.0280×.92`, PWH weights).

### `cc.linked1m` — MSM p22

Linkage ≤30 days (CD4, VL or genotype) among MSM diagnosed in 2024:
B **0.81**, H **0.88**, W/other **0.869**
(`(85×.85 + 49×.88 + 1×1.00 + 15×.93) / 150`, new-diagnosis weights; Native and
Multiracial cells are small-n).

### `cc.vsupp` — MSM p31

Viral suppression (last VL of year < 200) among all MSM living with diagnosed HIV,
computed as continuum VS ÷ HIV-diagnosed:

- B **0.830** = 0.78 / 0.94
- H **0.892** = 0.83 / 0.93
- W/other **0.922** = 0.8867 / 0.9620 (suppressed ÷ diagnosed counts, 11,412 / 12,381)

Cross-check: p29 (VS among diagnosed MSM, weighted method) gives B 0.82, H 0.89,
W/other 0.916, within ±0.01 of the ratio for every race group.

Point-in-time suppression. If `cc.vsupp` represents durable suppression, NYC's sustained
metric (all VLs < 200) is ~0.10 lower citywide; no MSM × race breakdown is published.

### Received care (supplementary) — MSM p31

| | B | H | W/other |
|---|---|---|---|
| of all PWH | 0.86 | 0.88 | 0.900 |
| conditional on dx | 0.915 | 0.946 | 0.935 |

### Related, not currently targeted

VS within 3 months of diagnosis, 2024 (MSM p25): B 0.58, H 0.67, W 0.55, overall 0.63.

---

## 3. Prevalence and diagnosis rate

Denominators from §1.3.

### `i.prev.dx` — diagnosed MSM ÷ all MSM

| | Diagnosed | MSM | Target |
|---|---|---|---|
| B | 14,194 | 49,811 | **0.285** |
| H | 15,624 | 66,671 | **0.234** |
| W/other | 12,381 | 124,433 | **0.0995** |

Independent check against NHBS-MSM5 2017 (slide 41, prevalence × awareness, venue sample,
no external denominator): B 0.278, H 0.188, W 0.104. B and W agree within 0.007 and 0.004;
H is 0.046 higher here.

### `ir100.hiv.dx` — new diagnoses per 100 HIV-negative MSM-years

`100 × new dx / (MSM − all PWH)`; subtracts diagnosed and undiagnosed PWH.

| | New dx | HIV-negative MSM | Target |
|---|---|---|---|
| B | 268 | 34,711 | **0.772** |
| H | 385 | 49,871 | **0.772** |
| W/other | 150 | 111,563 | **0.134** |

Diagnosis rate, not incidence (includes diagnosis lag).

---

## 4. `cc.prep`

**Working target: B 0.58, H 0.71, W/other 0.62** — NHBS 2023 NYC MSM, PrEP use in past 12
months among HIV-negative/unknown MSM (n = 101; small race cells → wide tolerance).
W/other = white value (other races excluded from the NHBS table).

Overall `cc.prep` = **0.64**: the race values weighted by the NYC MSM split from §1.3
(`0.58×0.207 + 0.71×0.277 + 0.62×0.517 = 0.637`). The raw NHBS overall (68%, n = 105
HIV-negative/unknown men) overweights Latino men, who are 61% of the sample versus 28% of
NYC MSM.

Source: NHBS 2023 deck (§6 for link), slide "PrEP Awareness, Use, and Adherence Overall
and by Participant's Race or Ethnicity, Past 12 Months": took PrEP in past 12 months,
overall 67%, Latino 71%, Black 58%, White 62%. The slide gives no per-race n; from the
sample make-up the Black estimate rests on roughly 12 men (58% ≈ 7/12, 95% CI ~30–80%,
inferred, not published).

### Why not the national gradient rebalanced to NYC

National 2022 (CDC Table 3a, p20): B 12.8%, H 24.4%, W/other 69.7%
(`(282,041 + 19,088) / (300,650 + 131,180)`), total 36.0%.

- Naive scaling breaks the [0, 1] bound (W/other → 1.23 at 63.4%).
- A logit shift preserving national odds ratios forces W/other to 0.87–0.97 depending on
  level and weights, and imposes a disparity (white 5.4× Black nationally) that NYC data
  contradict (NHBS: white 1.07× Black).

### Level

The draft's 63.4% is **New York State** (Table 3b, p25). NYC's four EHE counties (Table
3c, p34, 2022): Bronx 38.7%, Kings 66.7%, New York **116.7%**, Queens 56.4%; combined
35,939 / 45,990 = **78.1%**; 58.5% excluding Manhattan. Richmond not reported.

The >100% Manhattan value reflects the 2018-vintage denominator, which CDC paused in May
2024 pending method revision (*National HIV Progress Report 2024*, p5). Coverage is also
all risk groups, not MSM.

NHBS's weighted mean (0.64–0.65 across plausible weights) lies between the with- and
without-Manhattan CDC figures and does not depend on the paused denominator — hence the
working target.

Upper scenario, NHBS gradient logit-shifted to 78.1%: B 0.73, H 0.83, W/other 0.77.

---

## 5. `disease.mr100` — MSM p32, p35

**0.193 per 100 PY**, from the 2023 age-adjusted all-cause death rate among MSM with HIV
and the 2023 cause-of-death split (21% HIV-related, 78% non-HIV, 2% unknown):

```
all-cause      9.2   deaths per 1,000 per year
× 0.21     =   1.93  HIV-related deaths per 1,000 per year
÷ 10       =   0.193 HIV-related deaths per 100 per year  (= per 100 PY)
```

DOHMH's annual rate per 1,000 people with HIV is deaths per 1,000 person-years; dividing
by 10 converts to the per-100 scale of `disease.mr100`.

- **Not 2024.** The 5.2/1,000 for 2024 reflects incomplete death data (p32 footnote):
  it drops 43% from 2023 in one year, the same artefact as citywide (9.8 → 7.1).
- The 2023 value is **unlabelled** on the p32 chart; ~9.2 is a visual read (range
  9.0–9.4 → 0.189–0.197). Consistent with the 46% decline from the 2020 peak (~9.6).
- 464 deaths / 45,700 is a crude rate (~10/1,000), not 5.2; the 5.2 is age-adjusted to
  the US 2000 standard population.
- Citywide check: 2023 HIV-related rate 1.8/1,000 = 0.18/100 PY (Annual Report Fig. 12.1).
- Age adjustment approximates a 15–65 model population better than the crude rate, but
  is not identical to the model's output.

Race-specific all-cause rates, 2024 (MSM p33, incomplete year): B 7.1, H 6.4, W 3.3 per
1,000.

---

## 6. STI incidence — `ir100.gono`, `ir100.chla`, `ir100.syph`

Called `ir100.gc` / `ir100.ct` in the Atlanta sheet. Single citywide values, per 100
person-years.

| Target | Value | 95% CI | Source |
|---|---|---|---|
| `ir100.gono` | **17.4** | 11.3–25.9 | NHBS 2023 |
| `ir100.chla` | **16.3** | 10.6–24.8 | NHBS 2023 |
| `ir100.syph` | **5.1** | 3.3–7.8 | NHBS 2017 (2023 value 21.1 kept as outer bound) |

### 6.1 Sources and where to look

**NHBS 2023** — NYC DOHMH, *Sexual and Substance Use Behaviors and HIV Prevalence Among
Men Who Have Sex With Men in New York City: Findings from the 2023 National HIV Behavioral
Surveillance Study*, June 2025.
https://www.nyc.gov/assets/doh/downloads/pdf/dires/sexual-and-substance-use-behaviors-men-2025.pdf

No slide numbers are visible in the text version. In the "Sexually Transmitted Infections
(STIs)" section, after the two STI-testing slides:

- **"Self-Reported STI Diagnoses Overall and by Participant's Age, Past 12 Months"**,
  n = 139 (full sample, HIV-positive men included). Overall bars: any STI 37%, syphilis
  19%, gonorrhea 16%, chlamydia 15%. **Used.**
- "Self-Reported STI Diagnoses Overall and by Participant's Race or Ethnicity, Past 12
  Months", n = 135 (excludes 4 men of "other" race). Overall bars: 37%, 19%, 16%, 14%.
  Not used — chlamydia differs by one point because of the excluded men.

**NHBS 2017** — NYC DOHMH, *HIV Risk and Prevalence among Men who Have Sex with Men in New
York City: Results from the 2017 National HIV Behavioral Surveillance Study*.
https://www.nyc.gov/assets/doh/downloads/pdf/dires/hiv-risk-among-msm-in-nyc-2017study.pdf

- Slide 30, "Self-Reported STI Diagnoses in Past 12 Months by Participants' Age",
  n = 404, HIV-negative or unknown status only: syphilis 5%, gonorrhea 11%, chlamydia 9%.
- Slide 29, same by race (n = 371): 5%, 12%, 9%.
- Slide 31, lab-confirmed extragenital prevalence among 412 men tested in the study: any
  12%, rectal gonorrhea 4%, rectal chlamydia 6%, pharyngeal gonorrhea 4%, pharyngeal
  chlamydia <1%.

### 6.2 Method: share of men diagnosed → rate

NHBS asks whether a man was diagnosed in the past 12 months, so it counts **men with at
least one diagnosis**, each once. `ir100` counts **infections** per 100 person-years; a man
infected twice counts twice. The conversion finds the infection rate that leaves exactly
the reported share of men with at least one infection.

If infections arrive at random at rate λ per person-year, the chance of none in a year is
e^(−λ):

```
p = 1 − e^(−λ)   ⇒   λ = −ln(1 − p)
```

Illustration, gonorrhea (λ = 0.174), 100 men over one year:

| Infections that year | Men | Infections |
|---|---|---|
| 0 | 84.0 | 0 |
| 1 | 14.6 | 14.6 |
| 2 | 1.3 | 2.6 |
| 3+ | 0.1 | 0.2 |
| **Total** | **16 with ≥ 1** | **17.4** |

The correction is small for small p (16% → 17.4). Real repeat infections cluster among the
most active men, so the true rate behind a given p is higher: λ is a floor.

95% CIs: Wilson interval on the proportion (count reconstructed from the percentage, e.g.
~22/139), then transformed.

| per 100 PY (95% CI) | 2023, n = 139, all MSM | 2017, n = 404, HIV−/unknown |
|---|---|---|
| Gonorrhea | 16% → **17.4** (11.3–25.9) | 11% → 11.7 (8.6–15.4) |
| Chlamydia | 15% → **16.3** (10.6–24.8) | 9% → 9.4 (6.7–12.9) |
| Syphilis | 19% → 21.1 (14.0–30.1) | 5% → **5.1** (3.3–7.8) |

### 6.3 Choices

**Gonorrhea and chlamydia: 2023.** Same survey and year as `cc.prep`, and it includes
HIV-positive MSM like the model population; 2017 covers HIV-negative/unknown men only.
Testing also rose between cycles (any STI test in past year 67% → 73%, rectal 41% → 59%),
so part of the 2017 → 2023 increase is more testing rather than more infection.

**Syphilis: 2017.** The 2023 value (21.1) is not plausible as incidence. Werner et al.'s
meta-analysis of PrEP studies — men selected for high risk and screened every few months —
pooled syphilis at 9.1 per 100 PY (range 1.8–14.9); a venue sample should not exceed even
the highest study. Likely reasons: self-report cannot separate a new infection from an old
one picked up by serology, and 19% rests on about 26 men. For comparison, the same
meta-analysis pooled gonorrhea and chlamydia at 39.6 and 41.8 per 100 PY, well above the
NHBS values, as expected. The 2017 value (5.1) is within the PrEP-study range but excludes
HIV-positive men, who have more syphilis, so it is probably low. Wide tolerance; 21.1 as
an outer bound.

### 6.4 What these measure

Diagnoses made in routine care, so they depend on testing: undiagnosed infections,
especially asymptomatic rectal and pharyngeal ones, are missed. If the model's `ir100`
counts every incident infection, these are lower bounds. Venue sampling pushes the other
way (more sexually active men than the average MSM).

If the model outputs site-specific prevalence, the 2017 lab-confirmed extragenital results
(slide 31) are the only NYC MSM STI measure that does not depend on routine testing.

DOHMH surveillance case counts are not used: no sex-of-partner field, and they count
diagnoses rather than infections.

### 6.5 Comparison with the Atlanta targets

Atlanta: `ir100.gc` 12.81, `ir100.ct` 14.59 (Kojima et al. 2016); `ir100.syph` 2 (source
not recorded here).

Kojima et al. is a meta-analysis of 18 cohort studies of MSM (> 70,000 person-years):
five in MSM on PrEP, 14 without, PROUD contributing to both arms, from several countries.
It is not Atlanta-specific, so applying "the same approach" to NYC would return the same
numbers.

Table 1 is not in the text version, so the source cell is unconfirmed. The values cannot be
the non-PrEP rates: with the reported rate ratios (25.3 for gonorrhea, 11.2 for chlamydia),
PrEP users would then be at 324 and 163 infections per 100 PY. They are most likely the
pooled PrEP-cohort rates — scheduled screening, high-risk trial participants.

Harawa et al. (*AIDS* 2017) identified data errors: EXPLORE was included although it
stopped bacterial STI testing within its first year and only collected self-reports, with
person-years entered as 36,628 instead of 12,240; PROUD counts (276 and 124 incident STIs
for PrEP users and non-users) do not match the published trial (210 and 165).

The NYC 2023 values land close to Atlanta's by coincidence — different populations,
measured differently.

---

## 7. Sensitivities not applied

- **Race-specific MSM prevalence.** Lieb 2011 (national): Black 5.3%, Latino 6.5%, white
  6.8% of adult men. Applying these relative rates lowers the Black denominator 17% and
  raises `i.prev.dx.B` from 0.285 to 0.344.
- **Denominator vintage.** Raw 2013 Grey counts plus the Staten Island fill (221,722)
  raise all §3 targets by 8.7%.
- **Staten Island share.** 2% or 5% instead of 3.3%: total −1.0% / +1.4%.

---

## 8. Changes from draft

1. `cc.vsupp` used VS ÷ all PWH (p31) for a target conditioned on diagnosis → VS ÷ dx
   from the same continuum. B 0.78 → 0.830, H 0.83 → 0.892, W/other 0.887 → 0.922.
2. PPN reinterpreted as PrEP need, New York State; removed as corroboration.
3. MSM total: Census × Bennett replaced by Grey % × 2025 adult men (completing the
   draft's stated assumption), Staten Island filled with Bennett 3.3%; "ratio = 1/2"
   retired.
4. Race split: citywide shares with overlapping Black/Hispanic categories replaced by
   borough-level 2025 shares applied to each borough's MSM, non-Hispanic Black as residual.
5. PrEP level: 63.4% is NY State; NYC four counties = 78.1%.
6. `disease.mr100` filled from 2023, not incomplete 2024.
7. Arithmetic fixes: adult share (note 78.2%, calculation 79.2%, CSV 79.8%); draft race
   counts summed to 105,921 not 107,000 and B did not reproduce (107,000 × 0.219 =
   23,433 ≠ 22,354); Queens female share 51.6% not 53%; Staten Island absent from the Grey
   total (now filled, §1.1).

## 9. Open items

- Optional: Staten Island Grey % (CAMP county file) to replace the Bennett fill.
- Verify Kings/Queens/Bronx Grey figures against source.
- Exact 2023 MSM death rate (DOHMH request or 2024 data tables).
- Identify PPN source and vintage; if it is CDC's revised PrEP-need denominator, NY State
  coverage on it would be 46,046 / 140,078 = 0.33.
- Confirm which Kojima Table 1 cell the Atlanta 12.81 / 14.59 come from.

## Sources

- DOHMH, *HIV Among MSM – NYC, 2024* (Dec 2025): p10, p22, p25, p29, p31–35, p39.
- DOHMH, *People With HIV – NYC, 2024*: slide 15 (race-split check).
- DOHMH, *HIV Surveillance Annual Report 2024*: Table 1; Fig. 12.1.
- CDC, *HIV Surveillance Data Tables* 4(4), Dec 2023: Table 3a (p20), 3b (p25), 3c (p34).
- CDC, *National HIV Progress Report 2024*: p5 (PrEP indicator paused).
- Census QuickFacts, NYC and counties (`NYC_Census.csv`).
- Grey JA et al. *JMIR Public Health Surveill* 2016;2(1):e14. doi:10.2196/publichealth.5365
- Bennett BW et al. *JMIR Public Health Surveill* 2024;10:e56643. doi:10.2196/56643
- NYC DOHMH, *Sexual and Substance Use Behaviors and HIV Prevalence Among MSM in NYC:
  Findings from the 2023 NHBS*, June 2025.
  https://www.nyc.gov/assets/doh/downloads/pdf/dires/sexual-and-substance-use-behaviors-men-2025.pdf
- NYC DOHMH, *HIV Risk and Prevalence among MSM in NYC: Results from the 2017 NHBS*
  (slides 29–31, 41).
  https://www.nyc.gov/assets/doh/downloads/pdf/dires/hiv-risk-among-msm-in-nyc-2017study.pdf
- Kojima N, Davey DJ, Klausner JD. *AIDS* 2016;30(14):2251–2252.
  doi:10.1097/QAD.0000000000001185
- Harawa NT et al. Serious concerns regarding a meta-analysis of preexposure prophylaxis use
  and STI acquisition. *AIDS* 2017;31(5):739–740.
- Werner RN et al. Incidence of STIs in MSM at substantial risk of HIV infection: a
  meta-analysis of data from trials and observational studies of HIV PrEP. *PLOS One* 2018.
  doi:10.1371/journal.pone.0208107
- Lieb S et al. *Public Health Rep* 2011;126(1):60–72.
