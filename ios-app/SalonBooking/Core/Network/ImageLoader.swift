import SwiftUI
import UIKit

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    private static var cache = NSCache<NSString, UIImage>()

    func load(from urlString: String) {
        // Check cache first
        if let cached = Self.cache.object(forKey: urlString as NSString) {
            self.image = cached
            return
        }

        guard let url = URL(string: urlString) else { return }

        isLoading = true

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let uiImage = UIImage(data: data) else {
                    isLoading = false
                    return
                }

                Self.cache.setObject(uiImage, forKey: urlString as NSString)
                self.image = uiImage
                self.isLoading = false
            } catch {
                self.isLoading = false
            }
        }
    }
}
