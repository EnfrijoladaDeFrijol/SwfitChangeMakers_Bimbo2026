import SwiftUI

// MARK: - VoiceRestockBottomSheet
// Pantalla de Restock por Voz — azul minimalista, contextual por tienda
struct VoiceRestockBottomSheet: View {

    let tiendaNombre: String
    let modoQuitar: Bool

    @EnvironmentObject var appState: AppState
    @StateObject private var vm: VoiceAssistantViewModel
    @State private var pulse     = false
    @State private var wavePhase: Double = 0
    @Environment(\.dismiss) private var dismiss

    init(tiendaNombre: String = "", modoQuitar: Bool = false) {
        self.tiendaNombre = tiendaNombre
        self.modoQuitar   = modoQuitar
        _vm = StateObject(wrappedValue: VoiceAssistantViewModel(
            tiendaNombre: tiendaNombre,
            modoQuitar: modoQuitar
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Fondo minimalista
                backgroundLayer

                ScrollView {
                    VStack(spacing: 0) {
                        // Header con contexto de tienda
                        bimboHeaderSection
                            .padding(.top, 24)

                        // Transcripción en tiempo real
                        if vm.isRecording || !vm.transcribedText.isEmpty {
                            transcripcionCard
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Lista de items detectados (HCAI override)
                        if !vm.items.isEmpty {
                            itemsSection
                                .padding(.top, 20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // Espacio para el FAB
                        Spacer().frame(height: 160)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.items.count)
                .animation(.spring(response: 0.4), value: vm.isRecording)

                // FAB + controles inferiores (siempre visibles)
                bottomControlsLayer
            }
            .navigationTitle(modoQuitar ? "Retirar Producto" : "Ingresar Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundStyle(Color.bimboBlue)
                }
                if !vm.items.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Limpiar") { vm.limpiarLista() }
                            .foregroundStyle(Color.bimboDangerRed)
                    }
                }
            }
            .task { await vm.solicitarPermisos() }
            .overlay {
                if vm.showSuccess { successOverlay }
            }
        }
    }

    // MARK: - Background (azul minimalista)
    private var backgroundLayer: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            // Burbuja decorativa azul arriba
            Circle()
                .fill(Color.bimboBlue.opacity(0.06))
                .frame(width: 300, height: 300)
                .offset(x: 120, y: -60)
                .blur(radius: 40)
            // Burbuja decorativa azul claro abajo
            Circle()
                .fill(Color.bimboSky.opacity(0.05))
                .frame(width: 260, height: 260)
                .offset(x: -100, y: 200)
                .blur(radius: 35)
        }
    }

    // MARK: - Header con contexto de tienda
    private var bimboHeaderSection: some View {
        VStack(spacing: 16) {
            // Ícono según modo
            ZStack {
                Circle()
                    .fill(LinearGradient.bimboHero)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.bimboBlue.opacity(0.35), radius: 14, y: 6)
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Nombre de tienda
            if !tiendaNombre.isEmpty {
                Text(tiendaNombre)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.bimboBlue)
            }

            // Mensaje de personalidad
            Text(vm.bimboMessage)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .contentTransition(.numericText())
                .animation(.spring(), value: vm.bimboMessage)

            // Indicador de estado
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.isRecording ? Color.bimboBlue : Color.bimboSuccessGreen)
                    .frame(width: 8, height: 8)
                    .scaleEffect(vm.isRecording ? (pulse ? 1.4 : 1.0) : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                               value: pulse)
                Text(vm.isRecording ? "Escuchando..." : (vm.permisosOK ? "Listo" : "Sin permiso"))
                    .font(.badgeLabel.bold())
                    .foregroundStyle(.secondary)
            }
            .onAppear { pulse = true }
        }
    }

    // MARK: - Transcripción card
    private var transcripcionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Transcripción", systemImage: "text.bubble.fill")
                .font(.badgeLabel.bold())
                .foregroundStyle(Color.bimboBlue)

            if vm.isRecording {
                // Onda de audio animada
                AudioWaveView(nivel: vm.voice.nivelAudio)
                    .frame(height: 40)
            }

            Text(vm.transcribedText.isEmpty ? "Di algo como: \"Agrega 5 Gansitos y 3 Donitas\"" :
                    vm.transcribedText)
                .font(.body)
                .foregroundStyle(vm.transcribedText.isEmpty ? Color.secondary : Color.primary)
                .italic(vm.transcribedText.isEmpty)
                .animation(.default, value: vm.transcribedText)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.bimboBlue.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Items section (HCAI Override)
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(vm.items.count) producto\(vm.items.count != 1 ? "s" : "")",
                      systemImage: "cart.fill")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.bimboNavy)
                Spacer()
                Text("Ajusta sin teclado")
                    .font(.badgeLabel)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            ForEach(vm.items) { item in
                RestockItemCard(item: item,
                                onMas:    { vm.incrementar(id: item.id) },
                                onMenos:  { vm.decrementar(id: item.id) },
                                onDelete: { vm.eliminar(id: item.id) })
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Bottom controls
    private var bottomControlsLayer: some View {
        VStack(spacing: 0) {
            // Degradado fade
            LinearGradient(
                colors: [Color.appBG.opacity(0), Color.appBG],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 40)

            VStack(spacing: 12) {
                // FAB micrófono
                MicFABButton(isRecording: vm.isRecording) {
                    vm.toggleGrabacion()
                }

                // Botón confirmar (solo cuando hay items)
                if !vm.items.isEmpty {
                    MassiveActionButton(
                        label: "Confirmar Pedido",
                        icon: "checkmark.seal.fill",
                        color: Color.bimboSuccessGreen
                    ) {
                        // Actualizar inventario del camión
                        appState.inventario.procesarRestock(items: vm.items, tiendaId: tiendaNombre)
                        vm.confirmarPedido()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(Color.appBG)
        }
    }

    // MARK: - Success overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { vm.showSuccess = false; dismiss() }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(Color.bimboSuccessGreen)
                    .symbolEffect(.bounce, value: vm.showSuccess)

                Text("¡Pedido Confirmado!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(vm.bimboMessage)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    vm.showSuccess = false
                    dismiss()
                } label: {
                    Text("Cerrar")
                        .font(.title3.bold())
                        .foregroundStyle(Color.bimboNavy)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient.bimboHero)
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.4), value: vm.showSuccess)
    }
}

// MARK: - MicFABButton (FAB animado azul)
private struct MicFABButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulsate = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Anillo pulsante cuando graba
                if isRecording {
                    Circle()
                        .stroke(Color.bimboBlue.opacity(0.3), lineWidth: 10)
                        .frame(width: 88, height: 88)
                        .scaleEffect(pulsate ? 1.35 : 1.0)
                        .opacity(pulsate ? 0 : 0.8)
                        .animation(.easeOut(duration: 0.9).repeatForever(autoreverses: false),
                                   value: pulsate)
                }

                // Botón principal
                Circle()
                    .fill(LinearGradient.bimboHero)
                    .overlay(isRecording ? Circle().fill(Color.bimboNavy) : nil)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: isRecording ? Color.bimboBlue.opacity(0.5) : Color.bimboNavy.opacity(0.3),
                        radius: 16, y: 6
                    )
                    .overlay(
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isRecording ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
        .onChange(of: isRecording) { _, recording in pulsate = recording }
        .onAppear { pulsate = isRecording }
        .accessibilityLabel(isRecording ? "Detener grabación" : "Iniciar grabación")
    }
}

// MARK: - RestockItemCard (HCAI: botones [-] [+] gigantes, con imagen)
private struct RestockItemCard: View {
    let item:     RestockItem
    let onMas:    () -> Void
    let onMenos:  () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Imagen del producto o ícono
                ProductThumbnail(imagenAsset: item.imagenAsset, esQuita: item.esQuita)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.nombre)
                        .font(.productName)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.esQuita ? "Retirar" : "Ingresar")
                        .font(.badgeLabel)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Botón eliminar item
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .font(.title3)
                }
                .minTapTarget()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Stepper HCAI — área táctil >= 56pt
            HStack(spacing: 20) {
                // Botón [ - ]
                Button(action: onMenos) {
                    Image(systemName: "minus")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(Color.bimboDangerRed)
                        .frame(width: 72, height: 56)
                        .background(Color.bimboDangerRed.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                // Cantidad — número grande y escaneable
                Text("\(item.cantidad)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(item.cantidad == 0 ? Color.secondary : Color.bimboNavy)
                    .frame(minWidth: 72)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.spring(response: 0.25), value: item.cantidad)

                // Botón [ + ]
                Button(action: onMas) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(Color.bimboSuccessGreen)
                        .frame(width: 72, height: 56)
                        .background(Color.bimboSuccessGreen.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - ProductThumbnail (imagen de producto o SF Symbol)
private struct ProductThumbnail: View {
    let imagenAsset: String
    let esQuita: Bool

    var body: some View {
        ZStack {
            if !imagenAsset.isEmpty {
                Image(imagenAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(esQuita ? Color.bimboDangerRed.opacity(0.12) : Color.bimboBlue.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: esQuita ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(esQuita ? Color.bimboDangerRed : Color.bimboBlue)
            }
        }
    }
}

// MARK: - AudioWaveView (onda de audio animada — azul)
private struct AudioWaveView: View {
    let nivel: Float
    @State private var animPhase: Double = 0

    var body: some View {
        GeometryReader { geo in
            let bars = 28
            let barWidth: CGFloat = geo.size.width / CGFloat(bars * 2)
            HStack(spacing: barWidth * 0.6) {
                ForEach(0..<bars, id: \.self) { i in
                    let offset = sin(Double(i) * 0.5 + animPhase) * 0.5 + 0.5
                    let height = CGFloat(nivel) * geo.size.height * CGFloat(offset) + 4
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.bimboBlue.opacity(0.7 + Double(nivel) * 0.3))
                        .frame(width: barWidth, height: height)
                        .animation(.easeInOut(duration: 0.1), value: nivel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animPhase = .pi * 2
            }
        }
    }
}

// MARK: - Preview
#Preview("Voice Restock — Ingresar") {
    VoiceRestockBottomSheet(tiendaNombre: "Abarrotes Don Cheto", modoQuitar: false)
}

#Preview("Voice Restock — Retirar") {
    VoiceRestockBottomSheet(tiendaNombre: "Abarrotes Don Cheto", modoQuitar: true)
}
