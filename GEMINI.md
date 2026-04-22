# SORTA - The Ultimate Ranking Game

## The Vibe
Modern, simple, colorful, cool. Neo-Brutalist UI with **Space Grotesk** typography, hard shadows, and thick black borders. Chunky drag-and-drop mechanics. Dot-grid background on all screens except home.

## Core Mechanic
Bold prompts with five massive text cards. Users drag and drop cards to sort them in the correct order.

---

## Technical Stack

### Frontend (Flutter)
- **State Management:** Riverpod (`flutter_riverpod`) using `Notifier` for robust, scalable state.
- **Local Database:** Isar v4 (High-performance NoSQL) for offline-first capabilities.
- **Theming:** Custom `ThemeExtension` (AppColors, AppTextTheme) with support for Light and Dark modes.
- **Typography:** `google_fonts` (Space Grotesk).
- **Architecture:** Feature-based MVVM (Model-View-ViewModel).
- **Number Formatting:** `intl` package for scores and ranks.
- **SVG Icons:** `flutter_svg` + Heroicons 2 outline (assets/icons/).

### Content Pipeline (External)
- **Generation:** Node.js script using **NVIDIA Nemotron-3 Super 120B** model via NVIDIA NIM API.
- **Categories:** Sports, Entertainment, World Facts, Science, Math, Tech, ALL.
- **Output:** Structured JSON batches for Firestore injection.

---

## Gameplay & Logic

### Match Structure
- **5-Question Match:** A single match consists of 5 ranking puzzles.
- **Start Overlay:** A blurred background with a pulsating START button (scale + opacity breathe effect) triggers the first question.
- **Auto-Advance:** Questions flow seamlessly until the "Match Complete" results screen.
- **Daily Sort:** A special daily challenge accessible from the Home screen.

### Scoring System (Competitive)
- **Correct Card:** +10 points.
- **Perfect Bonus:** +30 points (Total +80 for all correct).
- **Wrong Card:** -5 points.
- **All Wrong Penalty:** -35 points (Total -60 for all incorrect).
- **Streak Multiplier:** Perfect scores increase your streak, multiplying subsequent match scores.
- **Speed Bonus:** Remaining time (in seconds) is added to your score for perfect sorts.

### UI Features
- **Smooth Pulse Timer:** Progress bar oscillates smoothly (CurvedAnimation + easeInOut) and turns red/glows when time (30s) is running low.
- **Floating Scores:** Individual card scores (+10 / -5) float from the card's bottom to top with a fade-out — clipped inside the card bounds (ClipRRect + Clip.hardEdge).
- **Fixed Layout:** `LayoutBuilder` ensures the game is scroll-free on all devices.
- **Category Dropdown:** Quickly switch categories directly from the Play screen.
- **Dot Grid Background:** `DotGridBackground` widget (CustomPainter) applies a 1px dot on 20×20px grid behind all screens except home.

---

## Screens

| Screen | File | Tab | Notes |
|--------|------|-----|-------|
| Home | `main_screen.dart` (HomeScreen) | HOME | Stats, daily sort, clubs; world rank card navigates to WorldRankScreen |
| Play/Game | `game_screen.dart` | PLAY | Drag-and-drop, timer, start overlay |
| Clubs | `clubs_screen.dart` | CLUBS | My club card (→ ClubRankScreen) + discover list |
| Club Rank | `club_rank_screen.dart` | — (pushed) | Club leaderboard, podium cards |
| World Rank | `world_rank_screen.dart` | — (pushed from home) | Global leaderboard, podium, your position banner |
| Profile | `profile_screen.dart` | ME | Avatar, stats cards, recent matches, theme toggle |

---

## Icon System (Heroicons 2 Outline)

Icons stored in `assets/icons/`, rendered via `SvgPicture.asset()` with `colorFilter: ColorFilter.mode(color, BlendMode.srcIn)`.

| Asset | Usage |
|-------|-------|
| `user.svg` | User avatar in rank rows, profile header, podium cards |
| `user-group.svg` | Club cards in ClubsScreen |
| `trophy.svg` | Matches stat in ProfileScreen |
| `chart-bar.svg` | Total points stat in ProfileScreen |
| `fire.svg` | Streak stat in ProfileScreen |
| `globe-alt.svg` | Reserved for future world rank card icon |

---

## Project Structure

```text
lib/
├── core/
│   ├── providers/
│   │   └── auth_provider.dart        # authStateProvider (StreamProvider<User?>)
│   ├── theme/
│   │   ├── extensions/               # AppColorsExtension, AppTextThemeExtension
│   │   ├── app_palette.dart          # Raw color constants
│   │   ├── app_theme.dart            # Theme orchestrator (Riverpod Notifier)
│   │   └── app_typography.dart       # Font styles (Space Grotesk)
│   ├── widgets/
│   │   └── dot_grid_background.dart  # DotGridPainter + DotGridBackground
│   ├── isar_service.dart
│   └── isar_provider.dart
├── features/
│   ├── auth/
│   │   ├── view/login_screen.dart         # Login/signup UI (email + password)
│   │   └── view_model/auth_view_model.dart # AuthViewModel (NotifierProvider)
│   ├── game/
│   │   ├── data/
│   │   ├── view/game_screen.dart
│   │   └── view_model/
│   └── home/
│       └── view/
│           ├── main_screen.dart       # Shell, HomeScreen, BottomNav
│           ├── world_rank_screen.dart # Global leaderboard
│           ├── clubs_screen.dart      # My club + discover
│           ├── club_rank_screen.dart  # Club member leaderboard
│           └── profile_screen.dart   # User profile + stats
├── firebase_options.dart              # Manual Firebase config (iOS + Android)
└── main.dart                         # _AuthGate → LoginScreen or MainScreen
assets/
└── icons/
    ├── user.svg
    ├── user-group.svg
    ├── trophy.svg
    ├── chart-bar.svg
    ├── fire.svg
    └── globe-alt.svg
functions/
└── index.js                          # 7 Cloud Functions (Node 20)
```

---

## Content Pipeline

### Scripts

| Script | Purpose |
|--------|---------|
| `generate_puzzles.js` | Calls NVIDIA NIM API, writes JSON files locally |
| `upload_puzzles.js` | Reads those JSON files, deduplicates, pushes to Firestore `questions/` |

### One-time Setup
1. `cd scripts && npm install`
2. Add your `OPENAI_API_KEY` (NVIDIA NIM key) to `scripts/.env`
3. Download Firebase service account key → Firebase Console → Project Settings → Service Accounts → Generate new private key → save as `scripts/service-account.json` (gitignored, never commit)

### Monthly Batch Workflow
```bash
cd scripts

# Step 1 — Generate new puzzles (calls NVIDIA NIM API)
node generate_puzzles.js ALL          # all 6 categories, 10 each
# or per category:
node generate_puzzles.js Science      # 20 for one category

# Step 2 — Dry run to preview what would be uploaded
node upload_puzzles.js ALL --dry-run

# Step 3 — Upload to Firestore (safe to re-run, duplicates are skipped)
node upload_puzzles.js ALL
```

### How Deduplication Works
Each question is identified by a SHA-256 hash of its prompt text — that hash becomes the Firestore document ID. Re-running the upload on the same batch writes nothing new. Only genuinely new prompts get created.

### Where Questions Live
- **Source of truth:** Firestore `questions/{docId}` collection
- **Local JSON files** (`generated_puzzles_*.json`) are intermediate/throwaway — gitignored
- App **never** reads from `hardcoded_data.dart` in production; that file is dev scaffolding only

### Question Rotation (how randomization works)
- App queries Firestore for active questions in the selected category
- Client shuffles the pool and picks 5 per match
- Played question IDs stored in `users/{uid}.completedQuestionIds` to avoid repeats
- Once all questions in a category are exhausted for a user, that user's completed set for that category resets
- **Daily Sort:** same 5 questions globally each day — seeded at midnight UTC by Cloud Function from `dailySorts/{YYYY-MM-DD}`

---

## Firebase Backend

### Services Used
- **Firebase Auth** — user identity (email/password; Google + Apple deferred)
- **Cloud Firestore** — all app data
- **Cloud Functions** — rank recomputation, score aggregation, daily sort seeding
- **Firebase Storage** — user avatar uploads (future)

---

### Firestore Collections

#### `users/{uid}`
One document per authenticated user. Created on first sign-in.

| Field | Type | Description |
|-------|------|-------------|
| `uid` | `string` | Firebase Auth UID (same as doc ID) |
| `displayName` | `string` | Public username (e.g. "JoshT") |
| `avatarId` | `string` | Avatar identifier (maps to asset or Storage URL) |
| `level` | `int` | Computed from `totalScore` using tier thresholds |
| `totalScore` | `int` | Cumulative world ranking score across all matches |
| `worldRank` | `int` | Cached global rank — recomputed by Cloud Function when `totalScore` changes |
| `matchesPlayed` | `int` | Total number of completed matches |
| `currentStreak` | `int` | Current consecutive-perfect streak |
| `bestStreak` | `int` | All-time highest streak |
| `dailySortDate` | `timestamp` | Date of last completed Daily Sort (used for new-day detection) |
| `dailySortScore` | `int` | Score earned on today's Daily Sort (reset each new day) |
| `clubIds` | `string[]` | List of club IDs this user belongs to |
| `primaryClubId` | `string?` | The club shown on the Home screen (first joined, or user-selected) |
| `createdAt` | `timestamp` | Account creation time |

#### `users/{uid}/matches/{matchId}`
One document per completed match. Used for "Recent Matches" in ProfileScreen.

| Field | Type | Description |
|-------|------|-------------|
| `matchId` | `string` | Auto-generated doc ID |
| `category` | `string` | Category played (e.g. "Sports", "Daily Sort") |
| `scoreDelta` | `int` | Net score change for this match (positive or negative) |
| `matchScore` | `int` | Raw score before streak multiplier |
| `finalScore` | `int` | Score after multiplier |
| `questionsAnswered` | `int` | Number of questions completed (up to 5) |
| `perfectCount` | `int` | Number of perfect sorts in this match |
| `streakAtEnd` | `int` | Streak value when match completed |
| `playedAt` | `timestamp` | Match completion timestamp |
| `isDailySort` | `bool` | Whether this was a Daily Sort match |

---

#### `questions/{questionId}`
Populated by the content pipeline (Node.js script → Firestore).

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique question ID |
| `prompt` | `string` | The ranking instruction shown to the user |
| `items` | `string[]` | Correct order (index 0 = first/lowest/earliest) |
| `category` | `string` | One of: Sports, Entertainment, World Facts, Science, Math, Tech |
| `difficulty` | `string` | "easy" / "medium" / "hard" (for future use) |
| `isActive` | `bool` | False = soft-deleted, excluded from queries |
| `createdAt` | `timestamp` | When inserted |

---

#### `dailySorts/{YYYY-MM-DD}`
One document per calendar day. Seeded by a Cloud Function or admin script.

| Field | Type | Description |
|-------|------|-------------|
| `date` | `string` | Document ID in "YYYY-MM-DD" format |
| `questionIds` | `string[]` | Ordered list of 5 question IDs for this day's Daily Sort |
| `seededAt` | `timestamp` | When the document was created |

---

#### `clubs/{clubId}`
One document per club.

| Field | Type | Description |
|-------|------|-------------|
| `clubId` | `string` | Auto-generated doc ID |
| `name` | `string` | Club display name (e.g. "Brain Squad") |
| `description` | `string?` | Optional short bio |
| `creatorUid` | `string` | UID of the user who created the club |
| `memberCount` | `int` | Cached count (updated by Cloud Function) |
| `clubScore` | `int` | Aggregate club score — **separate from world rank** — sum of all members' `clubScore` in the members subcollection |
| `clubRank` | `int` | Cached rank among all clubs by `clubScore` — recomputed by Cloud Function |
| `isPublic` | `bool` | Discoverable in the Discover tab |
| `createdAt` | `timestamp` | Club creation time |

> **Club Score vs World Rank:** `clubScore` is an independent leaderboard. When a user completes a match, their `matchScore` is added to both `users/{uid}.totalScore` (world rank) AND to `clubs/{clubId}/members/{uid}.clubScore` for every club they belong to. The two leaderboards are entirely separate.

#### `clubs/{clubId}/members/{uid}`
One document per club member.

| Field | Type | Description |
|-------|------|-------------|
| `uid` | `string` | Member's Firebase Auth UID (same as doc ID) |
| `displayName` | `string` | Denormalized for fast leaderboard reads |
| `avatarId` | `string` | Denormalized for fast leaderboard reads |
| `clubScore` | `int` | Score this user has accumulated **within this club** — not their world score |
| `clubRank` | `int` | This member's rank within this club (cached) |
| `joinedAt` | `timestamp` | When this user joined this club |

---

### Screen → Data Mapping

#### Home Screen
| UI Element | Data Source |
|------------|-------------|
| DAILY SORT "PLAY NOW" card | `users/{uid}.dailySortDate` compared to today |
| DAILY SORT SCORE card | `users/{uid}.dailySortScore` |
| TOTAL SCORE | `users/{uid}.totalScore` |
| WORLD RANK | `users/{uid}.worldRank` (cached) |
| MY CLUBS list | `users/{uid}.clubIds` → fetch each `clubs/{clubId}` for name + `clubRank` |

#### Game Screen
| UI Element | Data Source |
|------------|-------------|
| Category questions | Query `questions` where `category == selectedCategory` and `isActive == true` |
| Daily Sort questions | Fetch `dailySorts/{today}`, load each question by ID |
| Match score | Computed client-side, written to Firestore on match complete |
| Category list | Distinct values from `questions.category` (or a hardcoded enum) |

**On match complete:**
1. Write `users/{uid}/matches/{auto-id}` with match summary
2. Increment `users/{uid}.totalScore` by `matchScore`
3. Increment `users/{uid}.matchesPlayed`
4. Update `users/{uid}.currentStreak` / `bestStreak`
5. For each club in `users/{uid}.clubIds`: increment `clubs/{clubId}/members/{uid}.clubScore`
6. If Daily Sort: set `users/{uid}.dailySortDate` = today, `users/{uid}.dailySortScore` = matchScore
7. Cloud Function triggers world rank + club rank recomputation

#### World Rank Screen
| UI Element | Data Source |
|------------|-------------|
| Top 20 podium + list | Query `users` ordered by `totalScore` desc, limit 20 |
| YOUR POSITION banner | `users/{uid}.worldRank` + `users/{uid}.totalScore` |

#### Clubs Screen — MY CLUB section
| UI Element | Data Source |
|------------|-------------|
| Club name | `clubs/{primaryClubId}.name` |
| Member count | `clubs/{primaryClubId}.memberCount` |
| Club rank | `clubs/{primaryClubId}.clubRank` |

#### Clubs Screen — DISCOVER section
| UI Element | Data Source |
|------------|-------------|
| Club list | Query `clubs` where `isPublic == true`, ordered by `clubScore` desc |
| JOIN button | Add `uid` to `clubs/{clubId}/members`, add `clubId` to `users/{uid}.clubIds` |

#### CREATE CLUB
Fields collected: `name`, `description` (optional), `isPublic` (toggle)
Creates: `clubs/{auto-id}` document + `clubs/{clubId}/members/{uid}` for the creator

#### Club Rank Screen
| UI Element | Data Source |
|------------|-------------|
| AppBar title (club name) | `clubs/{clubId}.name` |
| MEMBERS pill | `clubs/{clubId}.memberCount` |
| RANK pill | `clubs/{clubId}.clubRank` |
| Podium top 3 | Query `clubs/{clubId}/members` ordered by `clubScore` desc, limit 3 |
| Member rows 4–N | Same query, offset 3, limit remaining |
| "isMe" highlight | Compare each member `uid` to current `auth.uid` |
| Score shown per member | `clubs/{clubId}/members/{uid}.clubScore` — **not** world score |

#### Profile Screen
| UI Element | Data Source |
|------------|-------------|
| Username | `users/{uid}.displayName` |
| Avatar | `users/{uid}.avatarId` |
| Level badge | Computed from `users/{uid}.totalScore` using tier table |
| Club name | `clubs/{primaryClubId}.name` |
| TOTAL PTS stat | `users/{uid}.totalScore` |
| MATCHES stat | `users/{uid}.matchesPlayed` |
| STREAK stat | `users/{uid}.currentStreak` |
| Recent Matches list | Query `users/{uid}/matches` ordered by `playedAt` desc, limit 10 |

---

### Level Tiers (suggested)
Computed client-side from `totalScore`. No separate Firestore field needed.

| Level | Min Score | Label |
|-------|-----------|-------|
| 1 | 0 | Novice |
| 5 | 500 | Thinker |
| 10 | 2,000 | Strategist |
| 15 | 5,000 | Expert |
| 20 | 10,000 | Master |
| 25 | 20,000 | Legend |

---

### Cloud Functions Deployed

All 7 functions are live in `functions/index.js` (Node 20, Firebase Functions v7).

| Function | Trigger | Action |
|----------|---------|--------|
| `initUserDocument` | HTTPS (`onRequest`) — called from app after sign-up | Creates `users/{uid}` with all default values; no-op if doc already exists |
| `onMatchComplete` | Firestore write to `users/{uid}/matches/{matchId}` | Increments `totalScore`, `matchesPlayed`, updates streak fields, fans out `clubScore` increments to all clubs |
| `onMemberJoin` | Firestore create on `clubs/{clubId}/members/{uid}` | Increments `clubs/{clubId}.memberCount` |
| `onMemberLeave` | Firestore delete on `clubs/{clubId}/members/{uid}` | Decrements `memberCount`, removes `clubId` from `users/{uid}.clubIds` |
| `recomputeWorldRanks` | Scheduled every 5 min | Orders top-500 users by `totalScore`, writes `worldRank` in batched commits |
| `recomputeClubRanks` | Scheduled every 5 min | Sums each club's member scores, sorts clubs, writes `clubRank` + `clubScore` |
| `seedDailySort` | Scheduled midnight UTC daily | Picks 5 fresh question IDs (not used in past 30 days), writes `dailySorts/{YYYY-MM-DD}` |

---

### Firebase Auth
- **Providers:** Email/Password only (Google and Apple deferred)
- **On first sign-in:** App calls HTTPS Cloud Function `initUserDocument` immediately after `createUserWithEmailAndPassword` succeeds. This creates `users/{uid}` with all default values. (An Auth `onCreate` trigger was ruled out — it caused load-timeout failures on the project's Blaze plan activation.)
- **Display name / Username:** Collected at sign-up, written via `user.updateDisplayName()` on the Firebase Auth profile, and stored in `users/{uid}.displayName` in Firestore by `initUserDocument`.
- **Anonymous play:** Not supported — account required to save scores

### Auth Implementation (Flutter)

| File | Role |
|------|------|
| `lib/core/providers/auth_provider.dart` | `authStateProvider` (`StreamProvider<User?>`) wraps `FirebaseAuth.instance.authStateChanges()`. `currentUserProvider` exposes current user via `.asData?.value`. |
| `lib/features/auth/view_model/auth_view_model.dart` | `AuthViewModel` (`Notifier<AuthState>`) — `signInWithEmail`, `signUpWithEmail`, `signOut`, `clearError`. Maps Firebase error codes to user-friendly strings. |
| `lib/features/auth/view/login_screen.dart` | Neo-brutalist login/sign-up screen. SIGN IN / SIGN UP toggle tab. Email + password fields; username field appears on sign-up only. Yellow primary button, error snackbar. |
| `lib/main.dart` | `SortaApp` is now a `ConsumerWidget`. `_AuthGate` watches `authStateProvider` and routes: signed-in → `MainScreen`, signed-out → `LoginScreen`, loading → spinner. |

### Firebase Project
- **Project ID:** `sorta-3df17`
- **Config file:** `lib/firebase_options.dart` (manual — no FlutterFire CLI needed)
- **To enable auth:** Firebase Console → Authentication → Sign-in method → **Email/Password → Enable**
