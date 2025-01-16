# TODO

This is a bit lighter-weight than using GH issues, and will do for now (while
we're building it out & exploring the problem space).

- the Users aren't hitting the db, hence the relationship not working. need to
  either get seed_generator actually creating the user, or to set up the
  changeset version (changes in flight, will return to it tomorrow)

- code interfaces where appropriate
- UI stuff (including all liveviews)
- seeding new users for dev/test

- once things have settled down a bit, re-visit the use of default actions
  (maybe don't need a bunch of them)

- sort out authorization and policies in general (maybe even org tenancy?)

- add a "create uuid on device and send on initial load" hook

## Libraries we'll use

- Phoenix LiveView (for web stuff)
- Ash & AshPhoenix (for data modelling)
- StreamData for property-based testing
- SaladUI
- PhoenixTest (and hopefully PhoenixTestPlaywright) for front-end testing
- mermaid.js (in a phoenix hook) for rendering the diagrams
- AshAuthentication (with passwords, maybe even magic links?) for auth
- [InstructorLite](https://hexdocs.pm/instructor_lite/readme.html) for
  platform-agnostic API use
- LiteFS for "hosted SQLite"

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
