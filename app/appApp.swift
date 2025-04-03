import SwiftUI
import AVFoundation

class DSPAudioEngine: ObservableObject {
    let engine = AVAudioEngine()
    var sampleRate: Double = 44100.0
    var phase: Float = 0.0
    var phaseIncrement: Float = 1.0 / 44100.0 // 440Hz
    var sawPhase: Float = 0.0
    var sourceNode: AVAudioSourceNode?

    init() {
        setupAudio()
    }

    private func setupAudio() {
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = ablPointer[0].mData?.assumingMemoryBound(to: Float.self)

            guard let bufferPointer = buffer else {
                return noErr
            }

            for frame in 0..<Int(frameCount) {
                // サイン波生成
                let sineWave = sin(2.0 * .pi * self.phase)
                self.phase += self.phaseIncrement * 300
                if self.phase >= 1.0 { self.phase -= 1.0 }

                // ノコギリ波生成 (-1.0 ~ 1.0 の範囲)
                let sawWave = 2.0 * self.sawPhase - 1.0
                self.sawPhase += self.phaseIncrement * 800
                if self.sawPhase >= 1.0 { self.sawPhase -= 1.0 }

                // サイン波 + ノコギリ波の合成
                bufferPointer[frame] = 0.5 * sineWave + 0.5 * sawWave
            }
            return noErr
        }

        self.sourceNode = node
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: sampleRate,
                                   channels: 1,
                                   interleaved: false)

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }

    func start() {
        do {
            try engine.start()
            print("Audio Engine Started")
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    func stop() {
        engine.stop()
    }
}

struct ContentView: View {
    @StateObject private var audioEngine = DSPAudioEngine()
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 20) {
            Text("DSP Audio: Sine + Saw")
                .font(.headline)

            Button(action: {
                if isPlaying {
                    audioEngine.stop()
                } else {
                    audioEngine.start()
                }
                isPlaying.toggle()
            }) {
                Text(isPlaying ? "Stop" : "Play")
                    .font(.title)
                    .frame(width: 100, height: 50)
                    .background(isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

@main
struct DSPAudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
