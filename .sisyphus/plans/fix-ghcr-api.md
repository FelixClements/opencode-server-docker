# Fix: GHCR API for listing container versions

## Context
User wants to check Docker image tags in their own GHCR repo. Previous attempts used wrong API endpoints.

## Plan

### Task 1: Fix GHCR API call

**What to do**: Use correct GHCR API endpoint for user-owned packages
- Endpoint: `GET /users/{owner}/packages/container/{package_name}/versions`
- Add `packages: read` permission back

**Files**: `.github/workflows/check-upstream-release.yml`

**QA Scenarios**:
- Verify API returns container version tags
- Verify upstream-* tag is detected correctly
