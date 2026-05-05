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
    
    // ──── TOGGLE: activa/desactiva el blur sobre la imagen de fondo ────
    // Cambia esto a `false` para ver la imagen sin blur
    private let enableBackgroundBlur = false
    // ───────────────────────────────────────────────────────────────────
    
    // Credenciales simuladas
    private let rutaCorrecta = "R-19"
    private let passCorrecta = "123"
    
    var body: some View {
        ZStack {
            // ─── Fondo: imagen personalizable ───
            // Coloca tu imagen como "login_bg" en Assets.xcassets
            // Tamaño recomendado: 1290 x 2796 px (iPhone 15 Pro Max @3x)
            // Formato: JPG o PNG, orientación vertical
            backgroundLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 50)
                    
                    // Logo Bimbo grande
                    Image("bimbo_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // Subtítulo
                    Text("Copiloto de Ruta")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.bimboNavy)
                        .opacity(logoOpacity)
                    
                    // ─── Formulario ───
                    VStack(spacing: 18) {
                        // Campo Ruta
                        loginField(
                            icon: "road.lanes",
                            placeholder: "Ruta (ej: R-SUR-08)",
                            text: $ruta,
                            isSecure: false
                        )
                        
                        // Campo Contraseña
                        loginField(
                            icon: "lock.fill",
                            placeholder: "Contraseña",
                            text: $contrasena,
                            isSecure: true
                        )
                        
                        // Error
                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Datos incorrectos")
                                    .font(.system(size: 14, weight: .bold))
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
                                        .font(.system(size: 24, weight: .bold))
                                }
                                Text("Iniciar Jornada")
                                    .font(.system(size: 20, weight: .black))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(LinearGradient.bimboHero)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color.bimboBlue.opacity(0.5), radius: 16, y: 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .padding(.top, 4)
                        
                        // Hint
                        Text("Demo: \(rutaCorrecta) / \(passCorrecta)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
                    .padding(.horizontal, 20)
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    
                    Spacer().frame(height: 40)
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
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Intenta cargar la imagen "login_bg" del Asset Catalog
            // Si no existe, usa el gradiente por defecto
            if UIImage(named: "login_bg") != nil {
                Image("login_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay {
                        if enableBackgroundBlur {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea()
                        } else {
                            // Sin blur: sólo un overlay oscuro sutil
                            Color.white.opacity(0.3).ignoresSafeArea()
                        }
                    }
            } else {
                // Fallback: gradiente azul sutil
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
            }
        }
    }
    
    // MARK: - Login Field
    private func loginField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.bimboBlue)
                .frame(width: 28)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 17, weight: .semibold))
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.bimboBlue.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Login Action
    private func iniciarSesion() {
        withAnimation(.spring()) { showError = false }
        
        guard !ruta.isEmpty, !contrasena.isEmpty else {
            withAnimation(.spring()) { showError = true }
            return
        }
        
        isLoading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
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
