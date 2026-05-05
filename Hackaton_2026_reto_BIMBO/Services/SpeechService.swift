import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechService: ObservableObject {
    @Published var transcripcion: String = ""
    @Published var isListening: Bool     = false
    @Published var errorMsg: String?

    private var recognizer:  SFSpeechRecognizer?
    private var request:     SFSpeechAudioBufferRecognitionRequest?
    private var task:        SFSpeechRecognitionTask?
    private let audioEngine  = AVAudioEngine()

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    }

    func solicitarPermiso() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func iniciar() {
        guard !isListening else { return }
        transcripcion = ""
        errorMsg      = nil

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in self.transcripcion = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true { self.detener() }
        }

        let fmt = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        try? audioEngine.start()
        isListening = true
    }

    func detener() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        isListening = false
    }

    // Extrae pares producto-cantidad del texto dictado (NLP básico on-device)
    func parsearDictado(_ texto: String, catalogo: [Producto]) -> [String: Int] {
        var resultado: [String: Int] = [:]
        let lower = texto.lowercased()
        for producto in catalogo {
            let nombre = producto.nombre.lowercased().components(separatedBy: " ").first ?? ""
            if lower.contains(nombre) {
                let words = lower.components(separatedBy: " ")
                for (i, word) in words.enumerated() where word.contains(nombre) {
                    if i > 0, let num = Int(words[i - 1]) { resultado[producto.id] = num }
                    else if i < words.count - 1, let num = Int(words[i + 1]) { resultado[producto.id] = num }
                }
            }
        }
        return resultado
    }
}
