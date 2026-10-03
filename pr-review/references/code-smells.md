# Code smells

A catalog of smells checked under the Clean Code, SOLID and DRY axes of
`SKILL.md`. A smell is **a signal to look closer, not a finding by itself**.
Each entry says what to look for, when it *is* a finding (there is a concrete
cost in this diff), and when it is only taste and must not be reported.

The evidence rule still applies: a smell becomes a finding only with
`file:line` and the concrete cost — the bug it invites, the change it makes
expensive, the reader it misleads.

---

## Bloaters

### Long function / large class

- **Look for:** a function past ~40 lines or a class that keeps gaining
  unrelated methods; several levels of abstraction mixed in one body.
- **A finding when:** the diff adds to it and the new code can't be understood
  or tested without reading the rest, or a bug in the change hides in the
  length (a branch that is unreachable, a variable reused far from where it
  was set).
- **Not a finding when:** it is long because it is a flat, linear sequence
  (a mapping, a builder, a migration) that reads top to bottom.

### Long parameter list

- **Look for:** more than ~4 parameters, especially several of the same type
  next to each other (`String, String, String`).
- **A finding when:** two same-typed parameters can be swapped by a caller
  without the compiler noticing, or the same group of parameters travels
  together through several functions (it wants to be a type).
- **Not a finding when:** the parameters are distinct types and the function
  is a constructor or factory for exactly those fields.

### Primitive obsession

- **Look for:** money as `double`, an ID as a bare `String`/`UUID` shared
  across entity kinds, a status as a free string, a tax ID/email/phone validated
  in several places instead of once in a type.
- **A finding when:** the diff validates or normalizes the same primitive in
  more than one place, or passes one kind of ID where another is expected
  and nothing catches it.
- **Not a finding when:** the value is used in one place and has no rules.

### Data clumps

- **Look for:** the same three or four fields always passed or stored
  together (street/district/postal code; amount/currency).
- **A finding when:** the diff adds another copy of the group, so a future
  change to it has to be made in every copy.

---

## Couplers

### Feature envy

- **Look for:** a method that reads mostly another object's fields to compute
  something about that object.
- **A finding when:** the rule it implements belongs to the other object's
  invariants and is now duplicated or can drift from it.
- **Not a finding when:** it is a mapper/DTO conversion whose job is to read
  another object.

### Inappropriate intimacy / leaking internals

- **Look for:** reaching into another module's internals, depending on a
  concrete class across a layer boundary, a test that asserts on private
  state.
- **A finding when:** it breaks a layering rule the repo enforces, or a
  refactor of the other module would now break this code for no reason.

### Message chains

- **Look for:** `a.getB().getC().getD()`.
- **A finding when:** any link can be null/absent and nothing handles it, or
  the chain encodes knowledge of a structure that is about to change.

---

## Change preventers

### Shotgun surgery

- **Look for:** one logical change that forced edits in many files with the
  same small modification each.
- **A finding when:** the next change of the same kind will need the same
  scattered edits — the rule wants a single home.

### Divergent change

- **Look for:** one module edited for unrelated reasons in the same PR
  (persistence, formatting and business rules together).
- **A finding when:** it is the "S" of SOLID failing in this diff: the module
  now has another reason to change.

### Temporal coupling

- **Look for:** methods that must be called in a specific order (`init()`
  before `run()`, `setX()` before `build()`), state that is valid only after
  a call.
- **A finding when:** calling them in the wrong order compiles and fails at
  runtime or, worse, silently produces wrong data. Prefer a constructor or a
  builder that makes the invalid order impossible.

---

## Dispensables

### Dead code, speculative generality

- **Look for:** unused parameters, branches, flags or abstractions "for the
  future"; an interface with a single implementation added "in case".
- **A finding when:** a reader has to understand it to change the code, or
  it hides that a case is not actually handled.
- **Not a finding when:** the repo's architecture requires the abstraction
  (e.g. a port interface in hexagonal architecture).

### Comments that apologize for code

- **Look for:** comments explaining *what* a confusing block does.
- **A finding when:** a rename or an extracted function would make the
  comment unnecessary and the comment is already out of date with the code.

### Duplicated knowledge

- **Look for:** the same rule (a regex, a limit, a list of allowed values)
  written in two places — including backend and frontend, or code and test
  data.
- **A finding when:** a change to the rule would have to be made in both and
  nothing fails if only one is changed. See the DRY axis for coincidental
  similarity, which is not this.

---

## Obfuscators

### Flag arguments

- **Look for:** a boolean parameter that switches what a function does
  (`render(true)`, `save(user, false)`).
- **A finding when:** call sites can't be read without opening the function,
  or the two behaviors have diverged enough to be two functions.

### Magic numbers and strings

- **Look for:** literal limits, timeouts, status codes or keys in the logic.
- **A finding when:** the same literal appears in more than one place, or its
  meaning isn't obvious and a wrong value would be silent.

### Misleading names

- **Look for:** a name that says less or something different than the code
  does (`validate()` that also saves, `isValid` that can throw, `list` that
  is a map).
- **A finding when:** a caller would use it wrongly on the strength of its
  name. This one is almost always a finding.

---

<!--
Template for the next entry — copy, fill in, keep it generalized.

### <smell name>

- **Look for:** <the signal in a diff>
- **A finding when:** <the concrete cost that makes it reportable>
- **Not a finding when:** <the case where it is only taste>
-->
