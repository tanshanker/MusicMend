# MusicMend

A native macOS app that fixes your MP3 music library. Fetches missing lyrics, adds album artwork, cleans up bad metadata like spam URLs and encoding artifacts, and renames files with URLs in their names.

## Features

- **Scan your library** - Automatically scans your Apple Music folder or any custom folder for MP3 files
- **Fetch lyrics** - Pulls lyrics from [LRCLIB](https://lrclib.net) (free, no API key needed)
- **Fetch album artwork** - Gets cover art from [MusicBrainz](https://musicbrainz.org) + [Cover Art Archive](https://coverartarchive.org) (free, no API key needed)
- **Clean bad metadata** - Removes URLs, spam text, and fixes encoding issues in title/artist/album fields
- **Clean filenames** - Detects and removes URLs and spam from MP3 filenames
- **Batch processing** - Fix your entire library at once with progress tracking
- **Individual editing** - Edit any track's metadata manually
- **Safe backups** - Creates backups before modifying any file
- **Drag and drop** - Drop a folder onto the app to scan it
- **Native macOS** - Built with SwiftUI, feels right at home on your Mac

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (to build from source)

## Installation

### Build from Source

1. **Clone the repository:**

```bash
git clone https://github.com/tanshanker/MusicMend.git
cd MusicMend
```

2. **Build with Swift Package Manager:**

```bash
swift build -c release
```

The built binary will be at `.build/release/MusicMend`.

3. **Or open in Xcode:**

```bash
open Package.swift
```

Then press `Cmd+R` to build and run.

## How It Works

### 1. Scan Your Music

Launch the app and either:
- Click **Music Library** in the sidebar to scan your default Apple Music folder (`~/Music/Music/Media.localized/`)
- Click **Choose Folder...** to pick any folder with MP3 files
- **Drag and drop** a folder onto the app window

The app reads all MP3 files and their ID3 metadata, then shows them in a list.

### 2. See What's Wrong

Each track is analyzed for issues:
- Missing lyrics
- Missing album artwork
- URLs in metadata fields (e.g., download sites left in the title)
- Spam text (e.g., "ripped by...", "downloaded from...")
- Encoding artifacts (e.g., garbled characters from wrong encoding)
- URLs or spam in the filename itself

Issues show up as orange warning badges. Use the sidebar filters to quickly find tracks that need attention.

### 3. Fix Everything

**Fix one track at a time:**
- Click a track to see its details
- Click "Fetch Lyrics" or "Fetch Artwork" buttons
- Edit metadata fields manually
- Click "Save Changes"

**Fix everything at once:**
- Click the "Fix All" toolbar button
- Choose what to fix (lyrics, artwork, metadata cleaning)
- Click "Start" and watch the progress bar

### 4. Your Files Are Safe

Before modifying any MP3 file, MusicMend creates a backup in `~/.musicmend-backups/`. If anything goes wrong, your original files are preserved.

## Project Structure

```
MusicMend/
├── Package.swift                    # Swift Package Manager config
├── MusicMend/
│   ├── MusicMendApp.swift           # App entry point + Settings
│   ├── Models/                      # Data models
│   │   ├── TrackItem.swift          # Core track model
│   │   ├── TrackMetadata.swift      # ID3 metadata fields
│   │   ├── MetadataIssue.swift      # Issue types
│   │   └── RepairAction.swift       # Fix actions
│   ├── Services/                    # Business logic
│   │   ├── FileScanner.swift        # MP3 file discovery
│   │   ├── ID3Service.swift         # Read/write ID3 tags
│   │   ├── MetadataCleaner.swift    # Detect & clean bad data
│   │   ├── LRCLIBService.swift      # Lyrics API
│   │   ├── MusicBrainzService.swift # Album lookup API
│   │   ├── CoverArtService.swift    # Album art API
│   │   ├── BackupService.swift      # File backups
│   │   └── BatchProcessor.swift     # Batch operations
│   ├── ViewModels/                  # UI state management
│   │   ├── LibraryViewModel.swift   # Main library state
│   │   ├── TrackDetailViewModel.swift
│   │   └── BatchProcessViewModel.swift
│   ├── Views/                       # SwiftUI views
│   │   ├── ContentView.swift        # Main window layout
│   │   ├── Sidebar/                 # Source & filter sidebar
│   │   ├── TrackList/               # Track table
│   │   ├── Detail/                  # Track detail panel
│   │   └── Batch/                   # Batch progress UI
│   └── Utilities/
│       ├── RateLimiter.swift        # API rate limiting
│       └── StringCleaning.swift     # Regex-based text cleanup
```

## APIs Used

All APIs are **free and require no API keys**.

| API | Used For | Rate Limit |
|-----|----------|------------|
| [LRCLIB](https://lrclib.net) | Lyrics (plain + synced) | ~2 req/sec |
| [MusicBrainz](https://musicbrainz.org/doc/MusicBrainz_API) | Album/release lookup | 1 req/sec (strict) |
| [Cover Art Archive](https://coverartarchive.org) | Album artwork images | No limit |

## Dependencies

| Package | Purpose |
|---------|---------|
| [ID3TagEditor](https://github.com/chicio/ID3TagEditor) | Read/write MP3 ID3 tags |

That's it, just one external dependency. Everything else uses built-in Apple frameworks (Foundation, SwiftUI, AppKit).

## Settings

Open **MusicMend > Settings** (or `Cmd+,`) to configure:
- Default scan location
- Toggle URL removal from metadata
- Toggle spam text removal
- Toggle encoding artifact fixes

## Tips

- **Large libraries**: The app handles large libraries well, but batch artwork fetching is slow due to MusicBrainz's 1 request/second rate limit. Be patient with large collections.
- **Backups**: Check `~/.musicmend-backups/` if you need to restore original files. Old backups (30+ days) are automatically cleaned up.
- **Best results**: Tracks with at least a title and artist get the best results from lyrics/artwork lookups. Fix those fields first if they're wrong.

## License

MIT License. See [LICENSE](LICENSE) for details.
