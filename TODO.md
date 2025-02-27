# TODO

This is a bit lighter-weight than using GH issues, and will do for now (while
we're building it out & exploring the problem space).

- add a new GH action which runs the tests

- instead of variable.voted?, could do variable.vote_id (and then use that to
  determine if the user has voted) update: Schmidty changed this to be a string
  with the type, which is maybe better, or maybe worse (need to think about it)

- faciliator view which which lists all curerntly-connected participants (the
  (Docs)[https://hexdocs.pm/phoenix/presence.html#usage-with-liveview] have an
  example of doing just this we could use as a staring point)

- add policies/authorizations

- there might be more examples to use streams instead of just list assigns in
  the various Phase live components

- can we do the "add facilitator? boolean to join table" purely via a manage
  relationship?

- could add a function component for the 2/3 column layout (with first_col and
  second_col slots)

- thought: the LLM stuff should either be %Variable{} aware, or no (but
  consistent in both input & output)

- (maybe) use [this](https://docs.rs/graph-cycles/latest/graph_cycles/) for
  cycle detection (via rustler) but honestly we might just hand-roll something
  naive

- Removing a vote is kind of gross at the moment, as you need to pass the whole
  vote to the destroy function. This is particularly annoying in the identify
  phase, as we the votes aren't loaded at any point before needing to destroy
  them.

- We sort the voted variables server side in the voting view when completed -
  might be better to do client side?

- The help modal should be separated into its own component, or use the .modal -
  I tried the latter, but there were server-side events triggering, so it's bit
  of a mess.

- The presence module {complete, total} calculation uses the current phases to swap
  between the participant being finished count, and the number of votes count - I feel
  there'd be a better way? Also, we start with the progress value unloaded, so it shows
  0% always until someone votes, even if many votes exist.

- There's repetition between the relationship overwrites and the loop relationship modal
  we could refactor
