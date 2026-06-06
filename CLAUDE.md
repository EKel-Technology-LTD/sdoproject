# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A **Salesforce DX (SFDX) project** named `sdoproject`. It is currently a clean scaffold:
the metadata folders under `force-app/main/default/` (`classes`, `triggers`, `lwc`, `aura`,
`objects`, `layouts`, `flexipages`, `applications`, `tabs`, `permissionsets`,
`staticresources`, `contentassets`) exist but are **empty placeholders**. They define where
each metadata type goes once authored — do not assume code exists; check before referencing it.

- Single default package directory: `force-app` (see `sfdx-project.json`).
- API version: **66.0**, no namespace, login URL `https://login.salesforce.com`.
- This is **not a git repository** yet.

## Commands

All work goes through the Salesforce CLI (`sf`) and npm. There is no compile/bundle step —
"building" means deploying metadata to an org.

### Org & deploy/retrieve workflow
```bash
# Create a scratch org from the included definition
sf org create scratch -f config/project-scratch-def.json -a sdoScratch --set-default

# Push local source to / pull from the default org (scratch-org dev model)
sf project deploy start
sf project retrieve start

# Deploy/retrieve a specific path or the wildcard manifest
sf project deploy start -d force-app/main/default/classes
sf project deploy start -x manifest/package.xml   # package.xml retrieves ALL of the listed types (members = *)

# Run anonymous Apex / SOQL from the scratch files
sf apex run --file scripts/apex/hello.apex
sf data query --file scripts/soql/account.soql
```

### Tests — two SEPARATE pipelines
- **LWC / JavaScript tests** run locally via Jest (`sfdx-lwc-jest`):
  ```bash
  npm test                 # alias for test:unit
  npm run test:unit:watch  # watch mode
  npm run test:unit:coverage
  # Run a SINGLE test file or by name (args after `--` pass through to Jest):
  npm run test:unit -- force-app/main/default/lwc/myCmp/__tests__/myCmp.test.js
  npm run test:unit -- -t "renders the header"
  ```
- **Apex tests do NOT run locally.** They execute server-side in an org:
  ```bash
  sf apex run test --tests MyClassTest --result-format human --code-coverage
  sf apex run test --test-level RunLocalTests
  ```
  Keep this distinction in mind: `npm test` says nothing about Apex correctness.

### Lint & format
```bash
npm run lint              # ESLint over **/{aura,lwc}/**/*.js only
npm run prettier          # format cls/cmp/component/css/html/js/json/md/page/trigger/xml/yaml
npm run prettier:verify   # check formatting without writing
```

## Tooling architecture (non-obvious bits)

- **ESLint flat config** (`eslint.config.js`) applies rules *by file path*, not globally:
  - `**/aura/**/*.js` → Aura recommended + locker rules
  - `**/lwc/**/*.js` → `@salesforce/eslint-config-lwc/recommended`
  - `**/lwc/**/*.test.js` → same, but `no-unexpected-wire-adapter-usages` disabled
  - `**/jest-mocks/**/*.js` → Node/Jest globals + `@eslint/js` recommended
  JavaScript outside these paths is effectively unlinted. The `npm run lint` script only
  globs `aura`/`lwc` JS.

- **Prettier** uses `prettier-plugin-apex` (formats `.cls`/`.trigger`) and
  `@prettier/plugin-xml`; LWC HTML uses the `lwc` parser, classic `.cmp/.page/.component`
  use the `html` parser. `staticresources/`, `.sfdx`, `.sf`, `.localdevserver`, `.vscode`,
  and `coverage/` are excluded from formatting.

- **Pre-commit hook** (`.husky/pre-commit` → `npm run precommit` → `lint-staged`) runs on
  every commit:
  - Prettier `--write` on all supported staged files.
  - ESLint on staged `aura`/`lwc` JS.
  - `sfdx-lwc-jest --bail --findRelatedTests --passWithNoTests` on staged `lwc/**` files.
  Expect commits to reformat files and to fail if related LWC tests break.

- **Jest config** (`jest.config.js`) extends the sfdx-lwc-jest preset and ignores
  `.localdevserver`.

## Key directories

- `force-app/main/default/` — all deployable metadata (currently empty; populate per type).
- `manifest/package.xml` — wildcard manifest (`<members>*</members>` per type) for org-wide
  retrieve/deploy.
- `config/project-scratch-def.json` — scratch org shape (Developer edition).
- `scripts/apex/*.apex`, `scripts/soql/*.soql` — ad-hoc Apex/SOQL to run against an org.
- `.forceignore` — source files excluded from `sf project deploy/retrieve` (e.g.
  `package.xml`, `**/__tests__/**`, LWC `jsconfig.json`/`.eslintrc.json`).
