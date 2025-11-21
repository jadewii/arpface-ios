import SwiftUI

struct CharacterView: View {
    let currentWaveform: WaveformType?
    @ObservedObject var audioEngine: AudioEngine
    let appMode: AppMode
    let faceColor: Color
    let isArpPlaying: Bool  // New parameter to track if any ARP is active
    let bpm: Int  // BPM for mouth animation timing

    @State private var startTime: Date? = nil
    @State private var amplitude: CGFloat = 1.0
    @State private var wiggleOffset: CGFloat = 0
    @State private var isBlinking = false  // For blink animation on selecting mode
    @State private var talkPhase: CGFloat = 0  // For talking animation
    @State private var wobbleTime: Double = 0  // For Keylimba-style wobble
    let baseAmplitude: CGFloat = 1.0
    let baseFrequency: Float = 440.0

    var body: some View {
        // Wrap entire face in wobble animation
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let wobblePhase = CGFloat(now * 3.0)  // Wobble speed

            // Calculate wobble deformation - multiple sine waves for organic effect
            let wobbleX = sin(wobblePhase) * 0.03 + sin(wobblePhase * 2.3) * 0.02
            let wobbleY = cos(wobblePhase * 1.7) * 0.03 + cos(wobblePhase * 3.1) * 0.015
            let scaleX = 1.0 + wobbleX * (isArpPlaying ? 1.5 : 0.5)
            let scaleY = 1.0 + wobbleY * (isArpPlaying ? 1.5 : 0.5)

            VStack(spacing: 20) {
                // Eyes - open circles when in selecting mode or playing sound, closed lines otherwise - CENTERED
                HStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 60) {
                        // Blinking only happens in selecting mode
                        if isBlinking && appMode == .selecting {
                            // Blink - closed eyes
                            RoundedRectangle(cornerRadius: 2)
                                .fill(faceColor)
                                .frame(width: 40, height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(faceColor)
                                .frame(width: 40, height: 4)
                        } else if appMode == .selecting || audioEngine.isPlaying || isArpPlaying {
                            // Shocked/Happy eyes - open circles
                            Circle()
                                .fill(faceColor)
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill(faceColor)
                                .frame(width: 20, height: 20)
                        } else {
                            // Closed eyes - horizontal lines
                            RoundedRectangle(cornerRadius: 2)
                                .fill(faceColor)
                                .frame(width: 40, height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(faceColor)
                                .frame(width: 40, height: 4)
                        }
                    }
                    Spacer()
                }
                .frame(height: 20) // Fixed height to keep eyes in same position
                .offset(x: wiggleOffset * 0.5, y: wiggleOffset)

                // Mouth area with animated waveform - CENTERED
                HStack(spacing: 0) {
                    Spacer()
                    ZStack(alignment: .center) {
                        if appMode == .selecting {
                            // Shocked expression - open mouth (circle)
                            Circle()
                                .fill(faceColor)
                                .frame(width: 30, height: 30)
                        } else if isArpPlaying {
                            // Talking animation when ARP is playing - speed matches BPM
                            let talkingFrequency = Double(bpm) / 60.0 * 4.0  // BPM / 60 * 4 for 16th note feel
                            let talkingPhase = CGFloat(now * talkingFrequency)
                            let mouthHeight = 30 + abs(sin(talkingPhase)) * 30  // Oscillate between 30-60
                            Ellipse()
                                .fill(faceColor)
                                .frame(width: 40, height: mouthHeight)
                        } else if let waveform = currentWaveform, audioEngine.isPlaying {
                            if appMode == .play {
                                // In play mode: show oval mouth when singing
                                Ellipse()
                                    .fill(faceColor)
                                    .frame(width: 40, height: 60)
                            } else {
                                // In browse mode: show animated waveform
                                TimelineView(.animation) { timeline in
                                    let now = timeline.date
                                    let _ = startTime == nil ? (startTime = now) : ()
                                    let elapsed = startTime == nil ? 0.0 : now.timeIntervalSince(startTime!)
                                    let cyclesPerSecond = cycles(for: waveform)
                                    let phase = CGFloat((elapsed * cyclesPerSecond).truncatingRemainder(dividingBy: 1.0) * 2 * .pi)

                                    getAnimatedWaveform(for: waveform, phase: phase, amplitude: amplitude)
                                }
                            }
                        } else {
                            if appMode == .play {
                                // Happy smile when in play mode but not singing
                                SmilePath()
                                    .stroke(faceColor, lineWidth: 4)
                                    .frame(width: 100, height: 40)
                            } else {
                                // Default closed mouth - same size as waveform
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(faceColor.opacity(0.5))
                                    .frame(width: 100, height: 8)
                            }
                        }
                    }
                    .frame(width: 200, height: 80, alignment: .center) // Fixed size container with center alignment
                    .offset(x: wiggleOffset * 0.5, y: -wiggleOffset)
                    .gesture(dragGesture())
                    Spacer()
                }
                .onAppear {
                    startWiggleAnimation()
                }
                .onChange(of: appMode) { newValue in
                    if newValue == .selecting {
                        startBlinking()
                    } else {
                        isBlinking = false
                    }
                }
            .onChange(of: currentWaveform) { newValue in
                if newValue != nil && audioEngine.isPlaying {
                    startTime = Date()
                } else {
                    startTime = nil
                    amplitude = baseAmplitude
                }
            }
                .onChange(of: audioEngine.isPlaying) { newValue in
                    if !newValue {
                        startTime = nil
                        amplitude = baseAmplitude
                    } else if currentWaveform != nil && newValue {
                        startTime = Date()
                    }
                }
            }
            .padding()
            // Apply Keylimba-style wobble effect
            .scaleEffect(x: scaleX, y: scaleY)
            .rotation3DEffect(
                .degrees(wobbleX * 8),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(wobbleY * 8),
                axis: (x: 1, y: 0, z: 0)
            )
        }
    }

    func cycles(for waveform: WaveformType) -> Double {
        switch waveform {
        case .sine, .triangle, .square: return 1.5
        case .saw, .reverseSaw: return 1.5
        case .pulse: return 1.2
        case .superSaw: return 1.8
        default: return 1.5
        }
    }

    @ViewBuilder
    func getAnimatedWaveform(for waveform: WaveformType, phase: CGFloat, amplitude: CGFloat) -> some View {
        switch waveform {
        case .sine, .fmModulated:
            AnimatedSineWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .triangle:
            AnimatedTriangleWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .square:
            AnimatedSquareWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .saw, .superSaw:
            AnimatedSawtoothWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .reverseSaw:
            AnimatedReverseSawWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .pulse, .pwm:
            AnimatedPulseWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .noise, .noiseBurst, .chaos:
            AnimatedNoiseWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .step, .quantizedStair:
            AnimatedStepWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .trapezoid:
            AnimatedTrapezoidWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .halfSine:
            AnimatedHalfSineWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .parabola:
            AnimatedParabolaWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .gaussian:
            AnimatedGaussianWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .exponential:
            AnimatedExponentialWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .waveshape:
            AnimatedWaveshapeWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .organ:
            AnimatedOrganWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .ringMod:
            AnimatedRingModWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        case .pinkNoise:
            AnimatedPinkNoiseWave(phase: phase, amplitude: amplitude)
                .stroke(faceColor, lineWidth: 3)
                .frame(width: 200, height: 80)
        }
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let delta = -value.translation.height
                let scale = max(0.2, min(3.0, 1.0 + delta / 300.0))
                amplitude = baseAmplitude * CGFloat(scale)
                let newFreq = baseFrequency * Float(scale)
                audioEngine.updateFrequency(newFreq)
            }
            .onEnded { _ in
                amplitude = baseAmplitude
                audioEngine.updateFrequency(baseFrequency)
            }
    }

    private func startWiggleAnimation() {
        withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            wiggleOffset = 8
        }
    }

    private func startBlinking() {
        // Only blink in selecting mode
        func scheduleBlink() {
            guard appMode == .selecting else { return }
            let delay = Double.random(in: 2.0...5.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard self.appMode == .selecting else { return }
                // Quick blink animation
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.isBlinking = false
                    }
                    // Schedule next blink
                    scheduleBlink()
                }
            }
        }
        scheduleBlink()
    }
}

struct Eye: View {
    var body: some View {
        // Closed eye (horizontal line)
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .frame(width: 40, height: 4)
    }
}

struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Start from left side
        path.move(to: CGPoint(x: 0, y: height * 0.2))
        // Draw curve to right side with control point at bottom center
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.2),
            control: CGPoint(x: width / 2, y: height)
        )

        return path
    }
}
