import SwiftUI

struct DigitRecognitionView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var showingImageSource = false
    @State private var recognizedDigits: [Int] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var formattedValue: String = ""

    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 100))
                    .foregroundStyle(.secondary)
                    .frame(height: 300)
            }
            
            VStack(spacing: 15) {
                Button(action: { showingImageSource = true }) {
                    Label("Upload Image", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                
                if isProcessing {
                    ProgressView("Processing...")
                } else if !recognizedDigits.isEmpty {
                    VStack(spacing: 10) {
                        Text("Detected Price: \(formattedValue)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

            }
            .padding()
        }
        .navigationTitle("Digit Recognition")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Choose Image Source", isPresented: $showingImageSource) {
            Button("Camera") { isShowingCamera = true }
            Button("Photo Library") { isShowingImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .onChange(of: selectedImage) { _ in
            if let image = selectedImage {
                processImage(image)
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let digits = try await NetworkManager.shared.uploadImage(image)
                await MainActor.run {
                    recognizedDigits = digits
                    formattedValue = formatAsCurrency(digits) // Formatea el resultado
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }

    
    private func formatAsCurrency(_ numbers: [Int]) -> String {
        guard !numbers.isEmpty else { return "$0.00" }
        
        let numberString = numbers.map { String($0) }.joined()
        
        if numberString.count > 2 {
            let index = numberString.index(numberString.startIndex, offsetBy: 2)
            return "$" + numberString[..<index] + "." + numberString[index...]
        } else {
            return "$0." + numberString.padding(toLength: 2, withPad: "0", startingAt: 0)
        }
    }

}

struct DigitsResultView: View {
    let digits: [Int]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Recognized Digits")
                .font(.headline)
            
            Text(digits.map(String.init).joined(separator: ", "))
                .font(.title2)
                .fontWeight(.medium)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
} 
