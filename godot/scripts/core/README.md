# Runtime Core Scripts

Place typed GDScript core classes here. These scripts should use data containers, RefCounted classes, and pure functions where practical.

Do not extend `Node` unless a thin adapter is required. Core rules must be callable from headless tests and simulation runners.

`GameCore` is the stable facade. Its deterministic dependencies are split by
responsibility: `command_rules`, `movement_rules`, `combat_rules`, `fog_rules`,
`state_hasher`, and `turn_resolver`. These services are scene-free and operate
only on serializable inputs; presentation and bot code may call the facade but
never mutate its state directly.
