# Lounge tour sound effects

Four short stingers cut from local ACE-Step 1.5 output. `.ogg` is Opus (Chrome, Firefox, Edge); `.mp3` is the Safari twin.
Both are 48 kHz stereo, same audio, about -16 LUFS integrated. Loudness is measured on the decoded files.

| file | duration | ogg size | mp3 size | LUFS (ogg / mp3) | peak (ogg) |
|---|---|---|---|---|---|
| cultural | 1.34 s | 16,222 B | 16,748 B | -16.1 / -16.0 | -1.3 dBFS |
| technical | 1.41 s | 17,649 B | 17,612 B | -16.0 / -16.0 | -4.3 dBFS |
| esports | 1.41 s | 18,983 B | 17,612 B | -15.9 / -15.9 | -2.4 dBFS |
| celebrate | 2.61 s | 26,321 B | 32,012 B | -16.0 / -16.0 | -3.8 dBFS |

(Opus adds 6.5 ms of container padding; the .mp3 durations are exact: 1.33, 1.40, 1.40, 2.60 s.)

## How they were made

Source clips: ACE-Step 1.5 `acestep-v15-turbo` DiT only (no LM, `thinking=False`), instrumental, lyrics `[Instrumental]`,
10 s, 8 inference steps, guidance 1.0, time signature 4, both CPU-offload flags, 8 GB RTX 5050. Takes were generated
with seeds 1-9 over about 25 prompt variants; a CLAP (`laion/clap-htsat-unfused`) zero-shot score, onset analysis and
cross-sound similarity picked the excerpts. Every excerpt starts on a detected onset (30 ms pre-roll), gets an 8 ms
fade-in and a cos^2 fade-out, then a gain to -16 LUFS (ffmpeg `ebur128` measurement, then `volume` + `alimiter` limit 0.84).
Opus: `libopus -b:a 64k -vbr on -application audio`. MP3: `libmp3lame -b:a 96k` with +0.5 dB (the MP3 decodes about 0.5 dB quieter).

### cultural
- Prompt: `Classical Indian dance. Tabla and pakhawaj rhythm, sitar pluck, sarangi, ghungroo bells jingling, expressive, graceful, kathak, poetic.`
- bpm 104, key G minor, seed 3 (take `cultural-b-s3`).
- Trim: source 5.16 s to 6.49 s (1.33 s). High-pass 70 Hz (2nd order, zero phase). Fade-out 280 ms. Gain -0.3 dB.
- Character: a bansuri/sitar-like woody phrase that opens loud and decays, with one accent hit at about 0.9 s. Mid register (F4-G5), warm, 2 onsets.

### technical
- Prompt: `Solo celesta and glockenspiel only. A quick rising sparkling arpeggio of crystal-clear high bell tones in C major, bright, airy, delicate, shimmering reverb, ambient, sparse, soft, magical, pure, high pitched.`
- bpm 90, key C major, seed 5 (take `technical-a-s5`).
- Trim: source 1.14 s to 3.94 s (2.8 s), then played at 2x speed (resample 1:2, +12 semitones, 1.4 s). High-pass 300 Hz (4th order). Fade-out 350 ms. Gain +1.7 dB.
- Character: the highest and sparkliest of the four. Four bell-like plucks around G6, D6, C6, G5, then a quick ringing decay. No energy below 300 Hz, no drums, tonal (spectral flatness 0.18).
- The 2x speed-up is an edit of the ACE-Step output; the unshifted take is a lower, pad-like phrase.

### esports
- Prompt: `Dark cyberpunk esports intro. Huge cinematic impact hit, distorted bass drop, sharp snare crack, rising siren, glitchy stutter, aggressive and menacing.`
- bpm 140, key D minor, seed 9 (take `esports-e-s9`).
- Trim: source 1.09 s to 2.49 s (1.40 s). High-pass 70 Hz. Fade-out 250 ms. Gain +0.1 dB.
- Character: dense, noisy and rhythmic: 11 onsets in 1.4 s (stuttering synth stabs around A4/D5 over low D#3 bass), gritty (spectral flatness 0.57, the other three are 0.14-0.18). The first 200 ms are about 8 dB below the body of the clip.

### celebrate
- Prompt: `Grand triumphant fanfare. Trumpets, timpani roll, cymbal crash, choir singing ahh, strings swell, victorious arrival, cinematic, warm, glorious.`
- bpm 100, key D major, seed 6 (take `celebrate-d-s6`).
- Trim: source 3.67 s to 6.27 s (2.6 s). High-pass 70 Hz. Fade-out 500 ms. Gain +1.9 dB.
- Character: full ensemble (CLAP: strings orchestra, trumpet fanfare), 11 onsets, steady dense level that swells and then fades. Twice as long as the others.

## Checks (ffmpeg silencedetect at -50 dB)

No silence at the start of any file. Trailing quiet at the very end of the fade: 43 ms (cultural), 23 ms (technical), 21 ms (esports), 31 ms (celebrate).

CLAP audio-embedding cosine similarity between sounds (lower = more different):

|  | cultural | technical | esports | celebrate |
|---|---|---|---|---|
| cultural | 1 | 0.54 | 0.41 | 0.46 |
| technical | 0.54 | 1 | 0.09 | 0.42 |
| esports | 0.41 | 0.09 | 1 | 0.31 |
| celebrate | 0.46 | 0.42 | 0.31 | 1 |

Not verified by ear. Listening quality is for Raja to judge.
