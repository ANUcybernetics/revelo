# TODO

This is a bit lighter-weight than using GH issues, and will do for now (while
we're building it out & exploring the problem space).

- add QR code component, look at
  (Panic!)[https://github.com/benswift/panic/blob/main/lib/panic_web/components/panic_components.ex#L235]
  if it helps

- modify auth_required hook to do the "create user if doesn't exist" thing

- liveview modules for identify, relate and analyse

- add (or modify the auth optional) on_mount hook so that if there's no user
  they get created (using uuid, also stored in localstorage) and logged in

- faciliator view which which lists all curerntly-connected participants (the
  (Docs)[https://hexdocs.pm/phoenix/presence.html#usage-with-liveview] have an
  example of doing just this we could use as a staring point)

- add the required logic to SessionServer to actually manage the session's
  progress

- add policies/authorizations

- sketch out notifications architecture (what gets broadcast, and to whom, and
  which views need what?)

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

- should we add phoenix storybook?
