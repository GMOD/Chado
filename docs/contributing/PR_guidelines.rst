
Pull Requests (PRs)
=====================

The goal of this document is to make it easy for A) contributors to make pull requests that will be accepted, and B) Chado committers to determine if a pull request should be accepted.

Requirements for Changes
-------------------------

In order for a change to be appropriate for the full Chado community, **you should be able to answer yes to the following questions**:

- Is the proposed schema/change generic (not site specific)?
- Is it generally useful?
    - If the answer isn’t obviously yes, please provide a clear use case.
- Is your solution Performative?
    - Have you tested it on real data?
    - Have you tested it on large-scale datasets?
- Does your change maintain database integrity?
- Is your change Commented/Documented?
- Does your PR pass continuous integration (CI)?

Guidelines
------------

- All PRs MUST be linked to an issue.
    - This provides a means for the Chado community to weigh in on any changes.
- Issues must be open for 2 weeks before a PR is made.
    - Any objection will freeze this time period until it is resolved or retracted.
    - If an objection is made and clarification requested, it should be provided in a timely manner.
    - If the objection is unable to be resolved, the Chado Project Management Committee (PMC) will evaluate the concern. The PMC can override objections if it unanimously agrees.
    - Issues with no feedback after 10 days should be bumped letting community members know it needs discussion promptly.
- PRs require a minimum number of reviews before they are merged (number depends on the size of change).
    - Small Changes: 2+ reviews (1+ PMC review).
    - Medium Changes: 4+ reviews (2+ PMC reviews; 1+ Non-Tripal reviews).
    - Large Changes: 6+ reviews (5+ PMC reviews; 1+ Non-Tripal reviews).
    - Not all reviews need to be from PMC members, the community is encouraged to chime in!
    - Definitions for magnitude of changes are below.

Change Magnitude Definitions
------------------------------

The following definitions attempt to provide guidance as to the magnitude of the change to the Chado database through providing examples. However, they are not yet complete or exhaustive and may change as Chado governance evolves. If your change does not align with any of these examples, please justify where you feel it fits in the PR and the Chado PMC will vote based on that information.

Small Changes
^^^^^^^^^^^^^^^

- New index.
- Update to documentation.

Medium Changes
^^^^^^^^^^^^^^^^

- Adding a column to an existing table.
- Addition of a small "chado-esque" table (follows an existing template such as a prop or _cvterm table).
- New linking table.

Large Changes
^^^^^^^^^^^^^^^^

- Any non-backwards compatible changes.
- A new module (i.e. base table with associated linking tables).
- A large infrastructure change.
