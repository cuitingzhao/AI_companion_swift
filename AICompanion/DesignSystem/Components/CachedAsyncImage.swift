import SwiftUI
import UIKit

/// A cached async image view that prevents cancellation issues in LazyVStack
/// Uses URLSession with a shared cache to load and cache images
struct CachedAsyncImage: View {
    let url: URL
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    // Shared image cache
    private static var imageCache = NSCache<NSURL, UIImage>()
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loadFailed {
                // Fallback for failed loads
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.neutralGray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.neutralGray.opacity(0.2))
            } else {
                // Loading state
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Check cache first
        if let cachedImage = Self.imageCache.object(forKey: url as NSURL) {
            self.image = cachedImage
            self.isLoading = false
            print("🖼️ Image loaded from cache: \(url.absoluteString)")
            return
        }
        
        // Download image
        do {
            print("🖼️ Downloading image: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                print("🖼️ Image download failed - bad response: \(url.absoluteString)")
                self.loadFailed = true
                self.isLoading = false
                return
            }
            
            guard let uiImage = UIImage(data: data) else {
                print("🖼️ Image decode failed: \(url.absoluteString)")
                self.loadFailed = true
                self.isLoading = false
                return
            }
            
            // Cache the image
            Self.imageCache.setObject(uiImage, forKey: url as NSURL)
            
            // Update UI on main thread
            await MainActor.run {
                self.image = uiImage
                self.isLoading = false
                print("🖼️ Image loaded successfully: \(url.absoluteString)")
            }
        } catch {
            print("🖼️ Image download error: \(url.absoluteString), error: \(error)")
            await MainActor.run {
                self.loadFailed = true
                self.isLoading = false
            }
        }
    }
}
