# Choira Music

A Flutter music player built against the [Jamendo Music API](https://developer.jamendo.com/v3.0) as a take-home assignment for Choira MusicTech.

Browse and search a live music catalogue, see loading/error/empty states handled properly, scroll through paginated results without duplicate requests, and play tracks with a full transport (play/pause, next/previous, seek) and a persistent mini player.

---

## 1. Setup instructions

**Requirements:** Flutter 3.41+ (Dart 3.11+), an Android device or emulator.

```bash
git clone <this-repo-url>
cd Choira_Assignment
flutter pub get
cp .env.example .env
```

Open `.env` and set your Jamendo client ID (see [API configuration](#2-api-configuration-instructions) below), then:

```bash
flutter run
```

To build a release APK:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 2. API configuration instructions

The assignment brief includes the Jamendo client ID directly in its own text, which means it isn't actually a secret — but it's still treated as configuration, not a hardcoded constant, because that's the correct practice regardless of whether a specific value happens to be public.

- The client ID is read from a `.env` file at runtime via [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv), never hardcoded in Dart source.
- `.env` is listed in `.gitignore` and is **not** committed to this repository.
- `.env.example` **is** committed, containing a placeholder:
  ```
  JAMENDO_CLIENT_ID=your_client_id_here
  ```
- To run the app, copy `.env.example` to `.env` and fill in a real client ID (the one given in the assignment brief works fine).
- `main.dart` loads it once at startup with `dotenv.load(fileName: '.env')`, and `JamendoApi` reads it via `dotenv.env['JAMENDO_CLIENT_ID']`.

---

## 3. Architecture and state management

**State management: [Provider](https://pub.dev/packages/provider).** Not Bloc, not Riverpod — Provider is the tool I've actually shipped in production, and this assignment is explicitly a precursor to a live coding round, so speed and familiarity mattered more than reaching for something unfamiliar to look impressive.

### Layers

```
lib/
  models/track.dart              Track — plain data class + fromJson/toJson
  services/jamendo_api.dart      raw HTTP calls to Jamendo, returns parsed Tracks
  repositories/track_repository.dart   network + Hive cache, behind one interface
  providers/
    track_list_provider.dart     browse + search + pagination state
    player_provider.dart         playback state, wraps just_audio
  screens/home_screen.dart, now_playing_screen.dart
  widgets/track_tile.dart, mini_player.dart, seek_bar.dart
```

**Why a repository layer between the providers and the API/cache?** Screens and providers never talk to `http` or `Hive` directly — they only ever call `TrackRepository`. That means the data source can change (add a second API, change the caching strategy, swap Jamendo entirely) by editing one file, with zero changes anywhere else in the app.

**Why two separate providers instead of one?** `TrackListProvider` (the list/search/pagination state) and `PlayerProvider` (playback state) change for completely different reasons and at completely different rates — playback position ticks every ~200ms while a track plays, while the list only changes on fetch/search/scroll. Keeping them separate means the seek bar can rebuild constantly without the track list rebuilding along with it, and vice versa.

### Pagination — the three rules the assignment calls out by name

All three live in `TrackListProvider._fetchPage()`:

1. **No duplicate requests while loading** — an `_isFetching` guard returns immediately if a fetch is already in flight.
2. **Properly handle the end of the list** — when a page comes back with fewer items than the page size, `hasMore` flips to `false` and no further requests are issued, no matter how much more the user scrolls.
3. **Load the next page near the bottom** — `HomeScreen`'s `ScrollController` fires `loadMore()` at ~80% of scroll extent, not at the exact bottom, so paging feels continuous rather than abrupt.

Search and browse are treated as **separate paginated streams**: `search()` and `loadInitial()` both go through the same `_reset()` method, which clears the offset, `hasMore`, and the track list together, so a new search can never mix results with the previous browse (or search) session.

### Playback

`PlayerProvider` wraps a single `just_audio.AudioPlayer`, holds the current queue and index, and listens to `positionStream` / `durationStream` / `playerStateStream` internally so the rest of the app just reads plain getters (`position`, `duration`, `isPlaying`) rather than dealing with streams directly. A track that fails to load (dead URL, network drop mid-stream) is caught and surfaced as a per-track error message instead of leaving the player looking frozen.

---

## 4. Scope notes

**What's in:**
- Full browse + search + pagination against the live Jamendo API, with the three pagination guards above
- Play/pause, next/previous, seek, live position/duration
- Loading, error, and empty states throughout
- Offline caching (bonus) — see below

**Offline caching (bonus), and its boundary:**
The first page of the browse list (20 tracks, with artwork) is cached via [Hive](https://pub.dev/packages/hive), so opening the app with no network still shows content instead of a blank error screen. Artwork itself is cached automatically on disk by `cached_network_image`. Search results are intentionally **not** cached — a stale search result reads as more broken than an honest empty state.

**Deliberately not attempted: offline *audio* playback.** Downloading and managing audio files for offline playback (storage limits, download queuing/cancellation, cache eviction) is a meaningfully larger feature than metadata caching, and was out of scope for the available timeframe. Cached metadata and artwork was the achievable, defensible version of "offline caching" — a stated boundary rather than a silent gap.

**Also out of scope, by design, not oversight:** authentication, playlists, favourites, theming toggles, and animation beyond basic transitions. None of these were asked for, and — since this assignment is explicitly a precursor to a live coding round — leaving room for features to be added live was part of the plan.

---

## 5. APK

Download: [`dist/choira-music.apk`](dist/choira-music.apk)

Built from this repo via `flutter build apk --release`. Installed and tested on a physical Android device (Android 15).
