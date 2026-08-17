---
name: migrations
description: Rules for writing and reviewing Laravel migrations and schema changes. Applies whenever database structure is added, altered, or removed.
paths: database/migrations/**, database/factories/**, app/Models/**
---

Standing rules for schema change. These apply for the rest of the task.

- Never edit a migration that already ran in a shared environment. Write a new one.
- Every migration needs a working `down()`. If genuinely irreversible, say so
  rather than leaving it empty.
- Index every foreign key. Name constraints explicitly on large tables.
- Flag anything that locks a big table and propose the multi-step version:
  add nullable, backfill in a job, then enforce.
- A schema change is not done until the migration, the factory, the model
  casts, and any affected Data object are updated in the same commit. The
  TypeScript type follows from the Data object automatically — never edit it
  by hand.
- Verify with `php artisan migrate --pretend` and `migrate:status`. Report the
  SQL and the rollback path before applying.
- Never run `migrate:fresh`, `migrate:reset`, or `db:wipe`.
