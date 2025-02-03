# TODO

This is a bit lighter-weight than using GH issues, and will do for now (while
we're building it out & exploring the problem space).

- add tests to user flow which test the Presence stuff (but probably not until
  the route refactor described below)

- faciliator view which which lists all curerntly-connected participants (the
  (Docs)[https://hexdocs.pm/phoenix/presence.html#usage-with-liveview] have an
  example of doing just this we could use as a staring point)

- add policies/authorizations

## Route/LiveView re-org

The plan is:

- have a single `ReveloWeb.SessionLive.Prepare` LiveView module
- each `/sessions/:session_id/PHASE_NAME` route will use this module, with the
  specific phase specified as the live_action
- for the add/edit variable modals can use the same route, but include a
  `new_variable=` or `edit_variable=` query param, and the in `handle_params` we
  check for the existence of this param and (conditionally) display the modal

@Schmidty there are pros and cons to this approach vs the one you took, but I
think this is better - can explain in person (can't be arsed writing it out
here).

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

## general dev thoughts

- data model-wise, maybe we don't actually want a session -> participants (or
  even session -> users) relationship? could just get that info from the list of
  variables (via their :creator attribute)
