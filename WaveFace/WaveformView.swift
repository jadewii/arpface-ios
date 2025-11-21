import SwiftUI

// EXACT copy from Rosita's RetroButton.swift
struct SineWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        let points = 100

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let y = midY - sin(angle) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct TriangleWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let normalized = (angle / .pi).truncatingRemainder(dividingBy: 2.0)
            let y = midY - (abs(normalized - 1.0) - 0.5) * 2.0 * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct SquareWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY - amplitude))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let y = midY - (sin(angle) >= 0 ? 1.0 : -1.0) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct SawtoothWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY + amplitude))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let normalized = angle / .pi
            let y = midY - (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct ReverseSawWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY - amplitude))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let normalized = angle / .pi
            let y = midY + (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct NoiseWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let points = 50

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let y = midY + CGFloat.random(in: -amplitude...amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct PulseWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let pulseWidth: CGFloat = 0.25

        // Start at top (normalized = 0 < 0.25, sample = 1.0)
        path.move(to: CGPoint(x: 0, y: midY - amplitude))

        let segmentWidth = width / cycles

        for i in 0..<Int(cycles) {
            let x = CGFloat(i) * segmentWidth
            let pulseX = x + segmentWidth * pulseWidth

            // Hold high
            path.addLine(to: CGPoint(x: pulseX, y: midY - amplitude))
            // Drop down
            path.addLine(to: CGPoint(x: pulseX, y: midY + amplitude))
            // Hold low
            path.addLine(to: CGPoint(x: x + segmentWidth, y: midY + amplitude))
            // Rise up (for next cycle)
            if i < Int(cycles) - 1 {
                path.addLine(to: CGPoint(x: x + segmentWidth, y: midY - amplitude))
            }
        }

        return path
    }
}

struct StepWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let steps = 8

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 0..<steps {
            let x = CGFloat(i) / CGFloat(steps) * width
            let nextX = CGFloat(i + 1) / CGFloat(steps) * width
            let y = midY - amplitude * sin(CGFloat(i) / CGFloat(steps) * 2 * .pi)

            path.addLine(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: nextX, y: y))
        }

        return path
    }
}

struct TrapezoidWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5

        // Start at midY (normalized = 0, sample = 0)
        path.move(to: CGPoint(x: 0, y: midY))

        let segmentWidth = width / cycles

        for i in 0..<Int(cycles) {
            let x = CGFloat(i) * segmentWidth

            // Rise to top
            path.addLine(to: CGPoint(x: x + segmentWidth * 0.2, y: midY - amplitude))
            // Hold high
            path.addLine(to: CGPoint(x: x + segmentWidth * 0.4, y: midY - amplitude))
            // Fall to bottom
            path.addLine(to: CGPoint(x: x + segmentWidth * 0.6, y: midY + amplitude))
            // Hold low
            path.addLine(to: CGPoint(x: x + segmentWidth, y: midY + amplitude))
            // Return to mid (for next cycle)
            if i < Int(cycles) - 1 {
                path.addLine(to: CGPoint(x: x + segmentWidth, y: midY))
            }
        }

        return path
    }
}

struct HalfSineWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 50

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let normalized = angle.truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi)
            let y = normalized < 0.5 ? midY - sin(angle) * amplitude : midY
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct ExponentialWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY + amplitude))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let t = CGFloat(i) / CGFloat(points)
            let y = midY + amplitude - (pow(2, t) - 1.0) / 1.0 * amplitude * 2
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct ParabolaWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY - amplitude))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let normalized = (angle / .pi).truncatingRemainder(dividingBy: 2.0)
            let xPos = normalized - 1.0  // Range -1 to 1
            let y = midY + (1.0 - xPos * xPos) * amplitude - amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct OrganWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            // Sum of harmonics
            var sum: CGFloat = 0.0
            sum += sin(angle) * 1.0
            sum += sin(angle * 2) * 0.5
            sum += sin(angle * 3) * 0.25
            let y = midY - sum * amplitude / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct GaussianWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY + amplitude))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let normalized = (angle / .pi).truncatingRemainder(dividingBy: 2.0)
            let xPos = (normalized - 1.0) * 3.0  // Range -3 to 3
            let y = midY - exp(-xPos * xPos) * amplitude + amplitude / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct PinkNoiseWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let points = 50

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            // Softer noise than white noise
            let y = midY + CGFloat.random(in: -amplitude...amplitude) * 0.7
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct RingModWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            // Ring modulation - multiply two waves
            let carrier = sin(angle)
            let modulator = sin(angle * 1.5)
            let y = midY - carrier * modulator * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

struct WaveshapeWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let amplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        path.move(to: CGPoint(x: 0, y: midY))

        for i in 1...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi
            let sine = sin(angle)
            // Soft clipping/distortion
            let shaped = tanh(sine * 3.0)
            let y = midY - shaped * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// Animated waveform shapes for character's mouth
struct AnimatedSineWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        // Start from i=0 to include x=0 point
        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let y = midY - sin(angle) * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedTriangleWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = (angle / .pi).truncatingRemainder(dividingBy: 2.0)
            let y = midY - (abs(normalized - 1.0) - 0.5) * 2.0 * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedSquareWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let y = midY - (sin(angle) >= 0 ? 1.0 : -1.0) * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedSawtoothWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = angle / .pi
            let y = midY - (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedNoiseWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    // Hash function to generate pseudo-random values
    func hash(_ value: CGFloat) -> CGFloat {
        let x = sin(value * 12.9898 + 78.233) * 43758.5453
        return x - floor(x)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let points = 50

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            // Generate jagged noise using hash function with phase for animation
            let seed = phase * 10.0 + CGFloat(i) * 2.5
            let random = hash(seed) * 2.0 - 1.0  // Range -1 to 1
            let y = midY + random * baseAmplitude * amplitude

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedPulseWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let pulseWidth: CGFloat = 0.25
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = (angle / (2 * .pi)).truncatingRemainder(dividingBy: 1.0)
            let y = midY - (normalized < pulseWidth ? 1.0 : -1.0) * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedStepWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let steps = 8
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let stepValue = floor(angle / (2 * .pi / CGFloat(steps)))
            let y = midY - sin(stepValue / CGFloat(steps) * 2 * .pi) * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedTrapezoidWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = (angle / (2 * .pi)).truncatingRemainder(dividingBy: 1.0)

            let y: CGFloat
            if normalized < 0.2 {
                // Rising edge
                y = midY + baseAmplitude * amplitude - (normalized / 0.2) * 2 * baseAmplitude * amplitude
            } else if normalized < 0.4 {
                // Hold high
                y = midY - baseAmplitude * amplitude
            } else if normalized < 0.6 {
                // Falling edge
                y = midY - baseAmplitude * amplitude + ((normalized - 0.4) / 0.2) * 2 * baseAmplitude * amplitude
            } else {
                // Hold low
                y = midY + baseAmplitude * amplitude
            }

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedParabolaWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = (angle / .pi).truncatingRemainder(dividingBy: 2.0)
            let xPos = normalized - 1.0  // Range -1 to 1
            let y = midY + (1.0 - xPos * xPos) * baseAmplitude * amplitude - baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedOrganWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            // Sum of harmonics
            var sum: CGFloat = 0.0
            sum += sin(angle) * 1.0
            sum += sin(angle * 2) * 0.5
            sum += sin(angle * 3) * 0.25
            let y = midY - sum * baseAmplitude * amplitude / 2
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedGaussianWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = (angle / .pi).truncatingRemainder(dividingBy: 2.0)
            let xPos = (normalized - 1.0) * 3.0  // Range -3 to 3
            let y = midY - exp(-xPos * xPos) * baseAmplitude * amplitude + baseAmplitude * amplitude / 2
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedPinkNoiseWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    // Hash function to generate pseudo-random values
    func hash(_ value: CGFloat) -> CGFloat {
        let x = sin(value * 12.9898 + 78.233) * 43758.5453
        return x - floor(x)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let points = 50

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            // Generate softer jagged noise using hash function with phase for animation
            let seed = phase * 10.0 + CGFloat(i) * 2.5
            let random = hash(seed) * 2.0 - 1.0  // Range -1 to 1
            let y = midY + random * baseAmplitude * amplitude * 0.7

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedRingModWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            // Ring modulation - multiply two waves
            let carrier = sin(angle)
            let modulator = sin(angle * 1.5)
            let y = midY - carrier * modulator * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedWaveshapeWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let sine = sin(angle)
            // Soft clipping/distortion
            let shaped = tanh(sine * 3.0)
            let y = midY - shaped * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedHalfSineWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let sineValue = sin(angle)
            let y = sineValue > 0 ? midY - sineValue * baseAmplitude * amplitude : midY
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedExponentialWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = (angle / (2 * .pi)).truncatingRemainder(dividingBy: 1.0)
            let y = midY + baseAmplitude * amplitude - (pow(2, normalized) - 1.0) / 1.0 * baseAmplitude * amplitude * 2
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct AnimatedReverseSawWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let baseAmplitude = height * 0.35
        let cycles = 2.5
        let points = 100

        for i in 0...points {
            let x = CGFloat(i) / CGFloat(points) * width
            let angle = (CGFloat(i) / CGFloat(points)) * cycles * 2 * .pi + phase
            let normalized = angle / .pi
            // Reverse direction by using 1.0 - ... instead of ... - 1.0
            let y = midY + (normalized.truncatingRemainder(dividingBy: 2.0) - 1.0) * baseAmplitude * amplitude
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}
