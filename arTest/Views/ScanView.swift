import SwiftUI
import PhotosUI
import CoreML
import Vision

struct ScanView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var detectedClass: String = ""
    @State private var detectedConfidence: Double = 0.0
    @State private var showingImageSource = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                Image(systemName: "camera.viewfinder")
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
                
                if !detectedClass.isEmpty {
                    ResultView(className: detectedClass, detectedConfidence: detectedConfidence)
                }
            }
            .padding()
        }
        .navigationTitle("Road Sign Scanner")
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
                classifyImage(image)
            }
        }
    }
    
    private func classifyImage(_ image: UIImage) {
        guard let resizedImage = image.resized(to: CGSize(width: 416, height: 416)),
              let buffer = resizedImage.toCVPixelBuffer() else {
            print("Error al procesar la imagen.")
            return
        }
        
        do {
            let config = MLModelConfiguration()
            let model = try RoadSignModelCoreML(configuration: config)
            
            // Realiza la predicción
            let prediction = try model.prediction(image: buffer, iouThreshold: 0.5, confidenceThreshold: 0.5)
            
            // Mapear categorías
            let categories = ["Crosswalk", "Speed limit", "Stop sign", "Traffic light"]
            
            // Convertir MLMultiArray en arreglo de Double
            let confidenceArray = prediction.confidence
            print(confidenceArray)

            // Accessing individual elements
            let firstValue = confidenceArray[0] as! Double
            let secondValue = confidenceArray[1] as! Double
            let thirdValue = confidenceArray[2] as! Double
            let fourthValue = confidenceArray[3] as! Double
            
            let formattedFirstValue = String(format: "%.6f", firstValue)
            let formattedSecondValue = String(format: "%.6f", secondValue)
            let formattedThirdValue = String(format: "%.6f", thirdValue)
            let formattedFourthValue = String(format: "%.6f", fourthValue)

            // Case structure to handle the four cases using formatted values and map to categories
            switch true {
            case formattedFirstValue > formattedSecondValue && formattedFirstValue > formattedThirdValue && formattedFirstValue > formattedFourthValue:
                detectedClass = categories[0]  // "crosswalk"
                detectedConfidence = confidenceArray[0].doubleValue
            case formattedSecondValue > formattedFirstValue && formattedSecondValue > formattedThirdValue && formattedSecondValue > formattedFourthValue:
                detectedClass = categories[1]  // "speedlimit"
                detectedConfidence = confidenceArray[1].doubleValue
            case formattedThirdValue > formattedFirstValue && formattedThirdValue > formattedSecondValue && formattedThirdValue > formattedFourthValue:
                detectedClass = categories[2]  // "stop"
                detectedConfidence = confidenceArray[2].doubleValue
            case formattedFourthValue > formattedFirstValue && formattedFourthValue > formattedSecondValue && formattedFourthValue > formattedThirdValue:
                detectedClass = categories[3]  // "trafficlight"
                detectedConfidence = confidenceArray[3].doubleValue
            default:
                detectedClass = "Unrecognized class"
            }
        } catch {
            print("Error en la clasificación: \(error)")
        }
    }
}

struct ResultView: View {
    let className: String
    let detectedConfidence: Double
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Detection Results")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sign Type:")
                        .fontWeight(.medium)
                    Text(className)
                }
                
                HStack {
                    Text("Confidence:")
                        .fontWeight(.medium)
                    Text(String(format: "%.1f%%", detectedConfidence * 100))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
} 
