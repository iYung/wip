# Design: Scripted Character Spacing Increase

## Goal
Reduce scripted character frequency by raising trigger counts — characters currently appear too close together. Sir Moneyton (all chapters) and Agent Frogsby ch1 are exempt.

## Affected Files
- `lua/game/data/customer_scripts.lua` — all `trigger.count` values listed below

## What Stays the Same
All Sir Moneyton (`sage`) trigger counts and all character data (colors, accessories, messages, plant_type).
Agent Frogsby chapter 1: `{ plant_type = 2, count = 2 }`.

## Proposed Changes

### Agent Frogsby
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 2 | plant_type=2 | count=6 | count=9 |
| 3 | plant_type=4 | count=6 | count=9 |

### Mayor Bloom
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 1 | plant_type=3 | count=6 | count=9 |
| 2 | plant_type=3 | count=8 | count=12 |
| 3 | plant_type=3 | count=20 | count=30 |

### The Collector
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 1 | plant_type=5 | count=20 | count=30 |
| 2 | plant_type=6 | count=3 | count=5 |

### Mira
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 1 | plant_type=3 | count=4 | count=6 |
| 2 | plant_type=4 | count=2 | count=3 |

### Mechafrog
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 1 | plant_type=5 | count=2 | count=3 |
| 2 | plant_type=1 | count=40 | count=60 |
| 3 | plant_type=2 | count=24 | count=36 |

### Dottie
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 1 | plant_type=4 | count=2 | count=3 |
| 2 | plant_type=4 | count=4 | count=6 |
| 3 | plant_type=5 | count=3 | count=5 |

### Glen
| Chapter | Trigger | Current | Proposed |
|---------|---------|---------|---------|
| 1 | plant_type=2 | count=6 | count=9 |
| 2 | plant_type=4 | count=8 | count=12 |
| 3 | plant_type=5 | count=8 | count=12 |

## Notes
- All multipliers are 1.5x (50% increase), with half-values rounded up.
- All chapters within a character maintain increasing order.
