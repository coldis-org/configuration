# Updating Dependent Projects After a Configuration Release

This guide describes how to propagate a new `org.coldis:configuration` release to all dependent projects.

## Prerequisites

- All dependent project repositories cloned under the same parent directory (e.g., `~/Workspaces/supersim/`)
- Git configured with push access to all repositories
- The new configuration version has been released (not a SNAPSHOT)

## 1. Identify the released version

After running `mvn release:clean release:prepare release:perform` on `coldis-configuration`, check the released version:

```bash
git log --oneline -3
```

Look for the `[maven-release-plugin] prepare release configuration-X.Y.Z` commit. The version `X.Y.Z` is the one to propagate.

## 2. Find dependent projects

Search for all projects that reference `org.coldis:configuration` as a parent:

```bash
BASE=~/Workspaces/supersim
grep -rl "<artifactId>configuration</artifactId>" $BASE/*/pom.xml \
  | xargs grep -l "org.coldis" \
  | grep -v coldis-configuration/pom.xml
```

This will find both direct dependents (coldis-* projects) and `supersim-configuration` (which extends `org.coldis:configuration` and re-exports as `br.com.supersim:configuration`).

## 3. Update each project

For each project found in step 2:

### a. Ensure you are on master

```bash
cd <project-directory>
git branch --show-current
# If not on master:
git stash  # if there are uncommitted changes
git checkout master
git stash pop  # restore changes if needed
```

### b. Update the parent version in `pom.xml`

Edit the `<parent>` block to reference the new version:

```xml
<parent>
    <groupId>org.coldis</groupId>
    <artifactId>configuration</artifactId>
    <version>X.Y.Z</version>  <!-- Update this -->
</parent>
```

### c. Commit and push

```bash
git add pom.xml
git commit -m "- Updating dependencies; Signed-off-by: rvcoutinho <me@rvcoutinho.com>"
# If remote has new commits:
git stash        # stash any non-pom changes
git pull --rebase
git stash pop
git push
```

## 4. Propagate to supersim-* projects (indirect dependents)

After updating and releasing `supersim-configuration`, the supersim-* service projects that use `br.com.supersim:configuration` as parent will pick up the changes on their next release. These projects do **not** need a parent version bump unless you want them to use the new configuration immediately.

## 5. Updating individual library versions

When a specific coldis library is released (e.g., `service-client`), find its dependents:

```bash
grep -rl "<artifactId>service-client</artifactId>" $BASE/*/pom.xml \
  | grep -v coldis-library-java-service-client/pom.xml
```

Then update the `<version>` tag for that dependency in each project and commit/push as above.

## Notes

- The `maven-release-plugin` version is pinned to `3.1.1`. Version `3.3.1` has a regression ("Project tag cannot be selected if version is not yet mapped") that breaks `release:prepare`.
- Projects with pre-existing uncommitted changes: only stage `pom.xml` for the dependency update commit. Use `git stash` / `git stash pop` around `git pull --rebase` to preserve other changes.
