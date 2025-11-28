import SwiftUI
import UIKit
import ImageIO

/// A SwiftUI view that displays an animated GIF from the app bundle
/// Use .frame(width:height:) to control the size - the GIF will scale to fit
struct GIFImage: UIViewRepresentable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        if let gifImage = loadGIF(named: name) {
            imageView.image = gifImage
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // No update needed
    }
    
    private func loadGIF(named name: String) -> UIImage? {
        // Try to find the GIF in the bundle
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("❌ Failed to load GIF: \(name)")
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: Double = 0
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            
            // Get frame duration
            let frameDuration = getFrameDuration(for: source, at: i)
            totalDuration += frameDuration
            
            images.append(UIImage(cgImage: cgImage))
        }
        
        // Create animated image
        return UIImage.animatedImage(with: images, duration: totalDuration)
    }
    
    private func getFrameDuration(for source: CGImageSource, at index: Int) -> Double {
        let defaultDuration = 0.1
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return defaultDuration
        }
        
        // Try to get unclamped delay time first, then fall back to delay time
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double,
           unclampedDelay > 0 {
            return unclampedDelay
        }
        
        if let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double,
           delay > 0 {
            return delay
        }
        
        return defaultDuration
    }
}

#Preview {
    GIFImage(name: "bouncing")
        .frame(width: 100, height: 100)
}
