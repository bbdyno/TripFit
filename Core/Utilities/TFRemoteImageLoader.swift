//
//  TFRemoteImageLoader.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public final class TFRemoteImageLoader {
    public static let shared = TFRemoteImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let queue = DispatchQueue(label: "tripfit.remote-image-loader", attributes: .concurrent)
    private var tasks: [UUID: URLSessionDataTask] = [:]

    private init() {
        cache.countLimit = 200
    }

    @discardableResult
    public func load(from urlString: String?, completion: @escaping (UIImage?) -> Void) -> UUID? {
        guard
            let urlString,
            let url = URL(string: urlString),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            DispatchQueue.main.async { completion(nil) }
            return nil
        }

        let nsURL = url as NSURL
        if let cached = cache.object(forKey: nsURL) {
            DispatchQueue.main.async { completion(cached) }
            return nil
        }

        let token = UUID()
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            defer { self?.removeTask(for: token) }
            guard let self else { return }

            guard
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let data,
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self.cache.setObject(image, forKey: nsURL)
            DispatchQueue.main.async { completion(image) }
        }

        store(task: task, for: token)
        task.resume()
        return token
    }

    public func cancel(_ token: UUID?) {
        guard let token else { return }

        var task: URLSessionDataTask?
        queue.sync {
            task = tasks[token]
        }
        task?.cancel()
        removeTask(for: token)
    }

    private func store(task: URLSessionDataTask, for token: UUID) {
        queue.async(flags: .barrier) {
            self.tasks[token] = task
        }
    }

    private func removeTask(for token: UUID) {
        queue.async(flags: .barrier) {
            self.tasks[token] = nil
        }
    }
}

public enum TFMaterialIcon {
    public static func image(
        named ligature: String,
        pointSize: CGFloat,
        weight: UIFont.Weight = .regular
    ) -> UIImage? {
        guard let font = materialFont(size: pointSize, weight: weight) else { return nil }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
        ]
        let text = NSAttributedString(string: ligature, attributes: attributes)
        let size = CGSize(width: ceil(text.size().width), height: ceil(text.size().height))
        guard size.width > 0, size.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            text.draw(at: .zero)
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    private static func materialFont(size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        let name: String
        switch weight {
        case ..<UIFont.Weight.ultraLight:
            name = "MaterialSymbolsOutlined-Regular_Thin"
        case UIFont.Weight.ultraLight..<UIFont.Weight.light:
            name = "MaterialSymbolsOutlined-Regular_ExtraLight"
        case UIFont.Weight.light..<UIFont.Weight.regular:
            name = "MaterialSymbolsOutlined-Regular_Light"
        case UIFont.Weight.regular..<UIFont.Weight.medium:
            name = "MaterialSymbolsOutlined-Regular"
        case UIFont.Weight.medium..<UIFont.Weight.semibold:
            name = "MaterialSymbolsOutlined-Regular_Medium"
        case UIFont.Weight.semibold..<UIFont.Weight.bold:
            name = "MaterialSymbolsOutlined-Regular_SemiBold"
        default:
            name = "MaterialSymbolsOutlined-Regular_Bold"
        }
        return UIFont(name: name, size: size)
    }
}
