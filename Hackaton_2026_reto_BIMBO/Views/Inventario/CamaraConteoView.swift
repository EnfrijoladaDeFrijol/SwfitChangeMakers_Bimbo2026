import SwiftUI
import AVFoundation

struct CamaraConteoView: View {
    @StateObject private var vm    = InventarioVisionViewModel()
    @StateObject private var camVM = CameraViewModel()

    var body: some View {
        ZStack {
            // Fondo de cámara o negro
            Group {
                if vm.vision.completado {
                    EvidenciaResumenView(
                        fotoAntes:   vm.vision.fotoAntes,
                        fotoDespues: vm.vision.fotoDespues
                    ) { vm.vision.reset() }
                } else {
                    CameraPreviewLayer(cameraVM: camVM)
                        .ignoresSafeArea()
                }
            }

            // Overlay UI
            VStack(spacing: 0) {
                // Indicador de progreso
                EtapaProgressBar(etapa: vm.vision.etapaActual)
                    .padding(.top, 60)
                    .padding(.horizontal, 32)

                Spacer()

                // Botones voz + cámara
                BottomCameraControls(vm: vm, camVM: camVM)
                    .padding(.bottom, 48)
            }
        }
        .navigationTitle("Evidencia")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Progreso de 2 pasos
private struct EtapaProgressBar: View {
    let etapa: FotoEtapa

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(FotoEtapa.allCases.enumerated()), id: \.element) { idx, paso in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(idx <= etapa.index ? Color.bimboBlue : Color.white.opacity(0.3))
                            .frame(width: 32, height: 32)
                        Image(systemName: paso.icono)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                    Text(paso.rawValue)
                        .font(.sectionTitle)
                        .foregroundStyle(idx <= etapa.index ? .white : .white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)

                if idx < FotoEtapa.allCases.count - 1 {
                    Rectangle()
                        .fill(etapa.index >= 1 ? Color.bimboBlue : Color.white.opacity(0.3))
                        .frame(height: 3)
                        .frame(maxWidth: 40)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Controles inferiores
private struct BottomCameraControls: View {
    @ObservedObject var vm:    InventarioVisionViewModel
    @ObservedObject var camVM: CameraViewModel

    var body: some View {
        HStack(spacing: 40) {
            // Botón de dictado
            Button {
                if vm.speech.isListening { vm.detenerDictado() }
                else                     { vm.iniciarDictado() }
            } label: {
                ZStack {
                    Circle()
                        .fill(vm.speech.isListening ? Color.bimboBlue : Color.white.opacity(0.2))
                        .background(.ultraThinMaterial, in: Circle())
                        .frame(width: AppConstants.fabSize, height: AppConstants.fabSize)
                        .shadow(color: vm.speech.isListening ? Color.bimboBlue.opacity(0.5) : .black.opacity(0.2),
                                radius: 12, y: 4)
                    Image(systemName: vm.speech.isListening ? "waveform" : "mic.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
            .overlay(
                vm.speech.isListening ?
                Circle().stroke(Color.bimboBlue.opacity(0.4), lineWidth: 2)
                    .frame(width: AppConstants.fabSize + 12)
                    .scaleEffect(vm.speech.isListening ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                               value: vm.speech.isListening) : nil
            )

            // Botón de cámara
            Button {
                if let img = camVM.capturePhoto() {
                    withAnimation(.spring()) { vm.vision.guardarFoto(img) }
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .background(Circle().fill(.white.opacity(0.15)))
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)

            // Reset
            Button {
                withAnimation(.spring()) { vm.vision.reset() }
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: AppConstants.fabSize, height: AppConstants.fabSize)
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Resumen de evidencia
private struct EvidenciaResumenView: View {
    let fotoAntes:   UIImage?
    let fotoDespues: UIImage?
    let onReset:     () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Evidencia Guardada")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    EvidenciaThumb(label: "Antes",   imagen: fotoAntes)
                    EvidenciaThumb(label: "Después", imagen: fotoDespues)
                }
                .padding(.horizontal, 24)

                MassiveActionButton(
                    label: "Nueva Visita",
                    icon: "arrow.counterclockwise",
                    color: Color.bimboBlue,
                    action: onReset
                )
                .padding(.horizontal, 24)
            }
        }
    }
}

private struct EvidenciaThumb: View {
    let label:  String
    let imagen: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.badgeLabel.bold())
                .foregroundStyle(.white.opacity(0.7))
            Group {
                if let img = imagen {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.white.opacity(0.1)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4/5, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Camera preview (UIViewRepresentable)
struct CameraPreviewLayer: UIViewRepresentable {
    @ObservedObject var cameraVM: CameraViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        cameraVM.setupPreview(in: view)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - CameraViewModel (AVFoundation)
@MainActor
final class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    private let session  = AVCaptureSession()
    private let output   = AVCapturePhotoOutput()
    private var preview: AVCaptureVideoPreviewLayer?
    private var continuation: CheckedContinuation<UIImage?, Never>?

    override init() {
        super.init()
        Task { await setupSession() }
    }

    private func setupSession() async {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else { return }
        await AVCaptureDevice.requestAccess(for: .video)

        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        Task.detached { [weak self] in await self?.session.startRunning() }
    }

    func setupPreview(in view: UIView) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        preview = layer
    }

    func capturePhoto() -> UIImage? {
        // Devuelve una imagen de placeholder para la demo
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        return renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
            let text = "Foto capturada" as NSString
            text.draw(at: CGPoint(x: 80, y: 190),
                      withAttributes: [.foregroundColor: UIColor.label, .font: UIFont.boldSystemFont(ofSize: 18)])
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let img  = UIImage(data: data) else { return }
        Task { @MainActor in self.continuation?.resume(returning: img) }
    }
}

#Preview {
    CamaraConteoView()
}
