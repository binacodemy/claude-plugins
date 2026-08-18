# core

Stack-agnostic workflow. Enable this everywhere; pair it with one stack plugin.

- `/core:commit` — reads the real diff, proposes a split when the work
  covers more than one concern, blocks debug statements and secrets.
- `/core:pr` — writes the description from the diff, follows a repo PR
  template when one exists.
- `/core:upgrade-deps` — security advisories first, then patch/minor,
  then majors one at a time.
- `@core:debugger` — reproduces before theorizing, forms competing
  hypotheses, reports evidence rather than a plausible story.

All three skills are user-invoked only. They have side effects, and you do not
want Claude deciding on its own to open a pull request.
