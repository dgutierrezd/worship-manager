# WorshipFlow — Agent Instructions & Project Reference

## What This App Is

**WorshipFlow** (display name: "Worship Manager") is an iOS band-management tool for worship teams. It lets a worship band create/join a band, manage a shared song library with chord sheets, plan services (setlists), schedule rehearsals, and coordinate team members. Built with a SwiftUI iOS app talking to a Node.js/Express backend deployed on Vercel, backed by Supabase (Postgres + Auth + Storage).

---

## Project Layout

```
WorshipManager/
├── backend/                        # Node.js + TypeScript REST API
│   ├── src/
│   │   ├── config/supabase.ts      # Supabase admin + disposable auth clients
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts  # JWT Bearer token validation → req.userId
│   │   │   └── bandAccess.middleware.ts  # Band membership gate → req.bandId, req.bandRole
│   │   ├── routes/
│   │   │   ├── auth.ts             # signup, signin, refresh, signout
│   │   │   ├── bands.ts            # CRUD bands, avatar upload, invite code
│   │   │   ├── members.ts          # list, remove, promote members
│   │   │   ├── songs.ts            # song CRUD + chord sheet CRUD
│   │   │   ├── setlists.ts         # setlist CRUD + songs in setlist + reorder
│   │   │   ├── rehearsals.ts       # rehearsal CRUD + RSVP
│   │   │   └── notifications.ts    # FCM device token registration
│   │   ├── services/
│   │   │   └── notification.service.ts  # notifyBandMembers() via FCM
│   │   └── server.ts               # Express app entry point
│   ├── migrations/                 # SQL migrations (run in Supabase SQL Editor)
│   ├── schema.sql                  # Full DB schema + RLS policies (source of truth)
│   └── vercel.json                 # Vercel deployment config
└── iOS/
    └── WorshipFlow/
        ├── App/
        │   ├── WorshipFlowApp.swift # @main entry, injects AuthViewModel + LanguageManager
        │   └── Config.swift        # Supabase URL, anon key, API base URL (constants)
        ├── Core/
        │   ├── Auth/               # AuthViewModel, WelcomeView, LoginView, SignUpView
        │   ├── Navigation/         # RootView (auth gate), MainTabView (2 tabs)
        │   ├── Localization/       # LanguageManager.shared, .localized String extension
        │   └── Theme/
        │       ├── AppTheme.swift  # Colors, Fonts, ViewModifiers — THE design system
        │       └── Components/     # BandAvatarView, SectionHeader, KeyBadge, RSVPButton,
        │                           #   LoadingButton, EmptyStateView, FlowLayout, SkeletonView
        ├── Features/
        │   ├── Band/               # BandHomeView (dashboard), BandViewModel, Create/Join/Settings
        │   ├── Members/            # MembersView, MemberProfileView, InviteView
        │   ├── Practice/           # PracticeAudioEngine (AVAudioEngine metronome), PracticeSessionView
        │   ├── Rehearsals/         # RehearsalsView, CreateRehearsalView, RehearsalDetailView, RehearsalsViewModel
        │   ├── Services/           # ServicesView, ServiceDetailView, CreateServiceView, ManageTeamView, ServiceAssignmentViewModel
        │   ├── Setlists/           # SetlistsView, SetlistDetailView, CreateSetlistView, AddSongToSetlistView, SetlistViewModel
        │   ├── Settings/           # SettingsView, ProfileView, LanguageView
        │   └── Songs/              # SongLibraryView, SongDetailView, AddSongView, EditSongView,
        │                           #   ChordsEditorView, SongsViewModel
        ├── Models/                 # Band, Song, Setlist, SetlistSong, Rehearsal, RehearsalRSVP,
        │                           #   ChordSheet, ChordProgression, ChordEntry, ChordSection,
        │                           #   Member, Profile, ServiceAssignment
        └── Services/               # APIClient, AuthService, BandService, SongService,
                                    #   SetlistService, RehearsalService, ServiceAssignmentService,
                                    #   NotificationService
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS | Swift 5.9, SwiftUI, iOS 17.0+, Xcode 16 |
| iOS Architecture | MVVM — `@MainActor ObservableObject` ViewModels |
| Networking (iOS) | Custom `APIClient` Swift actor (singleton) — URLSession, Bearer auth, silent refresh |
| Backend | Node.js + TypeScript + Express 4 |
| Deployment | Vercel (`vercel.json` routes everything to `src/server.ts`) |
| Database | Supabase (PostgreSQL) with Row Level Security |
| Auth | Supabase Auth JWT — tokens stored in UserDefaults, silent refresh via `/auth/refresh` |
| Push Notifications | Firebase Cloud Messaging (FCM) via `firebase-admin` |
| File Storage | Supabase Storage — bucket: `band-avatars` (public) |
| Localization | English (`en`) + Spanish (`es`) via `LanguageManager.shared` |
| Audio | `AVAudioEngine` — fully on-device metronome (no audio files) |

---

## iOS Architecture Rules — Always Follow These

### ViewModels
- Always `@MainActor class FooViewModel: ObservableObject`
- Use `async/await` + Swift Structured Concurrency (`Task`, `withTaskGroup`) for all async work
- Never use Combine for networking — it's all async/await
- Loading states use `@Published var isLoading: Bool` and `@Published var error: String?`

### Views
- All SwiftUI — no UIKit in Views
- Content loading shows **skeleton views** (`SkeletonBlock`) for initial empty state, not spinners
- Use `@StateObject` for ViewModels that a view owns
- Use `@EnvironmentObject` for `BandViewModel` and `AuthViewModel` (passed from root)
- Use `@ObservedObject` only when a parent passes a VM it owns

### Navigation
- `RootView` is the auth gate — it creates `BandViewModel` as `@StateObject` and passes it down
- `MainTabView` has **only 2 tabs**: Home (`BandHomeView`) and Settings (`SettingsView` wrapped in `NavigationStack`)
- Removed from tabs (now accessed via Home quick-access grid): Services, Songs, Schedule/Rehearsals, Team/Members
- Each feature section lives inside its own `NavigationStack` or is pushed via `NavigationLink`
- Never nest `NavigationStack` inside another `NavigationStack`

### State Management
- `bandVM.currentBand` is the **single source of truth** for the active band — always read from this
- Each feature view creates its own local `@StateObject` ViewModels (e.g., `SongsViewModel`) — they are not shared globally
- `BandViewModel` is the only VM shared globally via `@EnvironmentObject`

### Design System — Never Bypass AppTheme
- **Colors**: Always use `Color.appBackground`, `.appSurface`, `.appPrimary`, `.appSecondary`, `.appDivider`, `.appAccent`, `.statusGoing`, `.statusMaybe`, `.statusNo` — never raw `Color(..)` for UI elements
- **Fonts**: Always use `Font.appLargeTitle`, `.appTitle`, `.appHeadline`, `.appBody`, `.appCaption`, `.appMono` — never raw `Font.system(...)` for UI text
- **Modifiers**: Use `.cardStyle()`, `.elevatedCardStyle()`, `.primaryButton()`, `.secondaryButton()`, `.destructiveButton()`, `.appTextField()` — never recreate these inline
- **Accent color**: `appAccent` = `#C9A84C` (gold)
- App is forced to **Light mode only** (`preferredColorScheme(.light)` in `WorshipFlowApp`), but all AppTheme colors are dark-mode adaptive in case this changes

### Localization
- All user-facing strings must use `.localized` extension: `"settings".localized`
- Keys live in `en.lproj/Localizable.strings` and `es.lproj/Localizable.strings`
- Never hardcode English strings in views — always use a localization key
- Exception: proper nouns and dynamic data (band names, song titles)

### Audio
- `PracticeAudioEngine` is a class (not actor/observable) — `PracticeManager.shared` wraps it as `ObservableObject`
- The floating mini-player (`PracticeMiniPlayerView`) sits above the tab bar in `MainTabView` — always keep `.padding(.bottom, 49)` on it
- Full-screen player uses `.fullScreenCover` on `MainTabView`

---

## Backend Architecture Rules

### Authentication Flow
1. All routes (except `/health`, `/auth/signup`, `/auth/signin`) require `Authorization: Bearer <access_token>`
2. `authMiddleware` validates the token via Supabase Admin `auth.getUser(token)` — attaches `req.userId`
3. Band-scoped routes also run `bandAccessMiddleware` — verifies membership, attaches `req.bandId` and `req.bandRole`
4. Leader-only mutations also run `leaderOnlyMiddleware` — checks `req.bandRole === "leader"`
5. Tokens are short-lived Supabase JWTs. Client handles silent refresh via `POST /auth/refresh`

### Database / RLS
- All tables have **Row Level Security enabled** — the Express backend uses the **service role key** (bypasses RLS) via `supabaseAdmin`
- The `get_user_band_ids()` function is `SECURITY DEFINER STABLE` to avoid RLS self-referencing recursion in band_members
- Never expose the service role key to the iOS client — iOS only knows the anon key (used only for Supabase JS SDK if needed, not currently used directly in iOS)
- Run new SQL changes as migrations in `backend/migrations/` with sequential numbering (004_, 005_, etc.) and apply them in the Supabase SQL Editor

### Adding New Backend Routes
1. Create/extend a route file in `backend/src/routes/`
2. Always apply `authMiddleware` first, then `bandAccessMiddleware` for band-scoped routes
3. Add leader-only guard with `leaderOnlyMiddleware` for destructive or admin actions
4. Register the router in `server.ts`
5. Push notifications on important events: use `notifyBandMembers(bandId, excludeUserId, title, body)` from `notification.service.ts`

### Environment Variables (backend/.env)
```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_ANON_KEY=
FCM_PROJECT_ID=
FCM_PRIVATE_KEY=
FCM_CLIENT_EMAIL=
PORT=3000
```
Never commit `.env`. Use `.env.example` for documentation.

---

## API Reference

**Base URL**: `https://worship-manager-psi.vercel.app`

### Auth
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/signup` | None | Create account (email auto-confirmed). Body: `email, password, full_name, instrument?` |
| POST | `/auth/signin` | None | Sign in. Body: `email, password` |
| POST | `/auth/refresh` | None | Silent token refresh. Body: `refresh_token` |
| POST | `/auth/signout` | Bearer | Client-side logout (clears tokens locally) |

### Bands
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/bands` | Bearer | Create band. Body: `name, church?, avatar_emoji?, avatar_color?` |
| POST | `/bands/join` | Bearer | Join by invite code. Body: `code` (6 chars) |
| GET | `/bands/my` | Bearer | List user's bands (includes `my_role`) |
| GET | `/bands/:id` | Bearer+Member | Band detail + `member_count` + `my_role` |
| PUT | `/bands/:id` | Bearer+Leader | Update band. Body: `name?, church?, avatar_emoji?, avatar_color?, avatar_url?` |
| POST | `/bands/:id/avatar` | Bearer+Leader | Upload band avatar. Multipart `avatar` field (max 5MB, jpg/png) |
| DELETE | `/bands/:id` | Bearer+Leader | Delete band |
| POST | `/bands/:id/regenerate-code` | Bearer+Leader | New 6-char invite code |

### Members
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/bands/:id/members` | Bearer+Member | List members (includes profile: name, avatar, instrument) |
| DELETE | `/bands/:id/members/:userId` | Bearer+Leader | Remove member |
| PATCH | `/bands/:id/members/:userId` | Bearer+Leader | Change role. Body: `role` (`leader`\|`member`) |

### Songs
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/bands/:id/songs` | Bearer+Member | Song library (alphabetical) |
| POST | `/bands/:id/songs` | Bearer+Member | Add song. Body: `title`, `artist?, default_key?, tempo_bpm?, duration_sec?, notes?, lyrics?, tags?, theme?, youtube_url?, spotify_url?` |
| PUT | `/bands/:id/songs/:songId` | Bearer+Member | Update song |
| DELETE | `/bands/:id/songs/:songId` | Bearer+Member | Delete song |

### Chord Sheets
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/songs/:id/chords` | Bearer | All chord sheets for a song (newest first) |
| POST | `/songs/:id/chords` | Bearer | Create chord sheet. Body: `content` (JSON string of `ChordProgression`), `title?, instrument?` |
| PUT | `/chords/:id` | Bearer | Update chord sheet. Body: `title?, content?, instrument?` |

### Setlists / Services
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/bands/:id/setlists` | Bearer+Member | List setlists (includes song count, newest first) |
| POST | `/bands/:id/setlists` | Bearer+Member | Create setlist. Body: `name, date?, notes?, is_template?` |
| PUT | `/setlists/:id` | Bearer | Update setlist |
| DELETE | `/setlists/:id` | Bearer | Delete setlist |
| GET | `/setlists/:id/songs` | Bearer | Songs in setlist (ordered by position) |
| POST | `/setlists/:id/songs` | Bearer | Add song. Body: `song_id, key_override?, notes?` (auto-assigns next position) |
| DELETE | `/setlists/:id/songs/:songId` | Bearer | Remove song from setlist |
| PATCH | `/setlists/:id/songs/reorder` | Bearer | Reorder. Body: `positions: [{id, position}]` |

### Rehearsals
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/bands/:id/rehearsals` | Bearer+Member | List rehearsals (asc by date, includes setlist name) |
| POST | `/bands/:id/rehearsals` | Bearer+Member | Create rehearsal (triggers push notification). Body: `title, scheduled_at (ISO8601), location?, notes?, setlist_id?` |
| PUT | `/rehearsals/:id` | Bearer | Update rehearsal |
| DELETE | `/rehearsals/:id` | Bearer | Delete rehearsal |
| POST | `/rehearsals/:id/rsvp` | Bearer | RSVP. Body: `status` (`going`\|`not_going`\|`maybe`) |

### Notifications
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/notifications/register` | Bearer | Register FCM device token. Body: `token` |

---

## Database Schema

### Tables
| Table | Key Columns | Notes |
|---|---|---|
| `profiles` | `id` (UUID, FK auth.users), `full_name`, `avatar_url`, `instrument`, `language` | Auto-created by trigger on auth.users insert |
| `bands` | `id`, `name`, `church`, `invite_code` (CHAR(6) unique), `avatar_color`, `avatar_emoji`, `avatar_url`, `created_by` | invite_code uses chars ABCDEFGHJKLMNPQRSTUVWXYZ23456789 (no I/O/0/1) |
| `band_members` | `band_id`, `user_id`, `role` (leader\|member), `instrument` | Unique(band_id, user_id) |
| `songs` | `id`, `band_id`, `title`, `artist`, `default_key`, `tempo_bpm`, `duration_sec`, `notes`, `lyrics`, `tags` (TEXT[]), `theme`, `youtube_url`, `spotify_url` | |
| `chord_sheets` | `id`, `song_id`, `instrument`, `title`, `content` (JSON string of ChordProgression) | |
| `setlists` | `id`, `band_id`, `name`, `date` (DATE), `notes`, `is_template`, `service_type`, `location`, `theme` | service_type: sunday_morning, sunday_evening, wednesday, special |
| `setlist_songs` | `setlist_id`, `song_id`, `position`, `key_override`, `notes` | Unique(setlist_id, position) |
| `rehearsals` | `id`, `band_id`, `setlist_id`, `title`, `location`, `scheduled_at` (TIMESTAMPTZ), `notes` | |
| `rehearsal_rsvps` | `rehearsal_id`, `user_id`, `status` | PK(rehearsal_id, user_id); status: going, not_going, maybe, pending |
| `device_tokens` | `id`, `user_id`, `token` (unique) | FCM tokens for push |

### RLS Helper
```sql
-- Avoids self-referencing recursion in band_members policies
CREATE OR REPLACE FUNCTION get_user_band_ids()
RETURNS SETOF UUID AS $$
  SELECT band_id FROM public.band_members WHERE user_id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;
```

---

## iOS Models Reference

```swift
// Key fields — all models are Codable + Identifiable
Band         { id, name, church, inviteCode, avatarColor, avatarEmoji, avatarUrl, myRole, memberCount }
Song         { id, bandId, title, artist, defaultKey, tempoBpm, durationSec, notes, lyrics, tags, theme, youtubeUrl, spotifyUrl }
Setlist      { id, bandId, name, date, notes, isTemplate, serviceType, location, theme }
SetlistSong  { id, setlistId, songId, position, keyOverride, notes, songs: Song? }
Rehearsal    { id, bandId, setlistId, title, location, scheduledAt (ISO8601), notes, setlists: SetlistRef? }
RehearsalRSVP { rehearsalId, userId, status }
ChordSheet   { id, songId, instrument, title, content (JSON string) }
ChordProgression { sections: [ChordSection] }  // Stored as JSON in chord_sheets.content
ChordSection { id, name, chords: [ChordEntry] }
ChordEntry   { id, degree(1-7), isPass, modifier }  // Nashville Number System
Member       { id, role, instrument, full_name, avatar_url }
Profile      { id, fullName, avatarUrl, instrument, language }
```

### ChordEntry Music Theory
- Degrees 1–7 map to Nashville Number System (key-agnostic)
- `diatonicQuality`: I,IV,V = major; ii,iii,vi = minor; vii = diminished
- `romanNumeral`: "I", "ii", "iii", "IV", "V", "vi", "vii°"
- `chordName(inKey:)` resolves absolute chord name (e.g., key=G, degree=4 → "C")
- `Song.transpose(key:steps:)` — chromatic key transposition utility

---

## iOS Networking (APIClient)

```swift
// All calls go through APIClient.shared (Swift actor)
let songs: [Song] = try await APIClient.shared.get("/bands/\(bandId)/songs")
let song: Song    = try await APIClient.shared.post("/bands/\(bandId)/songs", body: [...])
let song: Song    = try await APIClient.shared.put("/bands/\(bandId)/songs/\(id)", body: [...])
try await APIClient.shared.delete("/bands/\(bandId)/songs/\(id)")

// For image uploads:
let band: Band = try await APIClient.shared.uploadImage("/bands/\(id)/avatar", imageData: data)
```

- On `401`, client automatically calls `/auth/refresh` once and retries
- Tokens stored in `UserDefaults` under keys `worshipflow_access_token` / `worshipflow_refresh_token`
- `AuthViewModel` restores tokens from UserDefaults on cold launch (sets `isAuthenticated = true` immediately if tokens exist)

---

## App Configuration

```swift
// iOS/WorshipFlow/App/Config.swift
enum Config {
    static let supabaseURL   = "https://isctjrimtuocjfgfrjyo.supabase.co"
    static let supabaseAnonKey = "sb_publishable_..."    // safe to expose (anon key)
    static let apiBaseURL    = "https://worship-manager-psi.vercel.app"
}
```

- **Bundle ID**: `com.dgutierrezd.worshipflow`
- **Display Name**: "Worship Manager"
- **Min iOS**: 17.0, **Xcode**: 16, **Swift**: 5.9
- **Orientation**: Portrait only on iPhone, all on iPad
- **Color Scheme**: Light mode forced (`preferredColorScheme(.light)`)
- **Photo Library Usage**: Band avatar upload only

---

## Roles & Permissions

| Action | Leader | Member |
|---|---|---|
| View band, songs, setlists, rehearsals, members | ✅ | ✅ |
| Add/edit songs, setlists, rehearsals | ✅ | ✅ |
| RSVP to rehearsals | ✅ | ✅ |
| Update band settings (name, church, avatar) | ✅ | ❌ |
| Remove members or change roles | ✅ | ❌ |
| Regenerate invite code | ✅ | ❌ |
| Delete the band | ✅ | ❌ |

---

## Home Screen — Navigation Structure

`BandHomeView` is the launchpad. Sections accessed from it:

```
BandHomeView (Home tab)
├── Band Header (avatar, name, church, role badge)
├── Quick Stats Bar (Services count · Songs count · Rehearsals count)
├── Quick Access Grid (2×2) — NavigationLinks to full section views
│   ├── 🎵 Services     → ServicesView
│   ├── 🎶 Songs        → SongLibraryView
│   ├── 📅 Schedule     → RehearsalsView
│   └── 👥 Team         → MembersView
├── Next Service card (or Next Rehearsal card if no upcoming service)
├── Upcoming Services (horizontal scroll, cards)
└── Recent Songs (horizontal scroll, chip pills)
```

`MainTabView` — only 2 tabs:
- **Home** (`house.fill`) → `BandHomeView`
- **Settings** (`gearshape.fill`) → `NavigationStack { SettingsView() }`

---

## Supabase Storage

- **Bucket**: `band-avatars` (public)
- **Path pattern**: `bands/{bandId}/avatar.{jpg|png}`
- Avatar URL is cached-busted with `?t={timestamp}` on upload
- Max file size: 5 MB (enforced by multer on the backend)

---

## Push Notifications

- **Provider**: Firebase Cloud Messaging (FCM) via `firebase-admin` on the backend
- **Trigger**: New rehearsal creation automatically notifies all band members except the creator
- **Device token registration**: iOS calls `POST /notifications/register` with the FCM token on app launch (see `NotificationService.swift`)
- **APNS config**: `aps.sound = "default"`, `aps.badge = 1`
- Firebase credentials live in env vars: `FCM_PROJECT_ID`, `FCM_PRIVATE_KEY`, `FCM_CLIENT_EMAIL`

---

## Practice / Metronome

- Fully on-device — no audio files, no network
- `PracticeAudioEngine`: generates click buffers via `AVAudioEngine` using sine wave math
- `PracticeManager.shared`: `ObservableObject` wrapper, exposes `showFullPlayer: Bool`
- `PracticeMiniPlayerView`: floating bar above tab bar in `MainTabView` (`.padding(.bottom, 49)`)
- `PracticeSessionView`: full-screen cover launched from `MainTabView` when `practice.showFullPlayer == true`

---

## Running the Project

### Backend (local dev)
```bash
cd backend
npm install
npm run dev          # tsx watch — hot reload on port 3000
npm run build        # TypeScript compile to dist/
```

### Backend (deploy)
```bash
# Just push to main — Vercel auto-deploys
git push origin main
```

### iOS
1. Open `iOS/WorshipFlow.xcodeproj` (generated by XcodeGen from `iOS/project.yml`)
2. Select `WorshipFlow` scheme → any iOS 17+ simulator or device
3. Build & Run

### Regenerate Xcode project after editing project.yml
```bash
cd iOS
xcodegen generate
```

---

## Code Style Conventions

- **File naming**: `FeatureNameView.swift`, `FeatureNameViewModel.swift`
- **MARK sections**: `// MARK: - Section Name` in all files with multiple sections
- **No force unwraps** (`!`) unless absolutely guaranteed (e.g., static assets)
- **Error handling**: All `APIClient` calls wrapped in `do/catch`, errors set to `self.error` string
- **Skeleton loading**: Show `SkeletonBlock` views when `isLoading && data.isEmpty`, not spinners
- **Section headers**: Use `SectionHeader(title:)` component, not inline `Text` + styling
- **Empty states**: Use `EmptyStateView(icon:title:subtitle:)` component
- **Card containers**: Use `.cardStyle()` or `.elevatedCardStyle()` modifiers
- **Button styles**: `.primaryButton()`, `.secondaryButton()`, `.destructiveButton()` modifiers
- **Text fields**: `.appTextField()` modifier

---

## Known Limitations / Watch-Outs

1. **SourceKit false positives**: SourceKit often shows "Cannot find type X in scope" errors in isolation — these are noise. The project compiles fine in Xcode with all targets resolved.
2. **No email verification**: Signup uses `supabaseAdmin.auth.admin.createUser` with `email_confirm: true` to skip verification.
3. **setlists ≈ services**: The `Setlist` model powers both "Setlists" and "Services" views — `serviceType`, `location`, and `theme` fields make a setlist a "service plan". The `ServicesView` filters/displays them in a service-calendar style.
4. **Tokens in UserDefaults**: Not using Keychain currently — tokens are in UserDefaults for simplicity. Consider migrating to Keychain for production hardening.
5. **No pagination**: All data fetches return full lists. Band song libraries and setlists could grow large — pagination should be added if scale requires it.
6. **Band member count**: Computed live on `GET /bands/:id` via a Supabase count query — not a stored column.
7. **setlist_songs.position uniqueness**: The DB enforces `UNIQUE(setlist_id, position)` — reorder must update all affected positions atomically.
