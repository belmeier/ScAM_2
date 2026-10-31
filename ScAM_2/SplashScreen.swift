import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive {
                ContentView()
                    .transition(.opacity) // Smooth fade into main view
            } else {
                ZStack {
                    // 1. Matching background
                    Color.tealSurface
                        .ignoresSafeArea()
                    
                    // 2. Full-scale image matching the storyboard
                    Image("LoadingScreen")
                        .resizable()
                        .scaledToFit()
                        //.frame(maxWidth: .infinity, maxHeight: .infinity)
                        //    .ignoresSafeArea()
                    
                    // 3. Rotating spinner overlaid near the bottom
                    VStack {
                        Spacer()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.brandTeal))
                            .scaleEffect(1.4)
                            .padding(.bottom, 90) // Positioned nicely above the home bar
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onAppear {
            // Keep splash visible for 2.8 seconds (adjust to your preference)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        }
    }
}
