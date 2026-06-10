# ReelTycoon

Chaotic idle tycoon about making reels. Built with **Godot 4**.

## Quick start

1. Install [Godot 4.3+](https://godotengine.org/download)
2. Open this folder in Godot (Import `project.godot`)
3. Press **F5** to run

## Gameplay

- Tap **+ New Reel Idea** to queue a reel through Idea → Film → Edit → Caption → Post
- Pick a **rising trend (▲)** on the Meme Market before posting for bigger payouts
- Buy upgrades to speed up stages and automate trend picking
- Survive random chaos events and algorithm mood swings
- Win at **10,000 followers** or **$1,000 cash**

## Project structure

```
data/           JSON balance (trends, events, upgrades, economy)
docs/GDD.md     Game design doc
scenes/         Godot scenes
scripts/        GDScript (autoloads, systems, UI)
```

## Mobile export

1. Install Android export templates in Godot
2. Project → Export → Add Android preset
3. Configure SDK path via Editor Settings → Export → Android

## MVP scope

- No ads, no IAP
- Local save only (`user://save.json`)
- Offline progress capped at 4 hours
