# Music Files

## bgm_fast.mp3 - NEEDS TO BE REPLACED

**Current Status:** This is currently just a copy of `bgm.mp3` and needs to be replaced with a properly pitch-shifted version.

**Required:** Create a version of `bgm.mp3` that is pitched up by 1.5x (50% faster/higher pitch).

### How to create the pitched version:

#### Option 1: Using Audacity (Free, Recommended)
1. Download and install [Audacity](https://www.audacityteam.org/)
2. Open `bgm.mp3` in Audacity
3. Select all (Ctrl+A)
4. Go to **Effect > Pitch and Tempo > Change Speed and Pitch...**
5. Set **Speed** to **50** (for 50% increase = 1.5x)
6. Click OK
7. Export as `bgm_fast.mp3` (File > Export > Export as MP3)
8. Replace the existing `bgm_fast.mp3` file

#### Option 2: Using ffmpeg (Command Line)
If you have ffmpeg installed:
```bash
ffmpeg -i bgm.mp3 -filter:a "asetrate=44100*1.5,aresample=44100" bgm_fast.mp3
```

#### Option 3: Online Tools
- Upload `bgm.mp3` to [Audio Speed Changer](https://audiotrimmer.com/audio-speed-changer/)
- Set speed to 1.5x
- Download and save as `bgm_fast.mp3`

### Why this change?

Previously, the game was using `pitch_scale = 1.5` in code to speed up the music. However, this caused issues in web exports where the pitch would reset to normal after the first loop. Using a pre-pitched audio file solves this problem completely by removing the need for runtime pitch adjustment.
