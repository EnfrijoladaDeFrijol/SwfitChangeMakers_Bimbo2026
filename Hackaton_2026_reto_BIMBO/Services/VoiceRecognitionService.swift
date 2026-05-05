import Foundation
import Speech
import AVFoundation

// MARK: - VoiceRecognitionService
// On-device, privado, Spanish MX — sin envío de datos a servidores externos.
@MainActor
final class VoiceRecognitionService: ObservableObject {

    @Published var transcripcion:   String  = ""
    @Published var isGrabando:      Bool    = false
    @Published var errorMensaje:    String? = nil
    @Published var nivelAudio:      Float   = 0.0   // 0.0 – 1.0 para animación de onda

    private let recognizer   = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var request:       SFSpeechAudioBufferRecognitionRequest?
    private var task:          SFSpeechRecognitionTask?
    private let audioEngine    = AVAudioEngine()
    private var meterTimer:    Timer?

    // MARK: Permisos
    func solicitarPermisos() async -> Bool {
        let speech = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        let mic = await AVAudioApplication.requestRecordPermission()
        return speech == .authorized && mic
    }

    // MARK: Iniciar grabación
    func iniciarGrabacion() {
        guard !isGrabando, recognizer?.isAvailable == true else { return }
        transcripcion = ""
        errorMensaje  = nil

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMensaje = "Error de audio: \(error.localizedDescription)"
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults    = true
        request.requiresOnDeviceRecognition   = true   // privacidad on-device

        let inputNode = audioEngine.inputNode
        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result { self.transcripcion = result.bestTranscription.formattedString }
                if let error  { self.errorMensaje = error.localizedDescription }
                if error != nil || result?.isFinal == true { self.detenerGrabacion() }
            }
        }

        let formato = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: formato) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            // Calcula nivel de audio para animación
            buffer.frameLength > 0 ? self?.calcularNivel(buffer: buffer) : nil
        }

        do {
            try audioEngine.start()
            isGrabando = true
            iniciarMetro()
        } catch {
            errorMensaje = "No se pudo iniciar el motor de audio."
        }
    }

    // MARK: Detener grabación
    func detenerGrabacion() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        meterTimer?.invalidate()
        isGrabando   = false
        nivelAudio   = 0.0
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: Privado — nivel de audio
    private func calcularNivel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let rms = sqrt(
            (0..<frameLength).reduce(0.0) { $0 + Double(channelData[$1] * channelData[$1]) } / Double(frameLength)
        )
        Task { @MainActor in self.nivelAudio = Float(min(rms * 10, 1.0)) }
    }

    private func iniciarMetro() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isGrabando else { return }
                self.meterTimer?.invalidate()
            }
        }
    }
}
