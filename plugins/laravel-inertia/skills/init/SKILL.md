---
name: init
description: Generate this project's .claude/CLAUDE.md from its actual dependencies and layout. Run once when adopting this plugin in a repo, and again after a major upgrade.
disable-model-invocation: true
allowed-tools: Bash(php ${CLAUDE_PLUGIN_ROOT}/bin/init-project.php *)
---

Run the generator, which detects versions and layout from composer.json,
package.json, and phpstan.neon:

```bash
php ${CLAUDE_PLUGIN_ROOT}/bin/init-project.php
```

It writes `.claude/CLAUDE.md`, backing up any existing file, and refuses to
overwrite one whose Conventions section has already been filled in.

Then do two things:

1. Read the generated header. `inertiajs/inertia-laravel` printed as
   `NOT INSTALLED` means this isn't actually an Inertia project — stop and
   tell me. `spatie/laravel-data` or the TypeScript transformer printed as
   `NOT INSTALLED` while the other is present is a real gap — tell me which.
2. Inspect the codebase and fill in the Conventions placeholders with what is
   actually true: where page controllers, domain logic, query objects, Data
   objects, generated types, and Inertia pages live. Cite the files each
   answer came from. Leave the final line ("the one thing a new developer
   always gets wrong") blank — only the user can write that one.

Do not invent structure that isn't there. If the project is new and a
convention hasn't been decided, delete that line rather than guessing.
