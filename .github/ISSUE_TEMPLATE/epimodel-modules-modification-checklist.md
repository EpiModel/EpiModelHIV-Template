---
name: EpiModel Modules Modification Checklist
about: Things to verify when working on an EpiModel module
title: "[MODULE] new module / features"
labels: ''
assignees: ''

---

## New Functionalities Description

## New Attributes

|attribute name| default value|
|----|---|
|new.attr.1|0|
|new.attr.2|NA|

## New Parameter

|parameter name| default value|
|----|---|
|new.param.1|10|
|new.param.2|0.004|

## Checklist

- [ ] new parameters are in `inst/model_parameters.csv`  [wiki](https://github.com/EpiModel/EpiModeling/wiki/EpiModelHIV-%E2%80%90-New-Parameters-and-Attributes#adding-new-parameters)
- [ ] new attributes have their default values set [wiki](https://github.com/EpiModel/EpiModeling/wiki/EpiModelHIV-%E2%80%90-New-Parameters-and-Attributes#adding-new-attributes)
- [ ] the code respects the [EpiModelHIV Code Conventions](https://github.com/EpiModel/EpiModeling/wiki/EpiModelHIV-%E2%80%90-code-conventions)
- [ ] new module is added to `control_msm`
- [ ] model run with default values without crashing
- [ ] model run with extreme values and produces coherent outcomes
