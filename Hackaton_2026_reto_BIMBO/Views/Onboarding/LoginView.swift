import SwiftUI

// MARK: - LoginView (Pantalla de inicio de sesión del repartidor)
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var ruta: String = ""
    @State private var contrasena: String = ""
    @State private var showError = false
    @State private var isLoading = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var formOffset: CGFloat = 40
    @State private var formOpacity: Double = 0
    
    // Credenciales simuladas
    //private let rutaCorrecta = "R-SUR-08"
    private let rutaCorrecta = "AIDA"
    //private let passCorrecta = "bimbo2026"
    private let passCorrecta = "1"
    
    var body: some View {
        ZStack {
            // Fondo con gradiente azul sutil
            LinearGradient(
                colors: [Color.bimboIce, Color.appBG, Color.appBG],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Burbujas decorativas
            Circle()
                .fill(Color.bimboBlue.opacity(0.06))
                .frame(width: 300, height: 300)
                .offset(x: 130, y: -280)
                .blur(radius: 50)
            Circle()
                .fill(Color.bimboSky.opacity(0.05))
                .frame(width: 240, height: 240)
                .offset(x: -120, y: 300)
                .blur(radius: 40)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)
                    
                    // Logo Bimbo animado
                    VStack(spacing: 16) {
                        Image("bimbo_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 192)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        
                        Text("Copiloto de Ruta")
                            .font(.title2.bold())
                            .foregroundStyle(Color.bimboNavy)
                            .opacity(logoOpacity)
                    }
                    
                    // Formulario
                    VStack(spacing: 20) {
                        // Campo Ruta
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Ruta", systemImage: "map.fill")
                                .font(.badgeLabel.bold())
                                .foregroundStyle(Color.bimboBlue)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "road.lanes")
                                    .foregroundStyle(Color.bimboBlue)
                                    .frame(width: 24)
                                TextField("Ej: R-SUR-08", text: $ruta)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .font(.sectionTitle)
                            }
                            .padding(16)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.bimboBlue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Campo Contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Contraseña", systemImage: "lock.fill")
                                .font(.badgeLabel.bold())
                                .foregroundStyle(Color.bimboBlue)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(Color.bimboBlue)
                                    .frame(width: 24)
                                SecureField("Contraseña", text: $contrasena)
                                    .font(.sectionTitle)
                            }
                            .padding(16)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.bimboBlue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Error
                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text("Ruta o contraseña incorrecta")
                                    .font(.badgeLabel.bold())
                            }
                            .foregroundStyle(Color.bimboDangerRed)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Botón Iniciar
                        Button {
                            iniciarSesion()
                        } label: {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2.bold())
                                }
                                Text("Iniciar Jornada")
                                    .font(.title3.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient.bimboHero
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.bimboBlue.opacity(0.4), radius: 12, y: 6)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .padding(.top, 8)
                        
                        // Hint
                        VStack(spacing: 4) {
                            Text("Demo: Ruta \(rutaCorrecta) · Pass \(passCorrecta)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 28)
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    
                    Spacer().frame(height: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                formOffset = 0
                formOpacity = 1.0
            }
        }
    }
    
    private func iniciarSesion() {
        withAnimation(.spring()) { showError = false }
        
        guard !ruta.isEmpty, !contrasena.isEmpty else {
            withAnimation(.spring()) { showError = true }
            return
        }
        
        isLoading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Simular delay de red
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if ruta.uppercased() == rutaCorrecta && contrasena == passCorrecta {
                withAnimation(.spring(response: 0.5)) {
                    appState.isLoggedIn = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                withAnimation(.spring()) {
                    showError = true
                    isLoading = false
                }
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
