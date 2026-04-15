# Worship Manager — Web

A Next.js 15 (App Router) web client for **Worship Manager**. It mirrors the
iOS SwiftUI app's structure and talks to the same Node/Express backend deployed
on Vercel at `https://worship-manager-psi.vercel.app`.

## Stack

| Layer | Tool |
| --- | --- |
| Framework | Next.js 15 · React 19 · App Router |
| Language | TypeScript (strict) |
| Styling | Tailwind CSS with design tokens that mirror iOS `AppTheme` |
| State (server) | TanStack Query |
| State (client) | Zustand (persisted) |
| Icons | Lucide |
| Fonts | Inter + Fraunces (display) + JetBrains Mono |

## Getting started

```bash
cd web
cp .env.local.example .env.local
npm install
npm run dev
```

Open http://localhost:3000.

### Environment variables

| Key | Description |
| --- | --- |
| `NEXT_PUBLIC_API_BASE_URL` | Backend base URL. Defaults to the production Vercel deployment. |

## Project layout

```
src/
├── app/
│   ├── (auth)/          # Welcome, login, signup — unauthenticated pages
│   ├── (app)/           # Authenticated shell (sidebar + content)
│   │   ├── home/
│   │   ├── bands/{create,join}/
│   │   ├── songs/[id]/
│   │   ├── services/[id]/
│   │   ├── rehearsals/
│   │   ├── members/
│   │   └── settings/
│   ├── layout.tsx       # Root layout with fonts + providers
│   ├── providers.tsx    # React Query provider
│   └── globals.css      # Design tokens + Tailwind layers
├── components/
│   ├── layout/          # AuthGate, BandRequired, Sidebar
│   └── ui/              # Button, Card, Input, Modal, BandAvatar, …
├── lib/
│   ├── api/             # Typed API modules (client.ts, auth.ts, bands.ts, …)
│   ├── stores/          # Zustand stores (auth, band)
│   ├── config.ts
│   └── utils.ts
└── types/               # Shared TS types mirroring the backend contract
```

## Architecture notes

- **Auth flow.** `AuthGate` redirects unauthenticated visitors to `/login`.
  Tokens live in `localStorage` (`worshipflow_access_token` / `_refresh_token`)
  to match the iOS app's `APIClient`. The wrapper auto-refreshes on 401.
- **Band context.** `BandRequired` auto-selects the user's first band into the
  Zustand `band-store` and renders an onboarding empty state if none exists.
  The `/bands/create` and `/bands/join` routes bypass the gate.
- **Design system.** All colors and typography come from CSS variables in
  `globals.css`, exposed as Tailwind tokens (`bg-accent`, `text-primary`, etc.)
  so the component layer never reaches for raw values.
- **Data fetching.** Every feature page uses TanStack Query with keys shaped
  as `["songs", bandId]`, `["setlists", bandId]`, etc. Mutations invalidate
  the relevant cache entries.

## Features

| Feature | Route |
| --- | --- |
| Home dashboard (quick access, next rehearsal, upcoming services, recent songs) | `/home` |
| Song library with search + create | `/songs` |
| Song detail (lyrics, notes, external links, delete) | `/songs/[id]` |
| Services list with upcoming/past split | `/services` |
| Service detail with add-song modal and setlist ordering | `/services/[id]` |
| Rehearsals schedule with inline RSVP | `/rehearsals` |
| Team members with invite code + role management | `/members` |
| Profile, band switcher, sign out | `/settings` |
| Create / join band | `/bands/create`, `/bands/join` |

## Scripts

```bash
npm run dev        # Dev server
npm run build      # Production build
npm run start      # Start production server
npm run lint       # ESLint
npm run typecheck  # TypeScript only
```
