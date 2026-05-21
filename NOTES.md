# Project Notes

A 2D top-down adventure game built in Godot 4 (macOS, PlayStation controller). Hobby project. Eventual premise: techno DJ in a fantasy nature setting — woodland creatures dance to your beats. Currently building foundational systems (gather, vendor, quest, zones) before tackling the DJ minigame.

## Vision (one paragraph, may evolve)

Player gathers resources in zones, sells/buys with vendors, completes NPC quests for gold and items. Eventually performs at venues with a sequencer/rhythm minigame where audience (woodland creatures) reacts to performance. The current build is the foundation game — gameplay loop without the DJ centerpiece yet.

## Architecture

### Autoloads
- **PlayerData** — inventory (Dictionary[Item, int]), gold, related signals (item_added, item_removed, gold_changed). Persistent across zones.
- **QuestLog** — quest state per id (NOT_STARTED, ACTIVE, READY, TURNED_IN). Auto-promotes/demotes based on PlayerData signals.
- **ZoneManager** — owns current_zone, zone_container, player references. Handles change_zone, spawn point placement, camera bounds application.

### Scene hierarchy
```
Main (Node2D)
├── ZoneContainer (Node2D) — holds whatever zone is current
│   └── (current Zone instance, swapped on transitions)
├── Player (CharacterBody2D + Camera2D) — persists across zones
└── UI (Node container)
	├── GameMenu (CanvasLayer) — unified modal: inventory + quests tabs
	├── DialogueUI (CanvasLayer)
	└── VendorUI (CanvasLayer)
```

### Zone pattern
- `zone.tscn` is the base scene (script `zone.gd`, `class_name Zone`). Contains containers: HarvestNodes, HarvestNodeMarkers, WorldItems, NPCs, PlayerSpawns/DefaultPlayerSpawn.
- Specific zones (`bidwell_square.tscn`, `wakeup_house.tscn`, etc.) are inherited scenes from `zone.tscn`. They add their own TileMapLayer, content, doors.
- Each zone provides `get_camera_bounds()` so ZoneManager can clamp the camera.

### Interactable pattern
Three-layer scene inheritance:
- `interactable.tscn` (Area2D + InteractBox CollisionShape on layer 5, mask 1, `interactable.gd` base script)
- `npc.tscn` (inherits interactable; adds InteractIndicator chat-bubble Sprite2D; `npc.gd` with quest/dialogue/vendor_inventory fields)
- Per-NPC scenes (e.g., `aldwin_smith.tscn`, `feydor.tscn`) inherit npc.tscn and add their unique Sprite2D
- HarvestNode also extends interactable.gd, has its own shader-aura indicator

Player has an Area2D InteractBox on layer 5 (no mask) that interactables detect. Player's body is layer 1 for world collision. Player.interact_target is set by Interactable when overlap entered.

### NPC services
NPC may have any combination of `dialogue` (chat), `quest`, `vendor_inventory`. `talk_to(player)` computes available services:
- 0 services → no interaction (player stays IDLE)
- 1 service → route directly (no menu)
- 2+ services → procedurally generate a service-menu Dialogue at runtime ("What can I help you with?") with choices for each service

Quest service routes dialogue by quest state (offer/in_progress/turn_in/completed) via Quest's four dialogue fields.

### Resource-vs-instance pattern
Recurring decision throughout: shared definitions vs per-placement state.
- Items, HarvestNodeTypes, Quests, SpawnProfiles, Dialogues, etc. — shared `.tres` files, referenced by many things.
- SpawnWeight (inside markers) — `resource_local_to_scene = true` so each marker has its own.
- Materials with shader state (HarvestNode's outline) — duplicated in _ready so each instance is independent.

### Modal UI patterns
- GameMenu pauses the tree (`get_tree().paused = true`); has process_mode = Always.
- DialogueUI and VendorUI freeze player via state machine (TALKING / VENDORING) rather than tree pause. Either works; mixing is fine.
- All modals call `get_viewport().gui_release_focus()` on close to avoid stale focus pollution.
- Input handling in modals uses `_input` with explicit allow-list for ui_* navigation actions; everything else is consumed via `set_input_as_handled()` so it doesn't leak to gameplay.

### Door / zone transitions
Door is Area2D with `target_zone_path` (file path string, not PackedScene reference — avoids circular load issues) and `target_spawn_name`. On player overlap, `ZoneManager.change_zone.call_deferred(...)` runs to avoid mutating physics state mid-frame.

## Naming conventions

- Scripts: snake_case files, PascalCase class_name.
- Per-quest folders: `quests/gather_copper/` with quest tres, dialogue tres, etc. all together.
- Resource prefixes when sharing folders: `objective_gather.gd`, `reward_gold.gd`.
- Item IDs: snake_case strings, stable once used (don't rename).
- Spawn point names: PascalCase Marker2D nodes (e.g., `DefaultPlayerSpawn`, `EntranceSpawn`).

## Quirks / things to know

- Quest registration: each new quest must be registered in `main.gd._ready` (`QuestLog.register_quest(preload(...))`). Auto-loader exists in the backlog but not built; forgetting causes the quest to appear missing from the log.
- Test inventory seeded in `PlayerData._ready` via `_seed_test_inventory` guarded by `OS.is_debug_build()`. Edit there to change starting state.
- Camera bounds account for TileMapLayer scale — see `zone.gd.get_camera_bounds`.
- `_clear_choices` in DialogueUI uses `remove_child` + `queue_free` (not just `queue_free`) because queue_free doesn't take effect until end of frame, and chained dialogues need the container empty immediately.
- DialogueUI `_on_choice_pressed` only closes for terminal actions (`close`, `open_vendor`, `accept_quest`, `turn_in_quest`). Chaining actions like `open_quest`, `open_chat` swap the dialogue content without closing.
- TileSet collision shapes: per-tile in the TileSet editor (Physics Layer 0). Decor (tables, plants, torches) gets collision; rugs and ground decor stay walkable.

## Current state (features working)

- Player movement, animation by facing direction, state machine (IDLE/WALKING/MINING/TALKING/VENDORING)
- Harvest nodes via markers with weighted spawn profiles, drop tables with chance/quantity variability, settle-and-magnet pickup
- Inventory data layer with PlayerData autoload, signals
- Gold currency, HUD overlay, gold coin pickups (Currency extends Item)
- Vendor (sell from player, buy from vendor) with two-grid UI
- Dialogue system: lines, choices, portraits, controller navigation
- Quest system: offer/accept/track/turn-in/completed lifecycle, auto state promotion/demotion, rewards on turn-in, items consumed on turn-in
- Multi-service NPCs with procedurally generated service menu
- GameMenu (Triangle) with tab navigation (L1/R1): inventory tab + quest tab
- Zone transitions via doors
- Reward display in quest dialogues

## Backlog

### Near-term polish
- Quest HUD — small persistent indicator of active quest objective
- Quest auto-registration scanning `res://quests/` instead of hardcoded list in main.gd
- Quest item flag on Item, decoration in inventory/vendor cells, vendor blocking sale of quest items
- Default "Goodbye" choice on Dialogues so authors only add non-default choices
- Multi-quantity transactions in vendor (shift to sell 10, sell-all)
- "Not enough gold" feedback in vendor
- Sort order in inventory grid (currently insertion order)
- Pickup notifications ("+3 stone" floating text)

### Medium-term features
- Equipment slots (probably DJ equipment specifically, not character armor)
- Mob spawning, simple combat ("slash at things while collecting herbs")
- Save/load to disk
- More zones, more content
- Per-zone persistence (remember harvested state, etc.)
- Minimap with harvest node tracking

### Larger / longer-term
- DJ minigame (the actual game premise, deferred until DJ-friend consultation is possible)
- Branching dialogue (graph instead of list+choices)
- Quest prerequisites and quest chains
- Conditional dialogue based on game state
- NPC schedules / movement
- Music / SFX system

## Done

- Player movement with state machine
- Harvest node interaction with shader outline indicator
- Harvest node markers with weighted spawn profiles
- Drop tables with chance/quantity ranges
- World items with arc-and-settle physics and grace period before lootable
- Inventory data + UI
- Gold currency + HUD overlay
- Currency as Item subclass; coin pickups route to gold
- Vendor system (sell and buy) with two-grid UI
- @tool pattern for editor-time visuals (markers, world items)
- Interactable base class + npc inheritance + per-NPC inherited scenes
- Dialogue UI with lines, choices, portraits
- Service menu generation for multi-service NPCs
- Quest system end-to-end
- Quest log UI in tabbed GameMenu
- Zone refactor (Player extracted from Zone, ZoneManager autoload)
- Door transitions between zones with deferred change to avoid physics conflicts
- Camera bounds per-zone via get_camera_bounds
- Reward display in quest dialogues
