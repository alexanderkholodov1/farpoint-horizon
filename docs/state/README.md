# Project state, one note per topic

There is no single state file: several agents work at once, and a file that every piece edits is a conflict waiting to
happen (issue #28). The state is assembled when you ask for it:

    tools/state.sh

It prints the notes in this folder, the steps integrated on the version branch (from its history) and the open
issues with who holds each. Pending work lives in the issues, one per piece.

A note is one file per topic (`docs/state/<topic>.md`), for what an issue does not hold: priorities the team set,
facts that were verified, known problems. Write and keep the notes of your own pieces; never edit someone else's
(ask in their issue); delete a note when it stops being true.
