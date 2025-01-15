# TODO

This is a bit lighter-weight than using GH issues, and will do for now (while
we're building it out & exploring the problem space).

- tests
- code interfaces where appropriate
- UI stuff (including all liveviews)
- seeding new users for dev/test

- once things have settled down a bit, re-visit the use of default actions
  (maybe don't need a bunch of them)

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

```
mix ash.gen.resource \
  Revelo.Diagrams.Variable \
  --uuid-v7-primary-key id \
  --timestamps \
  --default-actions read \
  --attribute "name:string:required,description:string:required,voi?:boolean:required,included?:boolean:required" \
  --relationship "belongs_to:session:Revelo.Sessions.Session:required,has_many:votes:Revelo.Diagrams.VariableVote"

mix ash.gen.resource \
  Revelo.Diagrams.Relationship \
  --uuid-v7-primary-key id \
  --timestamps \
  --default-actions read \
  --attribute "description:string:required" \
  --relationship "belongs_to:session:Revelo.Sessions.Session:required,belongs_to:src:Revelo.Diagrams.Variable:required,belongs_to:dst:Revelo.Diagrams.Variable:required,has_many:votes:Revelo.Diagrams.RelationshipVote"

mix ash.gen.resource \
  Revelo.Diagrams.VariableVote \
  --timestamps \
  --default-actions read \
  --relationship "belongs_to:variable:Revelo.Diagrams.Variable:required"


mix ash.gen.resource \
  Revelo.Sessions.Session \
  --uuid-v7-primary-key id \
  --timestamps \
  --default-actions read \
  --attribute "name:string:required,description:string,report:string" \
  --relationship "has_many:context_docs:Revelo.Sessions.ContextDoc"

mix ash.gen.resource \
  Revelo.Diagrams.Loop \
  --uuid-v7-primary-key id \
  --timestamps \
  --default-actions read \
  --attribute "description:string" \
  --relationship "has_many:variables:Revelo.Diagrams.Variable,has_many:relationships:Revelo.Diagrams.Relationship"
```
