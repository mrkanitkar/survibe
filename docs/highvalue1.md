# SurVibe + AudioKit Ecosystem: Enhancement Analysis

> Date: March 2026 | Based on codebase audit of SVAudio, main app target, and AudioKit org packages

---

## 1. Current State — What SurVibe Uses Today

SurVibe is **97% pure Apple frameworks** (AVFoundation + Accelerate/vDSP). AudioKit is imported but barely used.

### SPM Dependencies (in SVAudio/Package.swift)

| Package | Version | Actual Usage |
|---------|---------|-------------|
| AudioKit | 5.6.0 | `Node` protocol conformance for AudioNodeAdapter only |
| SoundpipeAudioKit | 5.6.0 | **Not used at all** — declared but zero imports in source |
| Microtonality | branch: main | Static JI ratio constants copied; `TuningTable` not used at runtime |
| AudioKitUI | (via AudioKit) | `NodeOutputView` (waveform) + `SpectrogramView` (spectrogram) |

### Component-by-Component Breakdown

| Component | AudioKit? | Framework Used | Implementation |
|-----------|-----------|---------------|----------------|
| Audio Engine | No | AVAudioEngine (single instance) | `AudioEngineManager.shared` |
| Piano Sampler | No | AVAudioUnitSampler | `SoundFontManager` — UprightPianoKW.sf2 |
| Tanpura Drone | No | AVAudioPlayerNode + `.loops` | `TanpuraPlayer` — pre-recorded loop |
| Metronome | No | AVAudioPlayerNode + AVAudioTime | `MetronomePlayer` — sample-accurate scheduling |
| Pitch Detection (primary) | No | vDSP_dotpr + vDSP_vsmul | `AudioKitPitchDetector` — autocorrelation algorithm |
| Pitch Detection (fallback) | No | vDSP_rmsqv | `YINPitchDetector` — YIN algorithm |
| Confidence Metric | No | Pure math | `SpectralConfidence` — peak-to-sidelobe ratio |
| Chord Detection | No | Accelerate FFT | `ChromagramDSP` — custom chromagram |
| Raga Tuning | Partial | Static constants from Microtonality | `RagaTuningProvider` — hardcoded JI ratios |
| Visualization | **Yes** | AudioKitUI | `AudioNodeAdapter` → `NodeOutputView`, `SpectrogramView` |
| Mic Input | No | AVAudioEngine.installTap | Direct buffer tap on inputNode |

### Key Architectural Constraints

- **Single AVAudioEngine** — one engine instance, managed by `AudioEngineManager.shared`
- **One tap per node per bus** — mic tap on inputNode bus 0, viz tap on mainMixerNode bus 0
- **AudioKit Node adapter** — `AudioNodeAdapter` wraps AVAudioEngine's mainMixerNode as an AudioKit `Node` for UI components
- **No AudioKit routing** — all audio routing is pure AVAudioEngine node connections

---

## 2. AudioKit Ecosystem — Available Packages

### Already Imported (zero-cost to use)

#### AudioKit Core (`github.com/AudioKit/AudioKit` 5.6.0)
- **Taps**: `AmplitudeTap` (smoothed VU metering), `FFTTap` (frequency analysis callback), `PitchTap` (pitch detection), `RawDataTap` (raw buffer access), `RawBufferTap`
- **NodeRecorder**: Record any node's output to audio file (WAV/CAF/M4A)
- **MIDI**: `MIDIListener`, `MIDIInstrument`, MIDI file parsing
- **Table**: Wavetable generation (sine, triangle, square, sawtooth, harmonic, custom)
- **Node**: Protocol for audio graph connectivity

#### SoundpipeAudioKit (`github.com/AudioKit/SoundpipeAudioKit` 5.6.0)
- **Filters**: `LowPassFilter`, `HighPassFilter`, `BandPassFilter`, `MoogLadder`, `ResonantFilter`, `PeakingParametricEqualizer`, `ThreePoleLowpassFilter`
- **Reverb**: `ZitaReverb`, `CostelloReverb`, `FlatFrequencyResponseReverb`, `ChowningReverb`
- **Delay**: `VariableDelay`, `StereoDelay`
- **Dynamics**: `Compressor`, `DynamicRangeCompressor`
- **Oscillators**: `Oscillator`, `DynamicOscillator`, `MorphingOscillator`, `PhaseDistortionOscillator`, `PWMOscillator`, `FMOscillator`
- **Generators**: `WhiteNoise`, `PinkNoise`, `BrownianNoise`, `Drip`, `MetalBar`, `PluckedString`, `VocalTract`
- **Analysis**: `PitchTap` (Soundpipe-based pitch tracker)

#### AudioKitUI (`github.com/AudioKit/AudioKitUI`)
- `NodeOutputView` — real-time waveform oscilloscope ✅ (already used)
- `SpectrogramView` — real-time spectrogram ✅ (already used)
- `FFTView` — frequency-domain bar graph
- `RollingView` — scrolling time-domain display
- `KeyboardView` — interactive piano keyboard with multi-touch

#### Microtonality (`github.com/AudioKit/Microtonality` branch: main)
- `TuningTable` — load/create arbitrary tuning systems
- 100+ built-in presets (Erv Wilson scales, historical temperaments)
- `npo()` — n-notes-per-octave generator
- Indian music: 22-shruti system, various raga presets

### New Dependencies (require approval)

#### AudioKitEX (`github.com/AudioKit/AudioKitEX`)
- **Sequencer**: MIDI step sequencer with loop points
- **CallbackInstrument**: Trigger Swift callbacks from sequencer events
- **Apple Sequencer wrapper**: AVAudioSequencer integration
- Dependencies: AudioKit

#### DunneAudioKit (`github.com/AudioKit/DunneAudioKit`)
- **Synth**: Polyphonic synthesizer with multi-oscillator, filter, ADSR
- **Sampler**: Advanced SFZ/WAV sampler with multi-layer velocity
- **Chorus**, **Flanger**, **StereoDelay**, **Transient Shaper**
- Dependencies: AudioKit

#### STKAudioKit (`github.com/AudioKit/STKAudioKit`)
- **Physical modeling instruments**: Flute, Clarinet, Sitar, Mandolin, PluckedString, TubularBells, Shaker, BeeBox, RhodesKeyboard
- Based on Stanford's Synthesis Toolkit (STK)
- Dependencies: AudioKit

#### PianoRoll (`github.com/AudioKit/PianoRoll`)
- **SwiftUI piano roll view**: Note grid editor
- Drag-to-create, resize, delete notes
- Customizable colors and grid
- Dependencies: None (standalone SwiftUI)

---

## 3. Enhancement Opportunities

### HIGH VALUE — Direct Feature Enhancement

#### H1. NodeRecorder — Practice Session Audio Recording
**Current gap:** `PracticeSessionRecorder` records metadata only (notes, scores, timestamps). No audio.

**Enhancement:** AudioKit's `NodeRecorder` can record any node's output to file.
- Record the mainMixerNode (piano + mic combined) during practice
- Save as M4A/CAF alongside session metadata
- "Listen back" button in `PracticeSessionSummaryView`
- Share recordings with teachers/friends
- Track improvement by comparing recordings over time

**Integration point:** `AudioNodeAdapter.shared` already wraps mainMixerNode as a `Node` — NodeRecorder can attach directly.

**New dependency:** None — AudioKit core already imported.

**Files affected:**
- `SVAudio/Engine/AudioEngineManager.swift` — expose recording start/stop
- `SurVibe/Practice/PracticeSessionRecorder.swift` — add audio recording
- `SurVibe/Practice/PracticeSessionSummaryView.swift` — add playback UI

---

#### H2. SoundpipeAudioKit Filters — Improve Pitch Detection Accuracy
**Current gap:** Raw mic input feeds directly into pitch detection. No pre-processing. Noisy environments degrade accuracy.

**Enhancement:** Insert SoundpipeAudioKit DSP filters in the mic input chain:
- `HighPassFilter` (cutoff ~80Hz) — remove room rumble, AC hum, handling noise
- `LowPassFilter` (cutoff ~2000Hz) — remove high-frequency noise above piano range
- `PeakingParametricEqualizer` — optionally boost the fundamental frequency band
- `Compressor` — normalize input levels across quiet/loud environments

**Pipeline:**
```
inputNode → HighPassFilter → LowPassFilter → [tap for pitch detection]
                                            → mainMixerNode (for visualization)
```

**Latency budget:** Each filter adds ~1-2ms. Total pipeline stays well under 50ms.

**New dependency:** None — SoundpipeAudioKit already in Package.swift but unused.

**Files affected:**
- `SVAudio/Engine/AudioEngineManager.swift` — insert filter nodes in chain
- `SVAudio/Pitch/AudioKitPitchDetector.swift` — tap filtered output instead of raw input

---

#### H3. FFTView / RollingView — Complete Pitch Track Visualization
**Current gap:** `AudioVisualizationView` has 4 modes but "Pitch Track" is a placeholder saying "Coming in a future update."

**Enhancement:** Use AudioKitUI views already available:
- `FFTView` — frequency spectrum bar graph (shows harmonics of detected note)
- `RollingView` — scrolling pitch-over-time display (like a simplified spectrogram)
- Wire to existing `AudioNodeAdapter.shared`

**Integration:**
```swift
case .pitchTrack:
    FFTView(AudioNodeAdapter.shared, barColor: .rangNeel)
        .accessibilityLabel("Frequency spectrum")
```

**New dependency:** None — AudioKitUI already imported.

**Files affected:**
- `SurVibe/Audio/AudioVisualizationView.swift` — replace placeholder with real view

---

#### H4. Sequencer + CallbackInstrument — Taal Pattern Engine
**Current gap:** MetronomePlayer produces flat, identical clicks. No concept of taal patterns (Sam/Khali/Tali accents), no taal-specific timbres.

**Enhancement:** Use AudioKitEX Sequencer:
- Define taal patterns as MIDI note sequences (e.g., Teentaal: 16 beats, Sam on beat 1, Khali on beat 9)
- `CallbackInstrument` triggers different samples per beat type:
  - Sam (beat 1): heavy tabla "dha" sound
  - Khali (empty beats): light "na" sound
  - Tali (clap beats): medium "dhin" sound
- Visual taal cycle indicator synced to sequencer position
- Support multiple taals: Teentaal (16), Jhaptaal (10), Rupak (7), Ektaal (12), Dadra (6)

**New dependency:** AudioKitEX (requires approval).

**Files affected:**
- `SVAudio/Playback/MetronomePlayer.swift` — refactor to TaalPlayer
- New: `SVAudio/Playback/TaalPattern.swift` — taal definitions
- `SurVibe/Practice/PracticeControlsToolbar.swift` — taal selector UI

---

#### H5. STKAudioKit — Synthesized Tanpura Drone
**Current gap:** Tanpura uses a pre-recorded audio loop. Fixed Sa pitch. Cannot adjust to user's chosen tonic.

**Enhancement:** Use STKAudioKit's physical models:
- `Sitar` model — plucked string synthesis matching tanpura timbre
- `PluckedString` — alternative simpler model
- Generate Sa-Pa-Sa-Sa drone pattern synthesized in real-time
- User sets their Sa (any frequency) — drone adjusts instantly
- Adjustable: string brightness, decay, sympathetic resonance

**Bonus:** `Shaker` model for optional percussion accompaniment.

**New dependency:** STKAudioKit (requires approval).

**Files affected:**
- `SVAudio/Playback/TanpuraPlayer.swift` — replace loop with synthesis
- New: `SVAudio/Playback/TanpuraSynthesizer.swift` — STK-based generator

---

#### H6. Microtonality TuningTable at Runtime
**Current gap:** `RagaTuningProvider` hardcodes JI ratios as static `Double` constants copied from Microtonality's Erv Wilson preset. Maintenance burden; can't add custom tunings.

**Enhancement:** Use `TuningTable` at runtime:
- Load any of 100+ built-in presets dynamically
- Support the full 22-shruti system (not just 12-note subset)
- Enable user-defined custom tunings
- `TuningTable.npo(notesPerOctave:)` for experimental scales

**Sendability workaround:** `TuningTable` is `NSObject` (not Sendable). Snapshot values on MainActor into `RagaContext` (already Sendable):
```swift
@MainActor
func loadRaga(_ name: String) -> RagaContext {
    let table = TuningTable()
    table.presetPersian17NorthIndian() // or other preset
    let ratios = table.masterSet.map { $0.1 } // extract frequency ratios
    // Build RagaContext from ratios...
}
```

**New dependency:** None — Microtonality already imported.

**Files affected:**
- `SVAudio/Pitch/RagaTuningProvider.swift` — replace hardcoded ratios with TuningTable

---

### MEDIUM VALUE — UX Polish

#### M1. AmplitudeTap for Smoothed VU Metering
**Current:** `PitchDSP.calculateRMS()` manually calls `vDSP_rmsqv` on each buffer. No smoothing.

**Enhancement:** AudioKit's `AmplitudeTap`:
- Configurable smoothing window
- Peak vs. RMS modes
- Callback-based — cleaner than manual buffer processing

**New dependency:** None.

---

#### M2. AudioKitUI KeyboardView
**Current:** `InteractivePianoView` is custom SwiftUI (~450 lines).

**Enhancement:** AudioKitUI `KeyboardView`:
- Multi-touch built-in
- Velocity sensitivity
- Note highlighting from external input

**Risk:** May not support Sargam labels or Rang colors without customization.

**New dependency:** None.

---

#### M3. PianoRoll for Song/Lesson Visual Editor
**Current:** Songs defined in JSON seed files only.

**Enhancement:** AudioKit `PianoRoll`:
- Visual note grid editor
- Teachers create custom exercises
- Display songs as scrolling piano roll during play-along

**New dependency:** PianoRoll package.

---

#### M4. DunneAudioKit Sampler for Multi-Instrument
**Current:** Single AVAudioUnitSampler with one piano SoundFont.

**Enhancement:** DunneAudioKit `Sampler`:
- SFZ format support (more expressive)
- Multi-layer velocity response
- Load harmonium, sitar, tabla alongside piano

**New dependency:** DunneAudioKit (requires approval).

---

## 4. Priority Matrix

| # | Enhancement | New Dep? | Effort | User Impact | Risk |
|---|------------|----------|--------|-------------|------|
| **H1** | NodeRecorder (practice recording) | No | Medium | High — hear your progress | Storage mgmt |
| **H2** | SoundpipeAudioKit filters (accuracy) | No | Medium | High — works in noisy rooms | Latency budget |
| **H3** | FFTView/RollingView (pitch track) | No | Low | Medium — completes viz modes | Minimal |
| **H4** | Sequencer for taal patterns | AudioKitEX | High | High — culturally authentic | Engine integration |
| **H5** | STK tanpura synthesis | STKAudioKit | High | High — dynamic Sa tuning | CPU profiling |
| **H6** | TuningTable runtime | No | Low | Medium — eliminates hardcoded ratios | NSObject threading |
| **M1** | AmplitudeTap VU metering | No | Low | Low — smoother meters | Tap bus conflict |
| **M2** | KeyboardView replacement | No | Medium | Low — less custom code | Customization |
| **M3** | PianoRoll editor | PianoRoll | Medium | Medium — user content | Package maturity |
| **M4** | DunneAudioKit multi-instrument | DunneAudioKit | High | Medium — more instruments | CPU overhead |

### Recommended Implementation Order

**Phase 1 — Zero new dependencies (leverage what's already imported):**
1. H3: Complete pitch track visualization (Low effort, immediate visible result)
2. H6: Microtonality TuningTable at runtime (Low effort, removes tech debt)
3. H1: NodeRecorder for practice recording (Medium effort, major feature)
4. H2: SoundpipeAudioKit filter chain (Medium effort, measurable quality improvement)
5. M1: AmplitudeTap (Low effort, polish)

**Phase 2 — New dependencies (require approval per CLAUDE.md):**
6. H4: Taal pattern sequencer (AudioKitEX)
7. H5: Synthesized tanpura (STKAudioKit)
8. M4: Multi-instrument sampler (DunneAudioKit)
9. M3: Piano roll editor (PianoRoll)

---

## 5. Integration Considerations

### Single-Engine Pattern
All AudioKit nodes must attach to `AudioEngineManager.shared`'s engine. The `AudioNodeAdapter` pattern already solves this — extend it for new nodes.

### Tap Bus Limits
Only one tap per node per bus. Current taps:
- `inputNode` bus 0 → mic tap (pitch detection)
- `mainMixerNode` bus 0 → viz tap (AudioNodeAdapter)

Adding `AmplitudeTap` or `NodeRecorder` on mainMixerNode requires multiplexing or using a different bus.

### Sendability
AudioKit `Node` and `TuningTable` are `NSObject` subclasses (not Sendable). Always read on `@MainActor`, snapshot values into Sendable structs for DSP.

### Binary Size
Each AudioKit package adds to binary size:
- AudioKit core: ~2MB
- SoundpipeAudioKit: ~5MB (C DSP libraries)
- STKAudioKit: ~3MB (STK C++ libraries)
- AudioKitUI: ~500KB

SurVibe already pays the AudioKit + SoundpipeAudioKit cost without using SoundpipeAudioKit.
