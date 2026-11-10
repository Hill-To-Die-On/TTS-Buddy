## What this changes

<!-- A sentence or two on what's different and why. Link the issue if there is one. -->

## How I checked it

<!-- The tests you added or ran, and any live checks in Tabletop Simulator. -->

## Checklist

- [ ] It's aimed at `dev`
- [ ] I wrote or updated a test first and watched it fail before the fix
- [ ] `npm test` passes
- [ ] Live checks that couldn't be automated are written up in `docs/validation.md`
- [ ] Buddy still only sees its own seat (hidden hands, deck order and private choices stay out of the model input, history and errors)
- [ ] Project Memory is updated if a fact, default or decision changed
- [ ] `CHANGELOG.md` has a line under Unreleased if players would notice
- [ ] No third-party game assets, Workshop saves or rulebook copies are included
