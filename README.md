# ArpFace iOS

An expressive iOS arpeggiator app that brings waveforms to life through an animated character face.

## Features

### Multi-Waveform Arpeggiator
- **27 unique waveforms**: sine, triangle, saw, square, pulse, supersaw, FM modulated, and many more
- **Independent ARP sequences**: Each waveform has its own 16-step arpeggiator
- **Multiple ARP modes**: Forward, backward, pendulum, and random playback patterns
- **Step programming**: Activate/deactivate individual steps for custom patterns
- **Smooth crossfade transitions**: Clean note changes without audio pops

### Interactive Character
- **Animated face**: Visual feedback through expressive character animations
- **Waveform visualization**: Real-time animated waveforms displayed as the character's mouth
- **BPM-synchronized animations**: Character mouth movement matches the arpeggiator tempo
- **Mode-specific expressions**: Different facial expressions for browse, play, and selecting modes

### Audio Engine
- **Professional quality synthesis**: High-fidelity waveform generation
- **16-voice polyphony**: Support for complex harmonic sequences
- **Clean looping**: Zero-crossing audio buffers prevent clicks and pops
- **Real-time parameter control**: Drag gestures for frequency modulation

### User Interface
- **Grid-based step sequencer**: 4x4 grid for intuitive pattern programming
- **Color-coded waveforms**: Each waveform has its own distinct color
- **Dual-mode interaction**: Instrument playing when ARP is off, step programming when ARP is on
- **Clean, responsive design**: Optimized for iPad and iPhone

## Technical Implementation

Built with Swift and SwiftUI, using AVFoundation for professional audio synthesis. Features include:

- **Advanced audio engine**: Custom AVAudioPlayerNode pool for polyphonic playback
- **Waveform-specific note tracking**: Isolated audio state for each waveform type
- **Timer-based sequencing**: Precise BPM control with smooth transitions
- **Real-time visual feedback**: Synchronized animations with audio playback

## Getting Started

1. Clone the repository
2. Open `WaveFace.xcodeproj` in Xcode
3. Build and run on iOS simulator or device
4. Select a waveform and start creating patterns!

## Controls

- **Waveform buttons**: Select different synthesis types
- **Grid pads**: When ARP is off - play as instrument; when ARP is on - program steps
- **PLAY button**: Cycle through ARP modes (off → forward → backward → pendulum → random → off)
- **STOP button**: Stop all audio and reset sequences
- **Character face**: Drag vertically to modulate frequency in real-time

---

🎵 Created with Claude Code