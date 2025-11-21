import SwiftUI

enum AppMode {
    case browse      // Normal waveform selection mode
    case selecting   // Waiting for user to select a waveform for pitch mode
    case play        // Pitch grid mode with selected waveform
}

enum ArpMode {
    case off
    case forward
    case backward
    case pendulum
    case random
}

enum ScaleType: String, CaseIterable {
    case major = "MAJ"
    case minor = "MIN"
    case dorian = "DOR"
    case phrygian = "PHR"
    case lydian = "LYD"
    case mixolydian = "MIX"
    case aeolian = "AEO"
    case locrian = "LOC"
    case harmonicMinor = "HMIN"
    case melodicMinor = "MMIN"
    case pentatonicMajor = "PENMAJ"
    case pentatonicMinor = "PENMIN"
    case blues = "BLU"
    case wholeTone = "WHL"
    case chromatic = "CHR"
    case diminished = "DIM"

    var color: (Double, Double, Double) {
        switch self {
        case .major: return (1.0, 0.0, 0.0)       // Bright Red
        case .minor: return (0.0, 0.0, 1.0)       // Bright Blue
        case .dorian: return (1.0, 0.5, 0.0)      // Bright Orange
        case .phrygian: return (0.6, 0.0, 1.0)    // Bright Purple
        case .lydian: return (1.0, 1.0, 0.0)      // Bright Yellow
        case .mixolydian: return (0.0, 1.0, 1.0)  // Bright Cyan
        case .aeolian: return (0.0, 1.0, 0.0)     // Bright Green
        case .locrian: return (1.0, 0.0, 1.0)     // Bright Magenta
        case .harmonicMinor: return (1.0, 0.4, 0.6) // Bright Pink
        case .melodicMinor: return (0.6, 1.0, 0.0) // Bright Lime
        case .pentatonicMajor: return (0.0, 0.8, 1.0) // Bright Sky Blue
        case .pentatonicMinor: return (1.0, 0.0, 0.5) // Bright Hot Pink
        case .blues: return (0.2, 0.6, 1.0)       // Bright Light Blue
        case .wholeTone: return (1.0, 0.6, 0.0)   // Bright Gold
        case .chromatic: return (0.8, 0.8, 0.8)   // Light Gray
        case .diminished: return (0.5, 0.0, 0.5)  // Medium Purple
        }
    }

    var intervals: [Float] {
        // Intervals as ratios for each scale
        switch self {
        case .major: return [1.0, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2.0]
        case .minor: return [1.0, 9/8, 6/5, 4/3, 3/2, 8/5, 9/5, 2.0]
        case .dorian: return [1.0, 9/8, 6/5, 4/3, 3/2, 5/3, 9/5, 2.0]
        case .phrygian: return [1.0, 16/15, 6/5, 4/3, 3/2, 8/5, 9/5, 2.0]
        case .lydian: return [1.0, 9/8, 5/4, 45/32, 3/2, 5/3, 15/8, 2.0]
        case .mixolydian: return [1.0, 9/8, 5/4, 4/3, 3/2, 5/3, 9/5, 2.0]
        case .aeolian: return [1.0, 9/8, 6/5, 4/3, 3/2, 8/5, 9/5, 2.0]
        case .locrian: return [1.0, 16/15, 6/5, 4/3, 64/45, 8/5, 9/5, 2.0]
        case .harmonicMinor: return [1.0, 9/8, 6/5, 4/3, 3/2, 8/5, 15/8, 2.0]
        case .melodicMinor: return [1.0, 9/8, 6/5, 4/3, 3/2, 5/3, 15/8, 2.0]
        case .pentatonicMajor: return [1.0, 9/8, 5/4, 3/2, 5/3, 2.0]
        case .pentatonicMinor: return [1.0, 6/5, 4/3, 3/2, 9/5, 2.0]
        case .blues: return [1.0, 6/5, 4/3, 64/45, 3/2, 9/5, 2.0]
        case .wholeTone: return [1.0, 9/8, 5/4, 45/32, 3/2, 27/16, 2.0]
        case .chromatic: return [1.0, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8, 2.0]
        case .diminished: return [1.0, 9/8, 6/5, 5/4, 45/32, 3/2, 8/5, 15/8, 2.0]
        }
    }
}

// Per-waveform ARP state
struct ArpState {
    var mode: ArpMode = .off
    var timer: Timer?
    var currentStep: Int = 0
    var direction: Int = 1
    var deactivatedSteps: Set<Int> = []
    var waveform: WaveformType
    var octaveOffset: Int = 0  // Per-waveform octave offset
    var bpm: Int = 120  // Default BPM
}

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    @State private var currentWaveform: WaveformType?
    @State private var backgroundColor: Color = .white  // Start with white background for play mode
    @State private var faceColor: Color = .black  // Start with black face for play mode
    @State private var appMode: AppMode = .play  // Start in play mode (ARP grid)
    @State private var selectedWaveformForPitch: WaveformType? = .sine  // Default to sine wave
    @State private var activePitchNotes: [WaveformType: Set<Int>] = [:]  // Track which pitch pads are active per waveform
    @State private var showingScaleSelection: Bool = false
    @State private var showingWaveSelection: Bool = false
    @State private var showingBpmSelection: Bool = false
    @State private var selectedScale: ScaleType = .major
    @State private var currentBpm: Int = 120

    // Per-waveform ARP settings - initialize with default sine state
    @State private var arpStates: [WaveformType: ArpState] = [.sine: ArpState(waveform: .sine)]

    // Universal play/stop state
    @State private var isGloballyPlaying: Bool = false

    // Root note selection (universal)
    @State private var rootNoteIndex: Int = 0  // 0 = C
    let rootNotes: [String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // Calculate root frequency based on selected note (C4 = 261.63 Hz)
    var rootFrequency: Float {
        let baseFrequency: Float = 261.63  // C4
        let semitoneRatio: Float = pow(2.0, 1.0/12.0)
        return baseFrequency * pow(semitoneRatio, Float(rootNoteIndex))
    }

    // Computed property for current ARP state
    var currentArpState: Binding<ArpState> {
        Binding(
            get: {
                guard let waveform = selectedWaveformForPitch else {
                    return ArpState(waveform: .sine)
                }
                return arpStates[waveform] ?? ArpState(waveform: waveform)
            },
            set: { newValue in
                guard let waveform = selectedWaveformForPitch else { return }
                arpStates[waveform] = newValue
            }
        )
    }

    // Check if any ARP is currently playing across all waveforms
    var isAnyArpPlaying: Bool {
        arpStates.values.contains { $0.mode != .off && $0.timer != nil }
    }

    // Helper method to create grid content based on current mode
    @ViewBuilder
    private func gridContent(columns: [GridItem], spacing: CGFloat, buttonSize: CGFloat) -> some View {
        if appMode == .browse || appMode == .selecting {
            // Browse mode: Show all waveforms
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(WaveformType.allCases, id: \.self) { waveformType in
                    WaveformButton(
                        waveform: waveformType,
                        isActive: currentWaveform == waveformType,
                        appMode: appMode,
                        arpState: .off,  // Browse mode doesn't use ARPs
                        buttonSize: buttonSize,
                        onPress: {
                            if appMode == .selecting {
                                // Complete the selection and switch to play mode
                                selectedWaveformForPitch = waveformType
                                appMode = .play
                                // Initialize ARP state for this waveform if it doesn't exist
                                if arpStates[waveformType] == nil {
                                    var newState = ArpState(waveform: waveformType)
                                    newState.bpm = currentBpm  // Use current global BPM
                                    arpStates[waveformType] = newState
                                }
                            } else {
                                audioEngine.play(waveform: waveformType)
                                currentWaveform = waveformType
                                // Set background to character color when playing
                                backgroundColor = Color(red: waveformType.color.0, green: waveformType.color.1, blue: waveformType.color.2)
                                faceColor = .white  // Always use white face in browse mode
                            }
                        },
                        onRelease: {
                            if appMode != .selecting {
                                audioEngine.stop()
                                currentWaveform = nil
                                backgroundColor = .black
                                faceColor = .white
                            }
                        }
                    )
                }
            }
        } else {
            // Play mode: Show pitch grid or scale/wave selection
            LazyVGrid(columns: columns, spacing: spacing) {
                playModeGridContent(buttonSize: buttonSize)
            }
        }
    }

    @ViewBuilder
    private func playModeGridContent(buttonSize: CGFloat) -> some View {
        if showingScaleSelection {
            // Show 16 scale options
            ForEach(ScaleType.allCases, id: \.self) { scale in
                ScaleButton(
                    scale: scale,
                    isActive: selectedScale == scale,
                    buttonSize: buttonSize,
                    onPress: {
                        selectedScale = scale
                        showingScaleSelection = false
                    }
                )
            }
        } else if showingWaveSelection {
            // Show first 16 waveforms
            ForEach(Array(WaveformType.allCases.prefix(16)), id: \.self) { waveform in
                WaveformButton(
                    waveform: waveform,
                    isActive: selectedWaveformForPitch == waveform,
                    appMode: appMode,
                    arpState: arpStates[waveform]?.mode ?? .off,
                    buttonSize: buttonSize,
                    onPress: {
                        selectedWaveformForPitch = waveform
                        showingWaveSelection = false

                        // Initialize ARP state for this waveform if it doesn't exist
                        if arpStates[waveform] == nil {
                            var newState = ArpState(waveform: waveform)
                            newState.bpm = currentBpm  // Use current global BPM
                            arpStates[waveform] = newState
                        }
                    },
                    onRelease: {}
                )
            }
        } else if showingBpmSelection {
            // Show BPM selection grid (20-170 in increments of 10)
            ForEach(0..<16, id: \.self) { index in
                let bpm = 20 + (index * 10)
                BpmButton(
                    bpm: bpm,
                    isActive: currentBpm == bpm,
                    buttonSize: buttonSize,
                    onPress: {
                        currentBpm = bpm
                        showingBpmSelection = false
                        // Update BPM for all ARPs and restart active ones
                        for waveform in arpStates.keys {
                            var state = arpStates[waveform]!
                            let wasActive = state.mode != .off && state.timer != nil
                            state.bpm = bpm

                            // Stop timer completely before restarting
                            if wasActive {
                                state.timer?.invalidate()
                                state.timer = nil
                                arpStates[waveform] = state
                                // Start timer with new BPM without resetting position
                                startArpTimer(for: waveform, state: &state)
                                arpStates[waveform] = state
                            } else {
                                arpStates[waveform] = state
                            }
                        }
                    }
                )
            }
        } else {
            // Show pitch grid - 4x4 (16 pads) for both iPhone and iPad
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            let totalPads = 16  // Both iPhone and iPad use 16 pads (4x4 grid)
            ForEach(0..<totalPads, id: \.self) { index in
                if let waveform = selectedWaveformForPitch {
                    PitchButton(
                        waveform: waveform,
                        noteIndex: index,
                        isActive: (activePitchNotes[waveform]?.contains(index) ?? false),
                        isDeactivated: currentArpState.wrappedValue.deactivatedSteps.contains(index),
                        buttonSize: buttonSize,
                        onPress: {
                            if currentArpState.wrappedValue.mode != .off {
                                // If ARP is active, toggle step activation
                                if currentArpState.wrappedValue.deactivatedSteps.contains(index) {
                                    currentArpState.wrappedValue.deactivatedSteps.remove(index)
                                } else {
                                    currentArpState.wrappedValue.deactivatedSteps.insert(index)
                                }
                            } else {
                                // Normal play mode when ARP is off - use root frequency
                                audioEngine.playScaleWithIntervals(note: index, waveform: waveform, intervals: selectedScale.intervals, octaveOffset: currentArpState.wrappedValue.octaveOffset, baseFrequency: rootFrequency)
                                currentWaveform = waveform
                                if activePitchNotes[waveform] == nil {
                                    activePitchNotes[waveform] = Set<Int>()
                                }
                                activePitchNotes[waveform]?.insert(index)
                            }
                        },
                        onRelease: {
                            if currentArpState.wrappedValue.mode == .off {
                                // Only stop manually played notes when ARP is off
                                audioEngine.stopNote(waveform: waveform, note: index)
                                activePitchNotes[waveform]?.remove(index)
                                if activePitchNotes[waveform]?.isEmpty == true {
                                    activePitchNotes[waveform] = nil
                                    currentWaveform = nil
                                }
                            }
                        }
                    )
                }
            }
        }

        // Control buttons
        controlButtons(buttonSize: buttonSize)
    }

    @ViewBuilder
    private func controlButtons(buttonSize: CGFloat) -> some View {
        // WAVE button (replaces back button) - custom styling
        WaveButton(
            label: "WAVE",
            buttonSize: buttonSize,
            onPress: {
                showingWaveSelection.toggle()
                showingScaleSelection = false  // Close scale selection if open
            },
            isActive: showingWaveSelection
        )

        // SCALE button (always shown)
        ModeButton(
            label: "SCALE",
            buttonSize: buttonSize,
            onPress: {
                showingScaleSelection.toggle()
                showingWaveSelection = false  // Close wave selection if open
            },
            isActive: showingScaleSelection
        )

        // BPM button - shows BPM selection grid
        ModeButton(
            label: "BPM",
            buttonSize: buttonSize,
            onPress: {
                showingBpmSelection.toggle()
                showingScaleSelection = false  // Close scale selection if open
                showingWaveSelection = false   // Close wave selection if open
            },
            isActive: showingBpmSelection
        )

        // ROOT button (moved before PLAY position)
        RootButton(
            currentNote: rootNotes[rootNoteIndex],
            buttonSize: buttonSize,
            onPress: {
                // Cycle through root notes
                rootNoteIndex = (rootNoteIndex + 1) % rootNotes.count
            }
        )

        // ARP button (renamed to PLAY/ARP based on state)
        ArpButton(
            arpMode: currentArpState.wrappedValue.mode,
            buttonSize: buttonSize,
            onPress: {
                if currentArpState.wrappedValue.mode == .off {
                    // Act as PLAY button - start global playing
                    isGloballyPlaying = true
                    // Start all ARPs that are in non-off mode
                    for (waveform, state) in arpStates where state.mode != .off {
                        startArpFromCurrentStep(for: waveform)
                    }
                }
                cycleArpMode()
            }
        )

        // STOP button (universal)
        ModeButton(
            label: "STOP",
            buttonSize: buttonSize,
            onPress: {
                isGloballyPlaying = false

                // Stop all ARPs and sounds aggressively
                for waveform in arpStates.keys {
                    var state = arpStates[waveform]!
                    // Stop timer immediately and forcefully
                    state.timer?.invalidate()
                    state.timer = nil
                    // Reset ARP state completely
                    state.mode = .off
                    state.currentStep = 0
                    state.direction = 1
                    arpStates[waveform] = state
                }

                // Stop all audio aggressively multiple times
                for waveform in WaveformType.allCases {
                    for i in 0..<16 {
                        audioEngine.stopNote(waveform: waveform, note: i)
                    }
                }
                audioEngine.stopAll()
                audioEngine.stopAll()
                audioEngine.stopAll()

                // Reset all visual state
                currentWaveform = nil
                activePitchNotes.removeAll()
                backgroundColor = .white
                faceColor = .black

                // Force immediate update
                DispatchQueue.main.async {
                    for waveform in arpStates.keys {
                        var state = arpStates[waveform]!
                        state.timer?.invalidate()
                        state.timer = nil
                        state.mode = .off
                        arpStates[waveform] = state
                    }
                }
            },
            isActive: false
        )

        // Down arrow button for octave down
        ModeButton(
            label: "↓",
            buttonSize: buttonSize,
            onPress: {
                // Decrease octave offset
                guard let waveform = selectedWaveformForPitch else { return }
                var state = currentArpState.wrappedValue
                state.octaveOffset = max(-2, state.octaveOffset - 1)
                currentArpState.wrappedValue = state
            },
            isActive: false
        )

        // Up arrow button for octave up
        ModeButton(
            label: "↑",
            buttonSize: buttonSize,
            onPress: {
                // Increase octave offset
                guard let waveform = selectedWaveformForPitch else { return }
                var state = currentArpState.wrappedValue
                state.octaveOffset = min(2, state.octaveOffset + 1)
                currentArpState.wrappedValue = state
            },
            isActive: false
        )
    }

    var body: some View {
        GeometryReader { geometry in
            // Use device-specific button sizes to ensure grid fits properly
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            let buttonSize: CGFloat = isIPad ? 120 : 70  // Much larger buttons for iPad to fill screen space
            let spacing: CGFloat = isIPad ? 8 : 4  // Increased spacing for iPad
            let columnCount = 4  // Both iPhone and iPad use 4x4 grid
            let columns = Array(repeating: GridItem(.fixed(buttonSize), spacing: spacing), count: columnCount)

            ZStack {
                // Background color
                backgroundColor
                    .ignoresSafeArea()

                // Centered crosshair for alignment verification
                Path { path in
                    // Vertical line
                    path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                    // Horizontal line
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Spacer at top to push character down from top edge
                    Spacer()
                        .frame(height: 40)

                    // Character at TOP - centered with same approach as grid
                    HStack(spacing: 0) {
                        Spacer()
                        CharacterView(currentWaveform: currentWaveform, audioEngine: audioEngine, appMode: appMode, faceColor: faceColor, isArpPlaying: isAnyArpPlaying, bpm: currentBpm)
                            .frame(height: 100)
                        Spacer()
                    }

                    // Add spacer to position grid at fixed vertical location
                    Spacer()
                        .frame(height: 40)

                    // Button grid BELOW - centered at fixed position
                    HStack(spacing: 0) {
                        Spacer()
                        gridContent(columns: columns, spacing: spacing, buttonSize: buttonSize)
                        Spacer()
                    }

                    // Bottom spacing
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }

    // Arpeggiator functions
    func cycleArpMode() {
        guard let waveform = selectedWaveformForPitch else { return }
        var state = currentArpState.wrappedValue

        // If currently running, aggressively stop everything
        if state.mode != .off {
            state.timer?.invalidate()
            state.timer = nil
            // Stop current note but don't reset position
            audioEngine.stopNote(waveform: waveform, note: state.currentStep)
            activePitchNotes[waveform]?.remove(state.currentStep)
            // Ensure timer is completely invalidated
            arpStates[waveform]?.timer?.invalidate()
            arpStates[waveform]?.timer = nil
        }

        // Cycle to next mode
        switch state.mode {
        case .off:
            state.mode = .forward
            currentArpState.wrappedValue = state
            startArp(for: waveform)
        case .forward:
            state.mode = .backward
            currentArpState.wrappedValue = state
            startArpFromCurrentStep(for: waveform)
        case .backward:
            state.mode = .pendulum
            currentArpState.wrappedValue = state
            startArpFromCurrentStep(for: waveform)
        case .pendulum:
            state.mode = .random
            currentArpState.wrappedValue = state
            startArpFromCurrentStep(for: waveform)
        case .random:
            state.mode = .off
            currentArpState.wrappedValue = state
            stopArp(for: waveform)
        }
    }

    func startArp(for waveform: WaveformType) {
        var state = arpStates[waveform] ?? ArpState(waveform: waveform)

        // First stop any existing notes for this waveform to prevent sustained notes
        if let activeNotes = activePitchNotes[waveform] {
            for note in activeNotes {
                audioEngine.stopNote(waveform: waveform, note: note)
            }
        }
        activePitchNotes[waveform] = Set<Int>()

        state.currentStep = state.mode == .backward ? 15 : 0
        state.direction = 1

        // Play first note immediately using crossfade system for consistency
        let octave = state.currentStep / selectedScale.intervals.count
        let noteInScale = state.currentStep % selectedScale.intervals.count
        let frequency = rootFrequency * selectedScale.intervals[noteInScale] * Float(pow(2.0, Double(octave + state.octaveOffset)))

        // Use crossfade (from no note to first note)
        audioEngine.crossfadeToNote(fromNote: -1, toNote: state.currentStep, waveform: waveform, frequency: frequency)
        currentWaveform = waveform
        activePitchNotes[waveform]?.insert(state.currentStep)

        // Start timer to play subsequent notes
        startArpTimer(for: waveform, state: &state)
        arpStates[waveform] = state
    }

    func startArpFromCurrentStep(for waveform: WaveformType) {
        var state = arpStates[waveform] ?? ArpState(waveform: waveform)

        // First stop any existing notes for this waveform to prevent sustained notes
        if let activeNotes = activePitchNotes[waveform] {
            for note in activeNotes {
                audioEngine.stopNote(waveform: waveform, note: note)
            }
        }
        activePitchNotes[waveform] = Set<Int>()

        // Don't reset currentStep - keep it at current position
        // Play current note immediately using crossfade system for consistency
        let octave = state.currentStep / selectedScale.intervals.count
        let noteInScale = state.currentStep % selectedScale.intervals.count
        let frequency = rootFrequency * selectedScale.intervals[noteInScale] * Float(pow(2.0, Double(octave + state.octaveOffset)))

        // Use crossfade (from no note to current step)
        audioEngine.crossfadeToNote(fromNote: -1, toNote: state.currentStep, waveform: waveform, frequency: frequency)
        currentWaveform = waveform
        activePitchNotes[waveform]?.insert(state.currentStep)

        // Start timer to play subsequent notes
        startArpTimer(for: waveform, state: &state)
        arpStates[waveform] = state
    }

    func startArpTimer(for waveform: WaveformType, state: inout ArpState) {
        // Always stop any existing timer first
        state.timer?.invalidate()
        state.timer = nil

        // Calculate interval from BPM (60 seconds / BPM / 4 for 16th notes)
        let interval = 60.0 / Double(state.bpm) / 4.0
        state.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [self] _ in
            guard var currentState = self.arpStates[waveform] else { return }

            let previousStep = currentState.currentStep

            // Find next active (non-deactivated) step
            var attempts = 0
            let maxAttempts = 16

            repeat {
                // Move to next step based on mode
                switch currentState.mode {
                case .forward:
                    currentState.currentStep = (currentState.currentStep + 1) % 16

                case .backward:
                    currentState.currentStep = currentState.currentStep - 1
                    if currentState.currentStep < 0 {
                        currentState.currentStep = 15
                    }

                case .pendulum:
                    currentState.currentStep += currentState.direction
                    if currentState.currentStep >= 15 {
                        currentState.currentStep = 15
                        currentState.direction = -1
                    } else if currentState.currentStep <= 0 {
                        currentState.currentStep = 0
                        currentState.direction = 1
                    }

                case .random:
                    currentState.currentStep = Int.random(in: 0..<16)

                case .off:
                    break
                }

                attempts += 1
            } while currentState.deactivatedSteps.contains(currentState.currentStep) && attempts < maxAttempts

            // Play next note using crossfade for smooth transition (only if step is active)
            if !currentState.deactivatedSteps.contains(currentState.currentStep) {
                // Calculate frequency for the new note
                let octave = currentState.currentStep / self.selectedScale.intervals.count
                let noteInScale = currentState.currentStep % self.selectedScale.intervals.count
                let frequency = self.rootFrequency * self.selectedScale.intervals[noteInScale] * Float(pow(2.0, Double(octave + currentState.octaveOffset)))

                // Use crossfade for smooth transition
                self.audioEngine.crossfadeToNote(fromNote: previousStep, toNote: currentState.currentStep, waveform: waveform, frequency: frequency)
                self.currentWaveform = waveform

                // Update visual tracking
                if self.activePitchNotes[waveform] == nil {
                    self.activePitchNotes[waveform] = Set<Int>()
                }
                self.activePitchNotes[waveform]?.remove(previousStep)
                self.activePitchNotes[waveform]?.insert(currentState.currentStep)
            }

            self.arpStates[waveform] = currentState
        }
    }

    func stopArp(for waveform: WaveformType) {
        guard var state = arpStates[waveform] else { return }

        state.timer?.invalidate()
        state.timer = nil

        // Stop current note
        audioEngine.stopNote(waveform: waveform, note: state.currentStep)
        activePitchNotes[waveform] = nil
        currentWaveform = nil
        state.currentStep = 0
        state.direction = 1

        arpStates[waveform] = state
    }
}

// EXACT copy of Rosita button style
struct WaveformButton: View {
    let waveform: WaveformType
    let isActive: Bool
    var appMode: AppMode = .browse
    let arpState: ArpMode  // Add ARP state to check if this waveform is playing
    let buttonSize: CGFloat
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var hasBeenPressed = false

    func getStrokeColor() -> Color {
        // White lines when button background is black, black lines when ARP is active on colored background
        if backgroundColor == .black {
            return .white  // Black background needs white waveform
        } else if arpState != .off {
            return .black
        } else {
            return .white
        }
    }

    @ViewBuilder
    func getWaveformShape() -> some View {
        let strokeColor = getStrokeColor()

        switch waveform {
        case .sine:
            SineWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .triangle:
            TriangleWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .saw, .superSaw:
            SawtoothWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .reverseSaw:
            ReverseSawWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .square:
            SquareWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .pulse, .pwm:
            PulseWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .step, .quantizedStair:
            StepWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .trapezoid:
            TrapezoidWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .noise, .noiseBurst, .chaos:
            SawtoothWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .fmModulated:
            SineWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .halfSine:
            HalfSineWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .parabola:
            ParabolaWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .organ:
            OrganWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .gaussian:
            GaussianWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .pinkNoise:
            TriangleWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .ringMod:
            RingModWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .exponential:
            ExponentialWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        case .waveshape:
            WaveshapeWaveShape()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: 60, height: 40)
        }
    }

    private var backgroundColor: Color {
        if isActive {
            return Color.black  // Only selected waveform has black background
        } else {
            // Always show colorful waveform background
            return Color(red: waveform.color.0, green: waveform.color.1, blue: waveform.color.2)
        }
    }

    private var borderColor: Color {
        if appMode == .selecting {
            // No visible border in selecting mode
            return Color.clear
        } else if isActive {
            return Color.white
        } else {
            return Color.gray
        }
    }

    private var bevelOpacity: Double {
        if appMode == .selecting {
            return 0.4  // Show bevel in selecting mode
        } else if isActive {
            return 0.4
        } else {
            return 0.0
        }
    }

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(backgroundColor)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    ZStack {
                        // 3D bevel effect (only when active in browse mode)
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(bevelOpacity))
                                .frame(height: 2)
                            Spacer()
                        }

                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(bevelOpacity))
                                .frame(width: 2)
                            Spacer()
                        }

                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(bevelOpacity * 1.5))
                                .frame(height: 2)
                        }

                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(bevelOpacity * 1.5))
                                .frame(width: 2)
                        }

                        // Border
                        Rectangle()
                            .stroke(borderColor, lineWidth: 2)
                    }
                )

            // Show waveform name when active, waveform shape otherwise
            if isActive && appMode == .browse {
                Text(waveform.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(4)
            } else {
                getWaveformShape()
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !hasBeenPressed {
                        hasBeenPressed = true
                        onPress()
                    }
                }
                .onEnded { _ in
                    hasBeenPressed = false
                    if appMode != .selecting {
                        onRelease()
                    }
                }
        )
    }
}

// Keyboard button for entering pitch mode
struct KeyboardButton: View {
    let onPress: () -> Void
    var appMode: AppMode = .browse

    var body: some View {
        ZStack {
            Rectangle()
                .fill(appMode == .selecting ? Color.black : Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 2)
                )

            // Keyboard icon using SF Symbol
            Image(systemName: "music.note.list")
                .font(.system(size: 30))
                .foregroundColor(appMode == .selecting ? .white : .black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// Pitch button for playing notes in a scale
struct PitchButton: View {
    let waveform: WaveformType
    let noteIndex: Int
    let isActive: Bool
    var isDeactivated: Bool = false
    let buttonSize: CGFloat
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var hasBeenPressed = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    isActive ? Color.white :
                    (isDeactivated ?
                        Color(red: waveform.color.0 * 0.3, green: waveform.color.1 * 0.3, blue: waveform.color.2 * 0.3) :
                        Color(red: waveform.color.0, green: waveform.color.1, blue: waveform.color.2)
                    )
                )
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    ZStack {
                        // 3D bevel effect
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(isActive ? 0.0 : 0.4))
                                .frame(height: 2)
                            Spacer()
                        }

                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(isActive ? 0.0 : 0.4))
                                .frame(width: 2)
                            Spacer()
                        }

                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(isActive ? 0.0 : 0.6))
                                .frame(height: 2)
                        }

                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .fill(Color.black.opacity(isActive ? 0.0 : 0.6))
                                .frame(width: 2)
                        }

                        Rectangle()
                            .stroke(isActive ? Color.black : Color.white, lineWidth: 2)
                    }
                )
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !hasBeenPressed {
                        hasBeenPressed = true
                        onPress()
                    }
                }
                .onEnded { _ in
                    hasBeenPressed = false
                    onRelease()
                }
        )
    }
}

// Back button for returning to browse mode
struct BackButton: View {
    let onPress: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 2)
                )

            // Back arrow icon
            Image(systemName: "arrow.left")
                .font(.system(size: 30))
                .foregroundColor(.black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// Wave button with custom styling (black when active)
struct WaveButton: View {
    let label: String
    let buttonSize: CGFloat
    let onPress: () -> Void
    var isActive: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isActive ? Color.black : Color.white)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? Color.white : Color.gray, lineWidth: 2)
                )

            // Label text
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isActive ? .white : .black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// Mode button for SCALE, ARP, PITCH controls
struct ModeButton: View {
    let label: String
    let buttonSize: CGFloat
    let onPress: () -> Void
    var isActive: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isActive ? Color.green : Color.white)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? Color.white : Color.gray, lineWidth: 2)
                )

            // Label text
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isActive ? .white : .black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// Empty placeholder button
struct EmptyButton: View {
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 80, height: 80)
            .overlay(
                Rectangle()
                    .stroke(Color.gray, lineWidth: 2)
            )
    }
}

// ARP button with mode icons
struct ArpButton: View {
    let arpMode: ArpMode
    let buttonSize: CGFloat
    let onPress: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(arpMode != .off ? Color.green : Color.white)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Rectangle()
                        .stroke(arpMode != .off ? Color.white : Color.gray, lineWidth: 2)
                )

            VStack(spacing: 2) {
                // Label text - shows PLAY when off, ARP when active
                Text(arpMode == .off ? "PLAY" : "ARP")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(arpMode != .off ? .white : .black)

                // Icon based on mode
                Group {
                    switch arpMode {
                    case .off:
                        EmptyView()
                    case .forward:
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    case .backward:
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    case .pendulum:
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    case .random:
                        DiceIcon()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// Dice icon shape - showing 6 dots
struct DiceIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)

        // Draw dice square
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: size, height: size), cornerSize: CGSize(width: 2, height: 2))

        // Draw dots in a dice pattern (showing 6)
        let dotRadius: CGFloat = size * 0.12
        let paddingX: CGFloat = size * 0.25
        let paddingY: CGFloat = size * 0.25

        // Left column (top, middle, bottom)
        path.addEllipse(in: CGRect(
            x: paddingX - dotRadius,
            y: paddingY - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        path.addEllipse(in: CGRect(
            x: paddingX - dotRadius,
            y: size/2 - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        path.addEllipse(in: CGRect(
            x: paddingX - dotRadius,
            y: size - paddingY - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        // Right column (top, middle, bottom)
        path.addEllipse(in: CGRect(
            x: size - paddingX - dotRadius,
            y: paddingY - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        path.addEllipse(in: CGRect(
            x: size - paddingX - dotRadius,
            y: size/2 - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        path.addEllipse(in: CGRect(
            x: size - paddingX - dotRadius,
            y: size - paddingY - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        return path
    }
}

// Scale button for selecting musical scales
struct ScaleButton: View {
    let scale: ScaleType
    let isActive: Bool
    let buttonSize: CGFloat
    let onPress: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? Color.white : Color.gray, lineWidth: isActive ? 4 : 2)
                )

            Text(scale.rawValue)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// BPM button for selecting tempo
struct BpmButton: View {
    let bpm: Int
    let isActive: Bool
    let buttonSize: CGFloat
    let onPress: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? Color.black : Color.gray, lineWidth: isActive ? 4 : 2)
                )

            Text("\(bpm)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// Arrow button for octave up/down (same style as BACK button)
struct ArrowButton: View {
    enum Direction {
        case up, down
    }

    let direction: Direction
    let onPress: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 2)
                )

            // Arrow icon
            Image(systemName: direction == .up ? "arrow.up" : "arrow.down")
                .font(.system(size: 30))
                .foregroundColor(.black)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

// ROOT button for selecting root note
struct RootButton: View {
    let currentNote: String
    let buttonSize: CGFloat
    let onPress: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 2)
                )

            VStack(spacing: 2) {
                // Label text
                Text("ROOT")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)

                // Current note
                Text(currentNote)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPress()
        }
    }
}

#Preview {
    ContentView()
}
