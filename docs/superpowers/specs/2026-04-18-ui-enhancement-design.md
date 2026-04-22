# SORTA UI Enhancement — Design Spec
**Date:** 2026-04-18

## Scope

This spec covers three areas of enhancement:
1. Dot grid background system across all screens
2. Three animation fixes in the game screen
3. Four new screens (World Rank, Clubs, Club Rank, Profile) with SVG icons and mock data

**Explicitly out of scope:** Home screen card icons, bottom tab bar icons.

---

## 1. Background System

### What
A `DotGridPainter` (CustomPainter) renders 1px dots on a 20×20px grid behind every screen content. A `DotGridBackground` widget wraps content in a `Stack`.

### Behaviour
- Light mode: `#F0F0F0` base, `#C0C0C0` dots
- Dark mode: `#1A1A1A` base, `#383838` dots
- Dot colors sourced from `AppColors` extension so they follow theme automatically
- Applied as the bottom layer of a `Stack` inside each screen's `Scaffold` body

### Implementation
```
lib/core/widgets/dot_grid_background.dart   — DotGridPainter + DotGridBackground widget
```
`DotGridBackground` takes a `child` and paints dots behind it via `CustomPaint` sized to `double.infinity`.

---

## 2. Animation Fixes

### 2a. Timer Pulse (GameScreen)
**Problem:** The progress bar colour change feels like it counts/steps rather than smoothly oscillates.
**Fix:** Wrap `_pulseController` in a `CurvedAnimation` with `Curves.easeInOut`. The controller already repeats; adding the curve makes each cycle a smooth sine-like oscillation instead of a linear sweep.
```dart
_curvedPulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
```
Use `_curvedPulse.value` instead of `_pulseController.value` in the `Color.lerp` call.

### 2b. Start Button (StartOverlay)
**Problem:** Expanding ring lines feel distracting; user wants a pulsating breathe effect.
**Fix:** Replace the three expanding `AnimatedBuilder` rings with a single `ScaleTransition` + `FadeTransition` wrapping the button container.
- Scale: `1.0 → 1.06`, curve `Curves.easeInOut`, duration `1200ms`, repeat with reverse
- Opacity: `1.0 → 0.80`, same controller, same curve
- Remove the three `List.generate` ring widgets entirely

### 2c. Score Float-Up (_SortCard)
**Problem:** Score popup floats outside the card bounds.
**Fix:**
- Wrap the card's `Stack` in `ClipRRect` with the card's border radius so nothing escapes
- Wrap the card in `LayoutBuilder` to capture `constraints.maxHeight` as the card height
- Keep the `TweenAnimationBuilder` tween at `0.0 → 1.0`; compute `dy = -(value * cardHeight)` so the score travels from the bottom edge to the top edge
- Opacity: `value < 0.7 ? 1.0 : 1.0 - ((value - 0.7) / 0.3)` — fully visible for the first 70% of travel, fades out in the final 30%

---

## 3. Icon System

### Dependency
Add to `pubspec.yaml`:
```yaml
flutter_svg: ^2.0.10
```

### Assets
Download Heroicons outline SVGs and store in `assets/icons/`:
```
assets/icons/
  trophy.svg
  globe-alt.svg
  user-group.svg
  user-circle.svg
  chart-bar.svg
  fire.svg
  calendar-days.svg
  squares-2x2.svg
```
Register in `pubspec.yaml` under `flutter: assets: - assets/icons/`.

### Usage
```dart
SvgPicture.asset(
  'assets/icons/trophy.svg',
  width: 24,
  height: 24,
  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
)
```
Colour is passed in at call site to match the card's accent colour.

---

## 4. New Screens

All screens use `DotGridBackground`, follow the existing neo-brutalist card style (2–4px border, hard shadow `Offset(4,4) blurRadius 0`, `BorderRadius.circular(12)`), Space Grotesk typography, and Heroicon SVGs. All data is mock/hardcoded.

### 4a. World Rank Screen (`world_rank_screen.dart`)
**Route:** `Navigator.push` from the existing World Rank card on the Home screen (adds `onTap` to the existing card — no visual change to home screen).
**Layout:**
- Header: "WORLD RANK" title + category filter pill row (ALL / Sports / Science / etc.)
- Top 3 podium cards: rank 1 in yellow, 2 in cyan, 3 in pink — each shows rank badge, user icon (SVG), username, score
- Divider: "YOUR POSITION" highlighted row with cyan dashed border showing rank #142 / 4,280 pts
- Scrollable list of remaining mock ranks (4–20) in surface-coloured rows with rank badge, user SVG, name, score

**Mock data:** 20 hardcoded `RankEntry` objects (`rank`, `username`, `score`).

### 4b. Clubs Screen (`clubs_screen.dart`)
**Route:** Existing CLUBS tab (currently PlaceholderScreen).
**Layout:**
- Section 1 "MY CLUB": Single club card (cyan, user-group SVG) showing club name "Brain Squad", member count, club rank badge. Tapping navigates to Club Rank screen.
- Section 2 "DISCOVER": Vertical list of club cards (white/surface) each with user-group SVG, club name, member count, join button. 6 mock clubs.
- FAB: "CREATE CLUB" button (yellow, bottom right)

**Mock data:** 6 hardcoded `ClubEntry` objects (`name`, `memberCount`, `rank`).

### 4c. Club Rank Screen (`club_rank_screen.dart`)
**Route:** Navigated to from Clubs screen (tapping "My Club" card).
**Layout:**
- Header bar: Club name + back button + stats row (members count, club world rank)
- Top 3 same podium card treatment as World Rank
- User's own position highlighted row
- Scrollable member list

**Mock data:** 8 hardcoded club members.

### 4d. Profile Screen (`profile_screen.dart`)
**Route:** Existing ME tab (currently PlaceholderScreen).
**Layout:**
- Avatar circle (yellow, user SVG icon) + username + "LVL 12 · BRAIN SQUAD" subtitle
- Stats cards row: Total Points (chart-bar SVG, yellow), Matches / Win% (trophy SVG, cyan), Current Streak (fire SVG, pink)
- Recent activity section: last 5 matches listed with category, score delta, date
- Theme toggle button (existing behaviour, moved here)

**Mock data:** Hardcoded stats + 5 recent match entries.

---

## File Changes Summary

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_svg`, register `assets/icons/` |
| `assets/icons/*.svg` | 8 Heroicon SVG files (new) |
| `lib/core/widgets/dot_grid_background.dart` | New widget |
| `lib/features/game/view/game_screen.dart` | 3 animation fixes |
| `lib/features/home/view/world_rank_screen.dart` | New screen |
| `lib/features/home/view/clubs_screen.dart` | New screen (replaces placeholder) |
| `lib/features/home/view/club_rank_screen.dart` | New screen |
| `lib/features/home/view/profile_screen.dart` | New screen (replaces placeholder) |
| `lib/features/home/view/main_screen.dart` | Wire Clubs + Profile tabs to new screens |
| `GEMINI.md` | Updated with new screens, icons, background system |
