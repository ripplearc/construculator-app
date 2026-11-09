## What and why
<!-- Two or three sentences on what changed and why. Ticket: CA-... -->

## Size
<!-- Lines changed in production code, without tests and generated files. -->
<!-- Count lib/**/*.dart only; leave out *.g.dart, *.freezed.dart and other generated files. -->

## How it was tested
<!-- The command you ran and its result. For a stacked PR, use the parent branch as --target. -->
`./scripts/run_check.sh --pre --target main` →

## Checklist
- [ ] I read the PR text again after the last change, and every sentence is still true.
- [ ] Every "later" or "out of scope" item has a CA ticket number.
- [ ] Every TODO has its own ticket and link.
- [ ] New public code has `///` docs.
- [ ] For a UI change: I compared the screen with the storyboard frame at the same size.
- [ ] I replied on every review thread with what I changed, or why I did not change it.
