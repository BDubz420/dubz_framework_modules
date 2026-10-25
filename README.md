# Dubz Framework Modules

A library of 37 ready-made modules for Garry's Mod DarkRP servers, built on the [Dubz Framework](https://github.com/BDubz420/dubz_framework). Characters, skills, inventory, jobs, shops, mining, cooking, a HUD, an F4 menu, a scoreboard, staff tools and more. They were written for and run on **Liminal RP**, and are released here for free so any server can use them.

Every module is its own addon. Take the ones you want, leave the rest. Everything is configurable in game from one admin menu, with no file editing.

## Highlights

- **One admin menu for everything.** Open `!dubzconfig`: every module has a page of sliders, switches, text boxes, colour pickers and editable tables. Changes are validated, saved and applied live.
- **One look across the server.** Windows, HUD, menus and overlays all use the framework's theme. Pick a preset or register your own and every module restyles.
- **Pick and choose.** 37 independent addons. Install five or all of them.
- **Built to work together.** Modules recognise each other and use each other when both are installed (skills level up your mining, the inventory carries your scrap, shops sell into your pocket).
- **Free to use and learn from.** The code is plain, small files in the framework's standard layout: a good reference for building your own.

## Requirements

- Some modules require a Garry's Mod server running **DarkRP**
- The **[Dubz Framework](https://github.com/BDubz420/dubz_framework)**, installed first

## Install

1. Install the [Dubz Framework](https://github.com/BDubz420/dubz_framework): copy it into `garrysmod/addons/` as `dubz_framework`.
2. Copy the module folders you want from this repository into `garrysmod/addons/`, beside the framework. Each folder is a complete addon.
3. Restart the server.
4. In game, as a superadmin, open **`!dubzconfig`** and configure each module. On the server console, `dfw_status` lists every module and whether it started.

Do not put gameplay modules inside the framework folder. Keep each one as a separate addon.

## Configure

Open `!dubzconfig`. Each installed module appears in the sidebar under its name. A page holds the module's settings in groups; modules with tables of things (shop stock, loot, titles, ranks) have an **Edit** button that opens a row editor. **Reset module** restores a module's defaults, and the Modules page switches any module off without uninstalling it.

## The modules

Folders link to the code. "Works with" lists other modules this one uses when they are installed.

### Core player systems

The foundations most other modules build on.

| Module | What it does | Works with |
| --- | --- | --- |
| [Characters](dubz_characters) | The start screen: pick or create a character (name, model, starting outfit) before spawning | Cosmetics |
| [Skills](dubz_skills) | Skill sheet, overall level, walking and running speed, and stamina | Characters |
| [Pocket & Backpack](dubz_inventory) | Pocket inventory, worn and ground backpacks, stacking, pickup, trading and weapon drops on death | Actions, Characters, Cosmetics |
| [Actions](dubz_actions) | First-person hands at work: animations, sounds and a progress bar for searching, scrapping and crafting | |
| [Cosmetics](dubz_cosmetics) | Accessories (worn props), the catalog and limited editions, clothing, store clerks and the placement editor | Characters, Credits, Inventory |
| [Karma & Commends](dubz_karma) | Karma from kills, arrests and play time, and the daily commend allowance | Characters |
| [Jobs](dubz_jobs) | Change job without a respawn (position, health, weapons and ammo carry over; the job changes the outfit), plus job-giver NPCs | Cosmetics, Inventory, NPC Life |

### Jobs and gathering

| Module | What it does | Works with |
| --- | --- | --- |
| [City Worker](dubz_cityworker) | A repair job: workers are sent to broken machines and street problems and fix them step by step with hand tools, with a placement tool for admins | Jobs, Scrap, Skills |
| [Mining](dubz_mining_system) | Rocks to break, gems and ore to find, a forge, a crafting table and a buyer | Actions, Characters, Cosmetics, Inventory, Jobs, Skills |
| [Cooking](dubz_cooking) | The cook's stove, donuts and golden donuts | Karma |
| [Scrap](dubz_scrap) | Trash from the dumpsters, scrapped into plastic, metal, cloth, leather and wood for crafting, melting and trading | Actions, Inventory, Skills |
| [Dumpsters](dubz_dumpster) | Searchable dumpsters: cooldown, junk, cash and item drops | Actions, Scrap |
| [Health & Armor Chargers](dubz_chargers) | Medic-owned chargers: price, owner cut, charge speed and rules | |

### Economy and shops

| Module | What it does | Works with |
| --- | --- | --- |
| [Shops](dubz_shops) | NPC shops with a Buy and a Sell tab: general store, furniture, dealer's wares and starter kits, each with its own stock table | Characters, Inventory, Jobs, NPC Life |
| [Exchange](dubz_exchange) | A bank vault for items, and a market where any player can list items for others to buy | Characters, Inventory |
| [Credits](dubz_credits) | Donator credits: the store link, daily credits, boosts, conversions and the item shop | Temp Ranks |
| [Temp Ranks](dubz_temp_ranks) | Time-limited user groups (VIP and so on) handed out by staff or bought with credits; they revert when time is up | |
| [Titles](dubz_title_system) | The title store: titles and colours players buy, their prices, and who counts as VIP | Characters |
| [Vending Machines](dubz_vending_machine) | Soda machines: press E, pay, and a can drops out; a can takes away hunger | Inventory |
| [Refund](dubz_refund) | Gives players back what a restart or crash cost them: small items respawn, big ones refund as cash | Characters |

### Rules and world

| Module | What it does | Works with |
| --- | --- | --- |
| [Laws](dubz_laws) | The city's laws as two lists, legal and illegal, set by the mayor | |
| [New Life Rule](dubz_nlr) | NLR timer after death, the zone around where you died, and the OOC lines when you enter or leave it | |
| [NPC Life](dubz_npc_life) | Shop NPCs idle with changing animations, look at you, turn to face you, and sometimes say a line | |
| [No Sprays](dubz_nosprays) | Stops players spraying their image on walls | |
| [Word Scramble](dubz_scramble) | A scrambled word appears in chat every so often; the first to type the real word wins cash | |

### Movement, hands and gun feel

| Module | What it does | Works with |
| --- | --- | --- |
| [Hands](dubz_hands) | The hands weapon: fists, shoving, door keys and the first-person arm position | Inventory |
| [Gestures](dubz_gestures) | Hold G for the gestures menu: wave, salute, laugh, dance and more, with a live preview | Characters |
| [Third Person](dubz_thirdperson) | F7 switches between first and third person; hold Alt to look around the player | Characters |
| [Weapon Stance](dubz_weapon_stance) | Lowered guns until you aim, like DarkRP's own guns, for M9K and other weapon packs | Third Person |
| [Visible Weapons](dubz_visible_guns) | Shows the weapons a player carries on their body: pistols and submachine guns on the hips, rifles on the back | Inventory |

### Interface

| Module | What it does | Works with |
| --- | --- | --- |
| [HUD](dubz_blackout_hud) | The top bar, laws, agenda, popups, ammo, overhead info, door text and death screen | Cosmetics, Karma, Laws, NLR, Skills, Titles |
| [Scoreboard](dubz_scoreboard) | The TAB scoreboard: title, size, columns, ordering and staff buttons | Karma |
| [F4 Menu](dubz_f4) | The DarkRP F4 menu: home, jobs, shop pages, commands and rules | |
| [Classic F4 Menu](dubz_classic_f4) | The classic F4 menu with tabs, icon grids, rules and How To Play | Characters, Cosmetics, Credits, Inventory, Laws, Skills, Third Person |

### Staff tools

| Module | What it does | Works with |
| --- | --- | --- |
| [DarkRP Management](dubz_darkrp) | Kanban boards for jobs, shipments, entities and ammo. Changes reach every player immediately | Workflow |
| [Workflow](dubz_workflow) | Plan, assign and track server work with staff presence, notes and an archive | DarkRP Management, Suggestions |
| [Suggestions](dubz_suggestions) | Players submit and vote on suggestions; staff approve them before they go public | |

## Things to know

- **Install only one F4 menu.** [F4 Menu](dubz_f4) and [Classic F4 Menu](dubz_classic_f4) both register the module id `f4`, so use one or the other.
- **Characters is the backbone.** Skills, karma, shops, the exchange and others use it to keep data per character, so install it from the start.
- **A sensible starting set.** Characters, Skills, Pocket & Backpack, Actions, Jobs, Shops, Laws, New Life Rule, HUD, Scoreboard and one F4 menu. Add gathering, economy and staff modules as the server grows.
- **Removing a module** is deleting its folder and restarting. "Works with" partners are optional for each other; if something misbehaves after you remove one, check the console and open an issue.
- **Shop-side names and prices** that DarkRP reads while it loads (shop entries, categories) need a restart after you change them in the menu. Descriptions in the admin menu say which.

## Build your own

These modules follow the framework's standards: one addon per feature, every value a setting, collections for tables, a gamemode adapter, themed UI and small files. They are real examples to read. The framework repository also contains a developer guide (and instructions for AI coding agents) for building your own modules the same way.

## Repository layout

```
dubz_<module>/
  addon.json              the addon's own manifest
  lua/autorun/            loader and package manifest
  lua/dubz_<module>/      shared (sh_), server (sv_) and client (cl_) files, and sh_framework.lua
  lua/entities/           entities, where the module has any
  lua/weapons/            weapons, where the module has any
  materials/, models/     assets, where the module has any
```

Files start with their realm: `sh_` shared, `sv_` server, `cl_` client. `sh_framework.lua` is the file that registers the module and its settings with the framework.

## Contributing and support

Issues and pull requests are welcome. Please say which module a report is about, include the console error text exactly, and run `dfw_status` on the server first. Follow the [framework's code style](https://github.com/BDubz420/dubz_framework/blob/main/docs/code-style.md) for changes.

## License

[MIT](LICENSE). Free to use, change and share, on any server.
