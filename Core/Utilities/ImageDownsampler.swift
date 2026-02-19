//
//  ImageDownsampler.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

public enum ImageDownsampler {
    public static func downsample(_ data: Data, maxDimension: CGFloat = 600) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        guard scale < 1.0 else { return data }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
