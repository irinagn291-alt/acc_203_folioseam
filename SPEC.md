# Folioseam — Technical Specification

## 1. Store metadata

- **Name:** Folioseam
- **Bundle ID:** `com.folioseam.bind`
- **Subtitle:** Bind, restore, finish books.
- **Category:** Lifestyle / Productivity
- **Age rating:** 4+

## 2. Product goal

Offline bookbinding & restoration workflow desk: projects with stages, sections, material lots, and condition records. Exploded binding cross-section shows progress — not a reading journal.

## 3. Platform

- iOS 17.0+, Swift 6.2, SwiftUI, Core Data, Charts, Photos (optional)
- Clean Architecture + DI + AppCoordinator
- No SPM, no network, no widgets

## 4. Domain model

```
BindingProject    id, title, clientOrOwner, bindingStyle, openedAt, status, notes
BookSection       id, projectId, name, pageCount, orderIndex, sewn
MaterialLot       id, projectId, kind, name, quantity, unit, costCents, notes
StageTask         id, projectId, stage, title, orderIndex, done, doneAt?
ConditionRecord   id, projectId, phase (before/during/after), score, notes, photoPath?, recordedAt
```

Stages: fold → sew → glue → boards → covering → finishing → press

## 5. Formulas

- `stageProgress = doneStages / totalStages`
- `sectionProgress = sewnSections / totalSections`
- `projectProgress = 0.6*stageProgress + 0.4*sectionProgress`
- `conditionDelta = after.score − before.score` when both exist
- `materialSpend = sum(costCents)/100`

## 6. Signature UI

- Exploded binding cross-section (not letterpress folio)
- Stitch-topology progress
- Material swatches
- Custom spine navigation

## 7. Onboarding

1. Create BindingProject
2. Pick binding style + first StageTask
3. Add BookSection or MaterialLot → enter app

## 8. Acceptance

CRUD projects/sections/materials/stages/conditions, progress calc, optional photos, PDF/JSON export, formula tests.
