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
    
    @State private var imageSaver: ImageSaver?
    
    // Save Feedback States
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full-Screen Background matching the illustration
                Color.tealSurface
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
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
                    .frame(height: 250)
                    .padding(.horizontal)
                    .padding(.top, 26)
                    
                    // Status Description
                    Text(statusText)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.tealSubtext)
                        .padding(.top, 2)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // 1. Photo Picker Button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                Text("Pilih gambarnya")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.brandTeal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.tealBorder, lineWidth: 1.5)
                            )
                        }
                        
                        // 2. Process / Straighten Button
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
                            .frame(height: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(originalImage == nil || isProcessing)
                        
                        // 3. Save to Photos Button
                        Button {
                            saveToPhotos()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Simpan ke Galeri")
                            }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(croppedImage == nil ? Color.tealSubtext.opacity(0.5) : Color.brandTeal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(croppedImage == nil ? Color.tealBorder.opacity(0.4) : Color.brandTeal, lineWidth: 1.5)
                            )
                        }
                        .disabled(croppedImage == nil || isProcessing)
                    }
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
            .alert("Simpan Foto", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
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
        statusText = "Mencari pinggiran dokumen kamu..."
        
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
    
    private func saveToPhotos() {
        guard let croppedImage else { return }

        // Gunakan state agar saver tetap hidup di memori sampai proses callback selesai
        imageSaver = ImageSaver()
        imageSaver?.onSuccess = {
            saveAlertMessage = "Hasil pindaian berhasil disimpan ke Galeri Foto!"
            showingSaveAlert = true
            statusText = "Tersimpan ke galeri foto."
            imageSaver = nil
        }
        imageSaver?.onError = { error in
            saveAlertMessage = "Gagal menyimpan foto: \(error.localizedDescription)"
            showingSaveAlert = true
            imageSaver = nil
        }

        imageSaver?.saveImage(croppedImage)
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
        
        // 1. Kunci color space ke standar sRGB 8-bit agar JFIF/JPEG encoder mengenalinya
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let context = CIContext(options: [
            .workingColorSpace: colorSpace,
            .outputColorSpace: colorSpace
        ])
        
        let integralExtent = correctedCI.extent.integral
        guard let finalCG = context.createCGImage(
            correctedCI,
            from: integralExtent,
            format: .RGBA8,
            colorSpace: colorSpace
        ) else {
            return nil
        }
        
        let rawImage = UIImage(cgImage: finalCG)
        
        // 2. Flatten bitmap untuk menghilangkan metadata CoreImage yang ditolak JFIF session
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: rawImage.size, format: format)
        return renderer.image { _ in
            rawImage.draw(in: CGRect(origin: .zero, size: rawImage.size))
        }
    }
}


