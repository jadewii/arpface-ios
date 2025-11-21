import AVFoundation
import Foundation

enum WaveformType: String, CaseIterable {
    case sine = "SINE"
    case triangle = "TRIANGLE"
    case saw = "SAW"
    case reverseSaw = "REVERSE SAW"
    case square = "SQUARE"
    case pulse = "PULSE"
    case step = "STEP"
    case noise = "NOISE"
    case trapezoid = "TRAPEZOID"
    case superSaw = "SUPER SAW"
    case fmModulated = "FM MODULATED"
    case pwm = "PWM"
    case quantizedStair = "QUANTIZED STAIR"
    case chaos = "CHAOS"
    case noiseBurst = "NOISE BURST"
    case halfSine = "HALF SINE"
    case parabola = "PARABOLA"
    case organ = "ORGAN"
    case gaussian = "GAUSSIAN"
    case pinkNoise = "PINK NOISE"
    case ringMod = "RING MOD"
    case exponential = "EXPONENTIAL"
    case waveshape = "WAVESHAPE"

    var color: (Double, Double, Double) {
        // Unique color for each waveform
        switch self {
        case .sine: return (0.3, 0.5, 1.0)
        case .triangle: return (1.0, 0.2, 0.4)
        case .saw: return (1.0, 0.6, 0.0)
        case .reverseSaw: return (0.2, 0.9, 0.5)
        case .square: return (1.0, 0.5, 0.1)
        case .pulse: return (1.0, 0.3, 0.3)
        case .step: return (0.6, 0.3, 1.0)
        case .noise: return (0.5, 1.0, 0.0)
        case .trapezoid: return (1.0, 0.4, 0.7)
        case .superSaw: return (0.5, 0.5, 1.0)
        case .fmModulated: return (1.0, 0.3, 0.6)
        case .pwm: return (1.0, 0.6, 0.3)
        case .quantizedStair: return (1.0, 0.7, 0.2)
        case .chaos: return (0.6, 0.6, 1.0)
        case .noiseBurst: return (1.0, 0.4, 0.8)
        case .halfSine: return (0.4, 0.7, 1.0)
        case .parabola: return (1.0, 0.5, 0.9)
        case .organ: return (0.9, 0.3, 0.4)
        case .gaussian: return (0.3, 1.0, 0.7)
        case .pinkNoise: return (1.0, 0.6, 0.8)
        case .ringMod: return (0.7, 0.4, 1.0)
        case .exponential: return (1.0, 0.8, 0.3)
        case .waveshape: return (0.5, 0.8, 1.0)
        }
    }
}

class AudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine
    private var playerNodes: [AVAudioPlayerNode] = []
    private let maxPolyphony = 16  // Support up to 16 simultaneous notes
    private var activeNodes: [String: AVAudioPlayerNode] = [:]  // Track which node is playing which waveform+note
    private(set) var currentWaveform: WaveformType?
    private(set) var currentFrequency: Float = 440.0

    @Published var isPlaying = false

    private func noteKey(waveform: WaveformType, note: Int) -> String {
        return "\(waveform.rawValue)_\(note)"
    }

    init() {
        audioEngine = AVAudioEngine()

        // Create a pool of player nodes for polyphony
        for _ in 0..<maxPolyphony {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
            playerNodes.append(playerNode)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func updateFrequency(_ frequency: Float) {
        guard let waveform = currentWaveform else { return }
        currentFrequency = frequency
        // Re-play with new frequency
        play(waveform: waveform, frequency: frequency)
    }

    func play(waveform: WaveformType, frequency: Float = 440.0) {
        stopAll()

        currentWaveform = waveform
        currentFrequency = frequency
        isPlaying = true

        // Use first available node
        guard let playerNode = getAvailablePlayerNode() else { return }

        let buffer = createBuffer(waveform: waveform, frequency: frequency)
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()
    }

    func playNote(waveform: WaveformType, note: Int, frequency: Float) {
        currentWaveform = waveform
        currentFrequency = frequency
        isPlaying = true

        let key = noteKey(waveform: waveform, note: note)

        // Stop previous note if playing
        if let existingNode = activeNodes[key] {
            existingNode.stop()
        }

        // Find available player node
        guard let playerNode = getAvailablePlayerNode() else { return }

        let buffer = createBuffer(waveform: waveform, frequency: frequency)
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()

        activeNodes[key] = playerNode
    }

    func stopNote(waveform: WaveformType, note: Int) {
        let key = noteKey(waveform: waveform, note: note)
        if let playerNode = activeNodes[key] {
            // Stop immediately to prevent overlap
            playerNode.stop()
            activeNodes.removeValue(forKey: key)
        }
        isPlaying = !activeNodes.isEmpty
    }

    func crossfadeToNote(fromNote: Int, toNote: Int, waveform: WaveformType, frequency: Float) {
        // Stop old note if it exists (fromNote -1 means no previous note)
        if fromNote >= 0 {
            let fromKey = noteKey(waveform: waveform, note: fromNote)
            if let oldPlayerNode = activeNodes[fromKey] {
                // Just stop immediately - we'll rely on the buffer design to prevent pops
                oldPlayerNode.stop()
                activeNodes.removeValue(forKey: fromKey)
            }
        }

        // Start new note immediately
        guard let newPlayerNode = getAvailablePlayerNode() else { return }
        let buffer = createBuffer(waveform: waveform, frequency: frequency)
        newPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        newPlayerNode.play()

        let toKey = noteKey(waveform: waveform, note: toNote)
        activeNodes[toKey] = newPlayerNode
        isPlaying = true
    }

    private func getAvailablePlayerNode() -> AVAudioPlayerNode? {
        // Find a node that's not currently playing
        for node in playerNodes {
            if !node.isPlaying {
                return node
            }
        }
        // If all are playing, reuse the first one
        return playerNodes.first
    }

    private func createBuffer(waveform: WaveformType, frequency: Float) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0

        // Calculate duration to contain whole number of cycles to avoid loop clicks
        let cyclesPerSecond = Double(frequency)
        let cyclesToInclude = max(1, round(cyclesPerSecond * 0.1)) // At least 1 cycle, aim for ~0.1s worth
        let duration = cyclesToInclude / cyclesPerSecond
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        // Use stereo format (2 channels) to match most device outputs
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]

        let angularFrequency = Float(2.0 * .pi) * frequency / Float(sampleRate)

        for frame in 0..<Int(frameCount) {
            let phase = angularFrequency * Float(frame)
            let sample: Float

            switch waveform {
            case .sine:
                sample = sin(phase) * 0.3

            case .triangle:
                let normalized = (phase / Float.pi).truncatingRemainder(dividingBy: 2.0)
                sample = (abs(normalized - 1.0) - 0.5) * 2.0 * 0.3

            case .saw:
                let normalized = phase / Float.pi
                sample = (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * 0.3

            case .reverseSaw:
                let normalized = phase / Float.pi
                sample = (1.0 - normalized.truncatingRemainder(dividingBy: 2.0)) * 0.3

            case .square:
                sample = (sin(phase) >= 0 ? 1.0 : -1.0) * 0.3

            case .pulse:
                let pulseWidth = 0.25
                let normalized = (phase / (Float.pi * 2)).truncatingRemainder(dividingBy: 1.0)
                sample = (normalized < Float(pulseWidth) ? 1.0 : -1.0) * 0.3

            case .step:
                let steps: Float = 8.0
                let normalized = (phase / (Float.pi * 2)).truncatingRemainder(dividingBy: 1.0)
                sample = (floor(normalized * steps) / steps - 0.5) * 2.0 * 0.3

            case .noise:
                // Replace with sawtooth wave
                let normalized = phase / Float.pi
                sample = (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * 0.3

            case .trapezoid:
                let normalized = (phase / (Float.pi * 2)).truncatingRemainder(dividingBy: 1.0)
                if normalized < 0.2 {
                    sample = (normalized / 0.2) * 0.3
                } else if normalized < 0.4 {
                    sample = 0.3
                } else if normalized < 0.6 {
                    sample = (1.0 - (normalized - 0.4) / 0.2) * 0.3
                } else {
                    sample = -0.3
                }

            case .superSaw:
                var superSample: Float = 0.0
                for detune in stride(from: Float(-0.02), through: Float(0.02), by: Float(0.01)) {
                    let detunePhase = phase * (Float(1.0) + detune)
                    let normalized = detunePhase / Float.pi
                    superSample += normalized.truncatingRemainder(dividingBy: 2.0) - 1.0
                }
                sample = superSample * Float(0.06)

            case .fmModulated:
                let modulator = sin(phase * 3)
                sample = sin(phase + modulator * 2) * 0.3

            case .pwm:
                let pulseWidth = (sin(phase * 0.1) + 1.0) / 2.0
                let normalized = (phase / (Float.pi * 2)).truncatingRemainder(dividingBy: 1.0)
                sample = (normalized < Float(pulseWidth) ? 1.0 : -1.0) * 0.3

            case .quantizedStair:
                let steps: Float = 16.0
                let normalized = (sin(phase) + 1.0) / 2.0
                sample = (floor(normalized * steps) / steps - 0.5) * 2.0 * 0.3

            case .chaos:
                // Simplified chaotic oscillator
                let x = sin(phase)
                let y = cos(phase * 1.3)
                sample = (x + y) * 0.15

            case .noiseBurst:
                // Replace with pulsed triangle wave
                let burstFreq = 5.0
                let burstLength = Int(sampleRate / 10)
                if (frame % Int(sampleRate / burstFreq)) < burstLength {
                    let normalized = (phase / Float.pi).truncatingRemainder(dividingBy: 2.0)
                    sample = (abs(normalized - 1.0) - 0.5) * 2.0 * 0.3
                } else {
                    sample = 0.0
                }

            case .halfSine:
                // Half wave rectified sine - only positive half
                let sineValue = sin(phase)
                sample = max(0, sineValue) * 0.3

            case .parabola:
                // Parabolic wave
                let normalized = (phase / Float.pi).truncatingRemainder(dividingBy: 2.0)
                let x = normalized - 1.0  // Range -1 to 1
                sample = (1.0 - x * x) * 0.3 - 0.3

            case .organ:
                // Additive synthesis with multiple harmonics
                var organSample: Float = 0.0
                let harmonics: [(Float, Float)] = [(1.0, 1.0), (2.0, 0.5), (3.0, 0.25), (4.0, 0.125)]
                for (harmonic, amplitude) in harmonics {
                    organSample += sin(phase * harmonic) * amplitude
                }
                sample = organSample * 0.15

            case .gaussian:
                // Gaussian/bell curve wave
                let normalized = (phase / Float.pi).truncatingRemainder(dividingBy: 2.0)
                let x = (normalized - 1.0) * 3.0  // Range -3 to 3
                sample = exp(-x * x) * 0.3 - 0.15

            case .pinkNoise:
                // Replace with complex harmonic wave (like filtered saw)
                var harmonicSample: Float = 0.0
                let harmonics: [(Float, Float)] = [(1.0, 1.0), (2.0, 0.5), (3.0, 0.25), (5.0, 0.2)]
                for (harmonic, amplitude) in harmonics {
                    let normalized = (phase * harmonic) / Float.pi
                    harmonicSample += (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * amplitude
                }
                sample = harmonicSample * 0.15

            case .ringMod:
                // Ring modulation - two sine waves multiplied
                let carrier = sin(phase)
                let modulator = sin(phase * 1.5)
                sample = carrier * modulator * 0.3

            case .exponential:
                // Exponential wave
                let normalized = (phase / (Float.pi * 2)).truncatingRemainder(dividingBy: 1.0)
                sample = (exp(normalized) - 1.0) / (exp(1.0) - 1.0) * 0.6 - 0.3

            case .waveshape:
                // Waveshaping/distortion - sine wave through nonlinear function
                let sine = sin(phase)
                let shaped = tanh(sine * 3.0)  // Soft clipping
                sample = shaped * 0.3
            }

            // Write same sample to both left and right channels (mono source, stereo output)
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }

        return buffer
    }

    func playScale(note: Int, waveform: WaveformType, isMajor: Bool = true) {
        // C major scale starting at C4 (261.63 Hz)
        let baseFrequency: Float = 261.63
        let majorScale: [Float] = [1.0, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2.0]
        let minorScale: [Float] = [1.0, 9/8, 6/5, 4/3, 3/2, 8/5, 9/5, 2.0]

        let scale = isMajor ? majorScale : minorScale

        // Support notes beyond one octave
        let octave = note / scale.count
        let noteInScale = note % scale.count
        let frequency = baseFrequency * scale[noteInScale] * Float(pow(2.0, Double(octave)))

        playNote(waveform: waveform, note: note, frequency: frequency)
    }

    func playScaleWithIntervals(note: Int, waveform: WaveformType, intervals: [Float], octaveOffset: Int = 0, baseFrequency: Float = 261.63) {
        // Base frequency defaults to C4 (261.63 Hz) but can be overridden with root note

        // Support notes beyond one octave
        let octave = note / intervals.count
        let noteInScale = note % intervals.count
        let frequency = baseFrequency * intervals[noteInScale] * Float(pow(2.0, Double(octave + octaveOffset)))

        playNote(waveform: waveform, note: note, frequency: frequency)
    }

    func stop() {
        stopAll()
    }

    func stopAll() {
        for node in playerNodes {
            if node.isPlaying {
                node.stop()
            }
        }
        activeNodes.removeAll()
        isPlaying = false
        currentWaveform = nil
    }
}
