# NYC Calibration targets

## Limits

My estimations for the number of MSM is not great.

## Sources

https://www.nyc.gov/site/doh/data/data-sets/hiv-aids-surveillance-and-epidemiology-reports.page

### Census + bennet

https://www.census.gov/quickfacts/fact/table/newyorkcitynewyork,bronxcountynewyork,kingscountynewyork,newyorkcountynewyork,queenscountynewyork,richmondcountynewyork

bennett (2024) - https://publichealth.jmir.org/2024/1/e56643 - % MSM

- full pop: 8 584 628
- race:
    - black: 21.9%
    - hisp: 28.5%
    - white: 49.6% (the rest)
- age and sex:
    - male: 48%
    - 18yo+: 78.2%

Note: ~36.6% foreign born

So: 107 696 MSM 18+ (full * prop male * prop 18+ * 3.3%)

MSM By race:
- Black: 22 354
- Hisp: 30 495
- White: 53 072


###  source: "hiv-among-men-sex-with-men-2024.pdf"

- ~ 45 700 MSM with HIV
- ~ 464 death among MSM with HIV (5.2 / 1000)

I use "white" as white+other and adjust values accordingly
- black new hiv dx: 268
- hisp new hiv dx: 385
- white/other new hiv dx: (150)
    - white: 85 (56.67%)
    - asian: 49 (32.67%)
    - native: 1 (0.67%)
    - multi: 15 (10%)

- black all PLWHIV: 15100
- hisp all PLWHIV: 16800
- white/other all PLWHIV: (12870)
    - white: 10700 (83.14%)
    - asian: 1700 (13.21%)
    - native: 110 (0.85%)
    - multi: 360 (2.80%)

### source: PPN all_states

- 106 879 MSM in NYC
- coherent with census + bennett
- use 107 000


## Targets

### `cc.prep`

"2023 hiv report.pdf" - p20

- national coverage 2022:
    - black: 12.8%
    - hisp: 24.4%
    - white/other: 69.7%
    - total: 36%
- rebalance with NYC coverage (63.4%) - p25


### `cc.dx`

source: "hiv-among-men-sex-with-men-2024.pdf" - p31

- `cc.dx.B` = 0.94
- `cc.dx.H` = 0.93
- `cc.dx.W` = 0.9620 (adjusted with other)

### Received care (all)

source: "hiv-among-men-sex-with-men-2024.pdf" - p31

- Received care = 0.86
- Received care = 0.88
- Received care = 0.8995 (adjusted with other)

### `cc.linked1m` (so only the one diag in 2024)

source: "hiv-among-men-sex-with-men-2024.pdf" - p22

- `cc.linked1m.B` = 0.81
- `cc.linked1m.H` = 0.88
- `cc.linked1m.W` = 0.8688 (adjusted with others)

### `cc.vsupp`

source: "hiv-among-men-sex-with-men-2024.pdf" - p31
NOTE: p29 are those diag in 2024 only

- `cc.vsupp.B` = 0.78
- `cc.vsupp.H` = 0.83
- `cc.vsupp.W` = 0.8867 (adjusted with other)

### `disease.mr100`
### `num`

- assumptions:
    - MSM proportion is the same among race groups
    - consider only 18+ males
    - consider that the "https://doi.org/10.2196/publichealth.5365" percentages
      are still correct

source: Estimating the Population Sizes of Men Who Have Sex With Men in US States and Counties Using Data From the American Community Survey - https://doi.org/10.2196/publichealth.5365

https://www.census.gov/quickfacts/fact/table/newyorkcitynewyork,bronxcountynewyork,kingscountynewyork,newyorkcountynewyork,queenscountynewyork,richmondcountynewyork/SEX255225#SEX255225
(NYC census csv)

NYC: estimated MSM 2016 (%) (census 2025)
- New York County - 87556 (13.8%) (total: 1664862 - female: 53% - <18: 12.9%)
    - B: 18.2% , H: 25.3%, W:
- Kings County - 59767 (6.7%) (total: 2653963 - female: 52.6% - <18: 20.7%)
    - B: 31.1% , H: 19.8, W:
- Queens County - 45656 (5.3%) (total: 2358182 - female: 53% - <18: 18.2%)
    - B: 21.4% , H: 29.5, W:
- Bronx County - 22370 (4.8%) (total: 1406332 - female: 53.2% - <18: 23.5%)
    - B: 45.2% , H: 57%, W:
- Richmont County - ?? (??) (total: 500K - female: 51.6% - <18: 20.4%)
    - B: 12.4% , H: 19.9%, W:

TOTAL MSM NYC: 215349
bennett: 107000

ratio = 1/2 (use for prev / ir100)

### `i.prev.dx`

- black: 15100*0.94 / 22354 = 63% (0.317 with other total)
- hisp: 16800*0.93 / 30495 = 51% (0.256)
- white:  12870*0.9620 / 53072 = 23% (0.116)

### `ir100.hiv.dx`

See sources

- black: 268 / (22354 - 15100) * 100 = 3.6945 (0.905 with other total)
- hisp: 385 / (30495 - 16800) * 100 =  2.8112 (0.871)
- white: 150 / (53072 - 12870) * 100 = 0.3731 (0.161)

### `ir100.chla`
### `ir100.gono`
### `ir100.syph`
