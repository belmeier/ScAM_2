import SwiftUI
import PhotosUI
import Vision
import CoreImage

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var isProcessing = false
    @State private var statusText: String = "Pilih hasil pindai kamu!"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Image Comparison View
                HStack(spacing: 12) {
                    VStack {
                        Text("Gambar sebelum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                            if let originalImage {
                                Image(uiImage: originalImage)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                    
                    VStack {
                        Text("Gambar sesudah")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                            if let croppedImage {
                                Image(uiImage: croppedImage)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                }
                .frame(maxHeight: 280)
                .padding(.horizontal)
                
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                // Photo Picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                
                // Action Button
                Button {
                    processReceipt()
                } label: {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Perbaiki otomatis semuanya", systemImage: "crop")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(originalImage == nil || isProcessing)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ScAM v2")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
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
                statusText = "Maaf, saya gagal mendeteksi bentuk persegi dokumen kamu."
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
                print("Vision error: \(error.localizedDescription)")
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
