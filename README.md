# ploch-github-actions

Shared GitHub Actions for the MrPloch organisation.

| Action | Purpose |
|---|---|
| [`build-test-sonar`](#build-test-sonar) | Build and test a .NET solution and run SonarCloud analysis |
| `build-test-snar-ps` | PowerShell script variant of the above |
| `test-script-action` | Scratch action used to exercise script steps |

## build-test-sonar

Restores, builds and tests a .NET solution, collects Coverlet coverage, and wraps the
build in a SonarCloud analysis so pull requests are decorated with the quality gate
result and inline annotations.

### Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # required — see below

      - name: Get build version
        id: version
        run: echo "value=$(dotnet nbgv get-version --variable NuGetPackageVersion)" >> "$GITHUB_OUTPUT"

      - uses: mrploch/ploch-github-actions/build-test-sonar@main
        with:
          solution-path: ./Ploch.Example.slnx
          sonar-project-key: mrploch_ploch-example
          sonar-organization: ${{ vars.SONAR_ORGANIZATION }}
          sonar-token: ${{ secrets.SONAR_TOKEN }}
          sonar-project-version: ${{ steps.version.outputs.value }}
```

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `solution-path` | yes | — | Solution to build and test. |
| `sonar-project-key` | yes | — | SonarCloud project key. |
| `sonar-organization` | yes | — | SonarCloud organisation. |
| `sonar-token` | yes | — | SonarCloud token. May be empty on a fork pull request — see [Fork pull requests](#fork-pull-requests). |
| `dotnet-version` | no | `9.0.x` | Passed straight to `actions/setup-dotnet`; a `global.json` in the consuming repo is never consulted. Set explicitly when targeting another framework (for example `net10.0`). |
| `sonar-url` | no | `https://sonarcloud.io` | Override to point at a self-hosted SonarQube Server. |
| `sonar-project-version` | no | *(empty)* | Reported as `sonar.projectVersion`. **Strongly recommended** — see [Project version](#project-version). |
| `sonar-coverage-exclusions` | no | test projects, scripts, generated annotations | Comma-separated globs passed as `sonar.coverage.exclusions`. Pass `''` to disable. |

### Requirements

#### `fetch-depth: 0` on checkout

The caller **must** check out with full history:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

SonarCloud derives new-code attribution from git blame. With the default shallow
clone, blame data is missing and the analysis cannot tell new code from old.

#### Automatic Analysis must be disabled

CI-based analysis and SonarCloud's Automatic Analysis are mutually exclusive per
project. Leaving Automatic Analysis enabled causes the two to overwrite each other.
Disable it in the project's **Administration → Analysis Method** settings.

### Project version

Without `sonar-project-version`, SonarCloud's **"Previous version"** new-code
definition has no version history to diff against, so every analysis treats the
entire baseline as new code and the new-code quality gate becomes meaningless.

Supply the build version — for repositories using Nerdbank.GitVersioning:

```yaml
- id: version
  run: echo "value=$(dotnet nbgv get-version --variable NuGetPackageVersion)" >> "$GITHUB_OUTPUT"
```

### Fork and Dependabot pull requests

GitHub withholds ordinary Actions secrets from two kinds of pull request:

- those raised from a **fork**, and
- those authored by **Dependabot** — note these run from a branch in *this*
  repository, so a `head.repo.full_name` test alone does not detect them.

`sonar-token` is legitimately empty in both cases. The action **skips the SonarCloud
steps with a warning and still runs build and test**, rather than failing the whole
check.

| Token | Pull request | Outcome |
|---|---|---|
| present | any | analysis runs |
| absent | fork, or Dependabot-authored | `::warning::`, scanner skipped, build and test still run |
| absent | anything else | `::error::`, job fails |

An empty token on an ordinary run is treated as a misconfiguration and fails the job
— silently analysing anonymously produces a misleading
`Not authorized or project not found` much later in the run.

### Coverage

Tests run with Coverlet's MSBuild integration, emitting both Cobertura and OpenCover
into `./CoverageResults/`. The OpenCover report is handed to SonarCloud via
`sonar.cs.opencover.reportsPaths` using the glob `coverage*.opencover.xml` — for
multi-project solutions Coverlet emits one file per assembly, so an exact filename
would silently miss most of the coverage.

### Notes

- `SonarScanner End` runs even when the build or tests fail, so the analysis opened
  by `begin` is always closed out and the pull request is still decorated.
- A green `SonarQube Cloud` check means the **quality gate** passed, not that there
  are zero new issues — issues below the gate threshold do not fail it.
