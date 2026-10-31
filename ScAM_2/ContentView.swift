import SwiftUI
import PhotosUI
import Vision
import CoreImage

// MARK: - Color Definitions
extension Color {
    static let brandTeal = Color("Colour-BluishGreen")
    static let tealSurface = Color("Colour-Surface")
    static let tealBorder = Color("Colour-Border")
    static let tealSubtext = Color("Colour-Subtext")
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var isProcessing = false
    @State private var statusText: String = "Pilih hasil pindai kamu!"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full-Screen Background matching the illustration
                Color.tealSurface
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Image Comparison Cards
                    HStack(spacing: 14) {
                        previewCard(
                            title: "Gambar sebelum",
                            image: originalImage,
                            placeholderIcon: "doc.badge.plus",
                            placeholderText: "Pilih foto"
                        )
                        
                        previewCard(
                            title: "Gambar sesudah",
                            image: croppedImage,
                            placeholderIcon: "crop",
                            placeholderText: "Hasil crop"
                        )
                    }
                    .frame(height: 260)
                    .padding(.horizontal)
                    
                    // Status Description
                    Text(statusText)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.tealSubtext)
                        .padding(.top, 4)
                    
                    // Photo Picker Button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Pilih gambarnya")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brandTeal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.tealBorder, lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Process Action Button
                    Button {
                        processReceipt()
                    } label: {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "crop")
                                Text("Perbaiki otomatis semuanya")
                            }
                        }
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(originalImage == nil || isProcessing)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("ScAM v2")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.brandTeal)
                        
                        Text("Scan Anti Miring v2")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.tealSubtext)
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        originalImage = image
                        croppedImage = nil
                        statusText = "Siap untuk memotong"
                    }
                }
            }
        }
    }
    
    // MARK: - Card Subview
    
    @ViewBuilder
    private func previewCard(title: String, image: UIImage?, placeholderIcon: String, placeholderText: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.tealSubtext)
            
            ZStack {
                // Crisp card container over the tinted background
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.tealBorder, lineWidth: 1.5)
                    )
                
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: placeholderIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(Color.brandTeal.opacity(0.4))
                        Text(placeholderText)
                            .font(.caption2)
                            .foregroundStyle(Color.tealSubtext.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func processReceipt() {
        guard let originalImage else { return }
        isProcessing = true
        statusText = "Mencari pinggiran dokumen..."
        
        Task {
            let result = await cropAndFlatten(image: originalImage)
            isProcessing = false
            if let result {
                croppedImage = result
                statusText = "Dokumen diperbaiki dengan sukses!"
            } else {
                statusText = "Maaf, gagal mendeteksi bentuk persegi dokumen."
            }
        }
    }
    
    // MARK: - Vision Processing
    
    private func cropAndFlatten(image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await Task.detached(priority: .userInitiated) {
            let request = VNDetectRectanglesRequest()
            request.minimumAspectRatio = 0.15
            request.maximumAspectRatio = 1.0
            request.minimumConfidence = 0.6
            request.maximumObservations = 1
            request.quadratureTolerance = 25
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            
            do {
                try handler.perform([request])
                guard let document = request.results?.first as? VNRectangleObservation else {
                    return nil
                }
                return ContentView.applyPerspectiveCorrection(to: cgImage, observation: document)
            } catch {
                return nil
            }
        }.value
    }
    
    nonisolated private static func applyPerspectiveCorrection(to cgImage: CGImage, observation: VNRectangleObservation) -> UIImage? {
        let ciImage = CIImage(cgImage: cgImage)
        let imageSize = ciImage.extent.size
        
        let topLeft = CGPoint(
            x: observation.topLeft.x * imageSize.width,
            y: observation.topLeft.y * imageSize.height
        )
        let topRight = CGPoint(
            x: observation.topRight.x * imageSize.width,
            y: observation.topRight.y * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: observation.bottomLeft.x * imageSize.width,
            y: observation.bottomLeft.y * imageSize.height
        )
        let bottomRight = CGPoint(
            x: observation.bottomRight.x * imageSize.width,
            y: observation.bottomRight.y * imageSize.height
        )
        
        let correctedCI = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight)
        ])
        
        let context = CIContext(options: nil)
        guard let finalCG = context.createCGImage(correctedCI, from: correctedCI.extent) else {
            return nil
        }
        
        return UIImage(cgImage: finalCG)
    }
}
