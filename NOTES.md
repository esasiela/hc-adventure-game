# Project Notes

A 2D top-down adventure game built in Godot 4 (macOS, PlayStation controller). Hobby project. Eventual premise: techno DJ in a fantasy nature setting — woodland creatures dance to your beats. Currently building foundational systems (gather, vendor, quest, zones) before tackling the DJ minigame.

## Vision (one paragraph, may evolve)

Player gathers resources in zones, sells/buys with vendors, completes NPC quests for gold and items. Eventually performs at venues with a sequencer/rhythm minigame where audience (woodland creatures) reacts to performance. The current build is the foundation game — gameplay loop without the DJ centerpiece yet.

## Architecture

### Autoloads
- **PlayerData** — inventory (Dictionary[Item, int]), gold, related signals (item_added, item_removed, gold_changed, gold_added, gold_spent). Persistent across zones.
- **QuestLog** — quest state per id (NOT_STARTED, ACTIVE, READY, TURNED_IN). Holds `_active_quests` (id → runtime Quest) and `_quest_history` (id → terminal state). Quest enum lives on Quest, referenced as `Quest.QuestState`.
- **ZoneManager** — owns current_zone, zone_container, player, minimap references. Handles change_zone, spawn point placement, camera bounds application (both player camera and minimap camera).
- **DialogueUI** — autoload scene. The UI is globally addressable; callers do `DialogueUI.start(npc, dialogue, quest)`.
- **FloatingText** — spawner singleton. `FloatingText.spawn(text, world_pos, style)` where style is enum (LOOT, GOLD, CELEBRATION).

### Scene hierarchy
```
Main (Node2D)
├── ZoneContainer (Node2D) — holds whatever zone is current
│   └── (current Zone instance, swapped on transitions)
├── Player (CharacterBody2D + Camera2D) — persists across zones
├── Minimap (CanvasLayer) — in-tree, shares world_2d with main viewport
└── UI (Node container)
├── GameMenu (CanvasLayer)
└── VendorUI (CanvasLayer)
```

DialogueUI is an autoload scene, not under UI.

### Zone pattern
- `zone.tscn` is the base scene (script `zone.gd`, `class_name Zone`). Contains containers: HarvestNodes, HarvestNodeMarkers, WorldItems, NPCs, RoadSigns, PlayerSpawns/DefaultPlayerSpawn.
- Specific zones are inherited scenes. They add their own TileMapLayer, content, doors.
- Each zone provides `get_camera_bounds()` so ZoneManager can clamp both cameras.

### Interactable pattern
Three-layer scene inheritance:
- `interactable.tscn` (Area2D + InteractBox on layer 5, mask 1, `interactable.gd` base)
- `npc.tscn` (inherits interactable; adds InteractIndicator, QuestWorldIndicator, QuestMinimapIndicator; `npc.gd` with `quest_templates: Array[Quest]`, dialogue, vendor_inventory, id, display_name, portrait fields)
- Per-NPC scenes inherit npc.tscn
- HarvestNode extends interactable.gd, has shader-aura indicator and a minimap-icon child

RoadSign also extends interactable but auto-shows a world-space PanelContainer label on enter, no press required.

### NPC services
NPC computes available services from non-null dialogue, _has_available_quests() (quest_templates with met preconditions or in non-NOT_STARTED state), and vendor_inventory.
- 0 → no interaction
- 1 → route directly (no menu)
- 2+ → load `service_menu_dialogue.tres` template, duplicate(true), filter choices by available services, present

Quest service: if multiple quests available, drill-down menu of quest titles, then state-aware dialogue (offer/in_progress/turn_in/completed) for the chosen one. Default fallback dialogues exist for null quest dialogue slots.

### Dialogue system
- `Dialogue` resource: `lines: Array[DialogueLine]`, `choices: Array[DialogueChoice]` (only shown on last line)
- Between-line continue prompt synthesized from `dialogue_choice_continue.tres`
- Goodbye auto-appended to last-line choices (UI-side, not authored per dialogue)
- DialogueUI signals: `dialogue_started(npc, dialogue, quest)`, `choice_selected(choice)`, `closed`
- Caller-driven choice routing: UI handles only `close` and `continue`; NPC handles `service_*`, `accept_quest`, `turn_in_quest`. Listeners connect in `talk_to`, disconnect on `closed`.
- Quest info panel inside DialogueUI scene shows title/description/objectives/rewards when a quest is passed to `start()`.

### Resource-vs-instance pattern
Quests use template/runtime split:
- NPCs hold `quest_templates: Array[Quest]` (authored .tres).
- `QuestLog.accept_quest` does `template.duplicate(true)` and stores the runtime instance in `_active_quests`.
- All reads of quest state (objectives, satisfaction, progress) must go through the runtime instance via QuestLog. Callers that have only a template should query `QuestLog.get_active_quest(id)` and fall back to template only for NOT_STARTED display.
- Objectives hold their own runtime state (`_satisfied`, `progress_qty`). Quest.activate_objectives() / deactivate_objectives() manages signal connections. Called on accept and turn-in.

Other shared resources (Items, HarvestNodeTypes, Dialogues, SpawnProfiles) stay shared. SpawnWeight is `resource_local_to_scene`. Materials with mutable state duplicated in _ready.

### Objectives
Base `Objective` resource. Subclasses:
- `GatherObjective` — listens to PlayerData item_added/removed in activate(), tracks progress_qty internally
- `TalkToObjective` — `target_npc_id: String`, listens to DialogueUI.dialogue_started in activate(), filters by npc.id

Signals: `progress_changed`, `satisfied_changed`. `is_satisfied()`, `get_progress_text()`.

### Quest preconditions
- `Quest.preconditions: Array[String]` (quest IDs).
- `Quest.are_preconditions_met()` checks each via QuestLog.get_state == TURNED_IN.
- NPC `_has_quest_interaction(quest)` returns true if state is non-NOT_STARTED, or NOT_STARTED with met preconditions. Used by has_interaction() and service menu building.

### Modal UI patterns
- All modals call `get_tree().paused = true/false` on open/close. DialogueUI process_mode = Always.
- Player `_unhandled_input` bails early when `DialogueUI.visible` to avoid double-bound input (e.g., E on both ui_accept and interact) racing with focused-button activation. Same pattern extends to other modals as they're built.
- Modal scripts use `_input` with explicit allow-list for ui_* navigation and consume the rest.
- All modals call `get_viewport().gui_release_focus()` on close.

### Minimap
- In-tree CanvasLayer (not autoload). Frame Panel top-right, SubViewportContainer → SubViewport → MinimapCamera.
- SubViewport shares `world_2d` with root viewport.
- Camera follows player in `_process`, clamped via ZoneManager's bounds.
- Visibility filtered by `canvas_cull_mask` on each viewport + `visibility_layer` on each CanvasItem:
  - Layer 1: shared (both cameras)
  - Layer 2: minimap-only (main viewport ignores)
  - Layer 3: world-only (minimap viewport ignores)
- Set in Minimap._ready: `get_tree().root.canvas_cull_mask &= ~(1<<1)` and `sub_viewport.canvas_cull_mask &= ~(1<<2)`. Layer names set in Project Settings → Layer Names → 2D Render.
- Tracked things (harvest nodes, NPC quest indicators) carry their own layer-2 Sprite2D child. Lifecycle is implicit — sprite lives and dies with its parent.

### Door / zone transitions
Door is Area2D with `target_zone_path` (file path string) and `target_spawn_name`. On player overlap, `ZoneManager.change_zone.call_deferred(...)` runs to avoid mutating physics mid-frame.

## Naming conventions

- Scripts: snake_case files, PascalCase class_name.
- Per-quest folders: `quests/gather_copper/` with quest tres, dialogue tres, etc.
- Resource prefixes when sharing folders: `objective_gather.gd`, `objective_talk_to.gd`, `reward_gold.gd`.
- Item IDs and quest IDs: snake_case strings, stable once used.
- Spawn point names: PascalCase Marker2D nodes.
- Quest variables: distinguish `template_quest` vs `runtime_quest` in code for clarity.

## Quirks / things to know

- Quest registration: each new quest must be registered in `main.gd._ready` (`QuestLog.register_quest(preload(...))`). Auto-loader still in backlog.
- Test inventory seeded in `PlayerData._ready` via `_seed_test_inventory` guarded by `OS.is_debug_build()`.
- Camera bounds account for TileMapLayer scale — see `zone.gd.get_camera_bounds`.
- DialogueUI `_clear_choices` uses `remove_child` + `queue_free` because chained dialogues need the container empty immediately.
- Window position pinned top-left via Editor Settings → run/window_placement/rect (not Project Settings; this is editor-only).
- World-space Controls (RoadSign label) need `pivot_offset` + position math after layout settles to anchor bottom-center; await one frame after visibility change before computing.
- Buttons created via `Button.new()` need their `pressed` signal connected programmatically; double-bound input (E on both ui_accept and interact) works as long as no other handler destroys the focused button during the press-release cycle.

## Current state (features working)

- Player movement, animation by facing direction, state machine (IDLE/WALKING/MINING/TALKING/VENDORING)
- Harvest nodes via markers with weighted spawn profiles, drop tables, settle-and-magnet pickup
- Inventory data layer with PlayerData autoload, signals
- Gold currency, HUD overlay, gold coin pickups
- Vendor (sell/buy) with two-grid UI
- Dialogue system: lines, choices, portraits, controller navigation, world pause, between-line continue prompts, auto-Goodbye, quest info panel
- Quest system: full lifecycle, runtime instance via duplicate(true), state on resources, GatherObjective + TalkToObjective, preconditions, multiple quests per NPC
- Multi-service NPCs with templated+filtered service menu
- GameMenu with tab navigation: inventory tab + quest tab
- Quest Overlay (persistent on-screen list of active quests with objective progress)
- NPC quest indicators in world (above head) and minimap (separate icons via visibility layers)
- Zone transitions via doors
- Minimap with harvest node tracking and zone-bounds clamping
- Floating text for loot (LOOT, GOLD styles) and quest completion (CELEBRATION)
- RoadSign auto-show label in world space when player enters range

## Backlog

### Near-term polish
- Quest auto-registration scanning `res://quests/`
- Quest validator (catch typo'd quest ids in preconditions, target_npc_id mismatches in TalkToObjective)
- Quest item flag on Item, decoration in inventory/vendor cells, vendor blocking sale of quest items
- Multi-quantity transactions in vendor (shift to sell 10, sell-all)
- "Not enough gold" feedback in vendor
- Sort order in inventory grid
- Floating text overlap jitter
- Auto-flex button column width in dialogue UI
- Per-objective-type display row in quest panel/overlay (richer than get_progress_text)
- Global "any modal open" abstraction (collapse the per-UI pause and player-input-bail calls)
- Per-zone validation at zone _ready

### Medium-term features
- Equipment slots (probably DJ equipment, not character armor)
- Mob spawning + stun-bean economy (gold→vendor→ammo→harvest tension loop)
- Save/load to disk
- More zones, more content
- Per-zone persistence (remember harvested state, quest history beyond current dict)
- Zone-global spawner with target_density (replacing per-marker timers)
- `dialogue_completed(npc, final_choice)` signal for stricter TalkTo variants
- Configurable minimap tracking (toggle harvest/NPC/vendor categories)
- Player marker on minimap (decide after authoring time)

### Larger / longer-term
- DJ minigame (the actual game premise)
- Branching dialogue (graph instead of list+choices)
- Conditional dialogue based on game state
- NPC schedules / movement
- Music / SFX system
- Day/night cycle, weather
- Companion pet for mob defense
- Data-driven quest system (json/db) replacing Resource-as-template

## Done

(includes all previous + this session)
- Player movement with state machine
- Harvest node interaction with shader outline indicator
- Harvest node markers with weighted spawn profiles
- Drop tables with chance/quantity ranges
- World items with arc-and-settle physics and grace period
- Inventory data + UI
- Gold currency + HUD overlay
- Currency as Item subclass; coin pickups route to gold
- Vendor system (sell and buy)
- @tool pattern for editor-time visuals
- Interactable base class + npc inheritance
- Dialogue UI rewritten with autoload pattern, signal-driven choice handling, world pause
- Service menu generation for multi-service NPCs
- Quest system end-to-end with runtime instance pattern
- Quest log UI in tabbed GameMenu
- Zone refactor (Player extracted, ZoneManager autoload)
- Door transitions
- Camera bounds per-zone
- Reward display in quest dialogues
- Quest info panel inside dialogue UI
- Quest Overlay (persistent on-screen)
- TalkToObjective with NPC id targeting
- Quest preconditions (string id array)
- NPC array of quests with drill-down menu
- Floating text system (loot, gold, celebration)
- Minimap with shared world_2d, cull-mask layering for icon visibility, harvest node and NPC quest tracking
- NPC `!` indicators in world and on minimap
- World pause on dialogue (via get_tree().paused)
- RoadSign auto-show world-space label
- Window position pinned for dev iteration
