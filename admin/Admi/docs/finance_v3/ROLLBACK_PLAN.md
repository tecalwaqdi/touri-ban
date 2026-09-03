# Rollback Plan

1. Feature flags OFF for settlement writes / payment confirm / cash realization / future V3 writers.
2. Admin Hosting rollback to previous `version.json` artifact.
3. Functions rollback to previous release.
4. Do not reverse journal by deleting docs — use reverse entries if journals were posted.
5. Historical order fields remain untouched (rollback safe).
