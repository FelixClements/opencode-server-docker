# Fix: Upstream Release Checker GHCR API Issue

## Context
The `check-upstream-release.yml` workflow fails to detect previously built versions because:
1. GHCR packages are owned by users/orgs, not repos directly
2. The API endpoint `repos/{owner}/{repo}/packages/container/...` returns 404
3. Need to use a more reliable method to track built versions

## Plan

### Task 1: Fix version detection to use workflow runs API

**What to do**:
- Replace GHCR API call with GitHub Actions workflow runs API
- Query last successful runs to find upstream version that was built
- Update the check-release job logic

**Files**:
- `.github/workflows/check-upstream-release.yml`

**QA Scenarios**:

Scenario: Happy path - new version detected
  Tool: Bash (simulation)
  Preconditions: Last workflow run had upstream_version="v1.2.5", new release is "v1.2.6"
  Steps:
    1. Simulate API response with old run showing v1.2.5
    2. New upstream shows v1.2.6
    3. Verify should_build=true
  Expected Result: should_build=true, new_version=v1.2.6, old_version=v1.2.5
  Evidence: Console output showing version comparison

Scenario: No change - same version
  Tool: Bash (simulation)
  Preconditions: Last workflow run had upstream_version="v1.2.6", new release is "v1.2.6"
  Steps:
    1. Simulate API response with run showing v1.2.6
    2. New upstream shows v1.2.6
    3. Verify should_build=false
  Expected Result: should_build=false
  Evidence: Console output "No new version. Already at: v1.2.6"
