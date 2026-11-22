# AGENTS.md

`org.coldis:configuration`, the Maven parent POM of the coldis projects (GitHub
`coldis-org/configuration`). It pins Java (21), dependency and plugin versions, and wires the
shared build: annotation processing, AspectJ weaving, Hibernate enhancement, Surefire, JaCoCo,
Spring Boot repackaging, Docker image build/push (exec-maven-plugin), release and Maven Central
publishing. Every coldis library and infrastructure repository, and `supersim-configuration`,
inherit from it.

## Layout

| Path | Holds |
|------|-------|
| `pom.xml` | The parent POM (`packaging` `pom`): `project.config.*` switches, `*.version` properties, `dependencyManagement`, plugins, `release` profile |
| `artifact.properties`, `artifact_properties.groovy` | Filtered into `target/` of every child: `ARTIFACT_GROUP_ID`, `ARTIFACT_ARTIFACT_ID`, `ARTIFACT_VERSION` |
| `config/cleanup.xml`, `config/codetemplates.xml` | Eclipse clean-up profile and code templates (`coldis`) |
| `config/lifecycle-metadata-mapping.xml` | m2e lifecycle mapping for the build plugins |
| `config/settings.xml` | Maven `settings.xml` template for `coldis-public-software-repository` (empty password) |
| `config/test` | A `git filter-branch` script that rewrites author/committer e-mails |
| `docs/updating-dependent-projects.md` | How to propagate a release to the dependent projects |

## Commands

```bash
mvn clean install > build.log 2>&1
mvn release:clean release:prepare release:perform
```

Send Maven output to a file and read it afterwards. After a release, follow
`docs/updating-dependent-projects.md` to bump `<parent>` in the dependents.

## Gotchas

- **Every change ships to every child** on its next parent bump: coldis libraries, coldis
  infrastructure repositories and, through `supersim-configuration`, the SuperSim services. Name any
  changed default, version or plugin binding in the PR description.
- **Optional steps are off by default.** Plugin executions are bound to `project.config.*.phase`
  properties that default to `none` (Docker build/push, assembly, JaCoCo, Spring Boot repackage,
  load-time weaving); children turn them on by setting the property. `zzz` is the "exclude nothing"
  placeholder for the include/exclude properties.
- **Docker images are built by an external command.** `docker-build`, `docker-push-latest` and the
  `release` profile's `docker-push-release` run `operational_utils_docker_build_modules`, which must
  be on the `PATH` of whoever builds; they also need `project.config.infrastructure.*.path`.
- **Releases skip tests:** `project.config.release.arguments` is
  `-DskipTests -Dnet.bytebuddy.experimental=true -Dmaven.deploy.skip=true`; publishing goes through
  `central-publishing-maven-plugin` with `autoPublish`. The `release` profile adds sources, javadocs
  and GPG signing.
- **Maven 3.9.0 or later:** `maven-enforcer-plugin` fails every build on an older Maven, because
  `exec-maven-plugin` 3.7.0 and `aspectj-maven-plugin` 1.17.0 require it.
- **`maven-release-plugin` is pinned to `3.1.1`:** `3.3.1` breaks `release:prepare` ("Project tag
  cannot be selected if version is not yet mapped").

## Conventions

- Versions live in `<properties>` as `<name>.version` (`maven.<plugin>.version` for plugins) and are
  referenced from `dependencyManagement` and the plugins; don't inline versions.
- Behaviour a child may change is exposed as a `project.config.*` property, not by overriding the
  plugin.
- Dependency-bump commits in the dependents use `- Updating dependencies; Signed-off-by: ...` and
  stage only `pom.xml` (see the docs).

## Workspace

This repository expects `supersim-infrastructure-code-reviewer` checked out next to it
(`../supersim-infrastructure-code-reviewer`; clone it there from the internal Git host if it's
missing). The review-gate summary and the local review both live in it.

## Review

The gates are those of `src/agents/review/review.toml`, read from master, so a branch can't weaken
its own review: `security`, `platform-runtime` and `platform-config`. What each gate stops:
`../supersim-infrastructure-code-reviewer/local-review/GATES.md`. `platform-config` reads
`config/*.xml` and `artifact.properties`, and `platform-runtime` reads `artifact_properties.groovy`.
`pom.xml` is excluded from `platform-config` by design, so the POM, which is most of this
repository (versions, plugin bindings, the image build/push), is reviewed by `security` only, as
are `docs/` and `config/test`. The PR description must name every version, default, plugin binding
and image build/push setting changed.

Before pushing, run the local review: follow
`../supersim-infrastructure-code-reviewer/local-review/REVIEW.md`. It ends with
`local-check attest`. Push only when the developer asks.
