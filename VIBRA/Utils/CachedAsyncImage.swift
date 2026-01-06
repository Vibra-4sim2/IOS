//
//  CachedAsyncImage.swift
//  VIBRA
//
//  Image loader with caching to prevent repeated network requests
//

import SwiftUI

// MARK: - Image Cache Manager
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Setup memory cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // Setup disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheKey(for url: URL) -> String {
        return url.absoluteString.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
    
    // Get from memory cache
    func getFromMemory(_ url: URL) -> UIImage? {
        let key = cacheKey(for: url) as NSString
        return cache.object(forKey: key)
    }
    
    // Get from disk cache
    func getFromDisk(_ url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Also store in memory for faster access next time
        cache.setObject(image, forKey: key as NSString)
        return image
    }
    
    // Save to both caches
    func save(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        
        // Memory cache
        cache.setObject(image, forKey: key as NSString)
        
        // Disk cache (async to not block)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let data = image.jpegData(compressionQuality: 0.8) else { return }
            let fileURL = self.cacheDirectory.appendingPathComponent(key)
            try? data.write(to: fileURL)
        }
    }
    
    // Get image (memory first, then disk)
    func get(_ url: URL) -> UIImage? {
        if let memoryImage = getFromMemory(url) {
            return memoryImage
        }
        return getFromDisk(url)
    }
}

// MARK: - Cached Async Image View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else if loadFailed {
                placeholder()
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        // Check cache first
        if let cachedImage = ImageCacheManager.shared.get(url) {
            self.loadedImage = cachedImage
            return
        }
        
        isLoading = true
        
        // Load from network
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let image = UIImage(data: data) {
                    // Cache the image
                    ImageCacheManager.shared.save(image, for: url)
                    self.loadedImage = image
                } else {
                    self.loadFailed = true
                }
            }
        }.resume()
    }
}

// MARK: - Convenience initializer for simple placeholder
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}
