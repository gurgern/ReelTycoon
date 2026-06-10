# ReelTycoon — Game Design Document (MVP)

## Elevator pitch

Run a chaotic bedroom-to-studio reel empire: queue ideas through an idle pipeline, ride the Meme Market, and pray the Algorithm stays hyped.

## Core loop

1. Tap **New Reel Idea** → job enters Idea stage
2. Pick a **rising trend** on the Meme Market (or auto via upgrade)
3. Reel progresses: Idea → Film → Edit → Caption → Post
4. Publish earns views, followers, cash
5. Buy upgrades → faster automation → hit win milestone

## Win / soft-fail

- **Win:** 10,000 followers OR $1,000 cash
- **Soft-fail:** Drama hits 100 → "Cancelled" comedy pause for 30s (not game over)

## Meme Market

- 3 active trends at a time; each has a live multiplier (0.3×–2.5×)
- Ticks every 5s with volatility + mean reversion toward `base_bonus`
- UI shows ▲ rising / ▼ falling
- Post on a riser = big payout; post on a crasher = flop toast

## Stats

| Stat | Role |
|------|------|
| Followers | Unlocks upgrades |
| Views | Score / milestones |
| Cash | Buy upgrades |
| Algorithm Mood | 0–100 view multiplier |
| Drama | 0–100 chaos / cancel risk |

## Trends (content bible)

| ID | Name |
|----|------|
| npc_walk | NPC Walk |
| ai_apology | AI Voice Apology |
| potato_grwm | GRWM But It's a Potato |
| silent_review | Silent Product Review |
| corecore | Corecore Aesthetic |
| sigma_grind | Sigma Grindset POV |
| npc_walk | NPC Walk |
| hot_take | Hot Take Green Screen |
| day_in_life | Day In My Life (Fake) |
| unboxing | Unboxing Nothing |

## Events

- Comment Section War (+drama, +views)
- Shadowban Scare (−algorithm mood)
- Mystery Brand Deal (+cash)
- Algorithm Update (mood reshuffle)
- Trend Mooning (+multiplier on one trend)
- Meme Bubble Burst (top trend crashes)

## Monetization

**MVP:** Free, no ads, no IAP. Local save only.
