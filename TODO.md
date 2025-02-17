# TODO

This is a bit lighter-weight than using GH issues, and will do for now (while
we're building it out & exploring the problem space).

- add the "facilitator's vote wins" behaviour in the relationship voting

- add cytoscape

- sort out generate variables input counter component

- rename rel types to direct/inverse

- instead of variable.voted?, could do variable.vote_id (and then use that to
  determine if the user has voted)

- faciliator view which which lists all curerntly-connected participants (the
  (Docs)[https://hexdocs.pm/phoenix/presence.html#usage-with-liveview] have an
  example of doing just this we could use as a staring point)

- add policies/authorizations

- could add a function component for the 2/3 column layout (with first_col and
  second_col slots)

## Route/LiveView re-org

- we'll re-do the pubsub stuff, as per yesterday's discussion

- thought: the LLM stuff should either be %Variable{} aware, or no (but
  consistent in both input & output)

## Libraries we'll use

- Phoenix LiveView (for web stuff)
- Ash & AshPhoenix (for data modelling)
- SaladUI
- [PhoenixTest](https://hexdocs.pm/phoenix_test/PhoenixTest.html) (and hopefully
  PhoenixTestPlaywright) for front-end testing
- [cytoscape.js](https://js.cytoscape.org) (in a phoenix hook) for rendering the
  diagrams
- AshAuthentication (with passwords, maybe even magic links?) for auth
- [InstructorLite](https://hexdocs.pm/instructor_lite/readme.html) for
  platform-agnostic API use
- LiteFS for "hosted SQLite"
- (maybe) use [this](https://docs.rs/graph-cycles/latest/graph_cycles/) for
  cycle detection (via rustler) but honestly we might just hand-roll something
  naive

## generator invocations

as an example:

```
mix ash.gen.resource \
  Revelo.Diagrams.Variable \
  --uuid-primary-key id \
  --timestamps \
  --default-actions read \
  --attribute "name:string:required,description:string:required,voi?:boolean:required,included?:boolean:required" \
  --relationship "belongs_to:session:Revelo.Sessions.Session:required,has_many:votes:Revelo.Diagrams.VariableVote"
```

## adrian's gross things

- Removing a vote is kind of gross at the moment, as you need to pass the whole
  vote to the destroy function. This is particularly annoying in the identify
  phase, as we the votes aren't loaded at any point before needing to destroy
  them.

- We should change the style of the relationship votes table, as it's a bit
  confusing and large.

- We sort the voted variables server side in the voting view when completed - might be better to do client side?
