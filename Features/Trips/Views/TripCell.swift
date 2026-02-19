//
//  TripCell.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import UIKit

final class TripCell: UICollectionViewCell {
    static let reuseId = "TripCell"

    private static let heroByCountryCode: [String: String] = [
        "FR": "https://lh3.googleusercontent.com/aida-public/AB6AXuB0J5YyvNmfHfw7AP99Ngfg8KzIsXMNML3qMXHenWYb7d9AtiHqsDsGX00-MrMq31hHMKYHrDgevIeGYspq8T6Jp1x7AuV2bHRMZza3DCDQYvVkuNyLm9hTe-tOWcb5BMoaNNByO6gtpujMGfZ0zYTieorkVgb9lHAWeFO82XLpxysVtHMzmMeTxwHWzSACo1OiX8gT4SI3inAkw12rxB7u-0d9Gc6fegVfqWdrHt2u_ddFIUX9HKzkuh6VS8y1fWIw3tbTga-QB_I",
        "JP": "https://lh3.googleusercontent.com/aida-public/AB6AXuBNErgL5xReDbrn1naYRZj2j968_6XOw7TAJuwkUEcAjZPiLXXfUvNPn9Inw2nK0QnmR8x1GZkwXj542olle6Od2izQz5YxulFOsJxbtKxuHMUkohqQteS-ajkTSGImYLMMVXbcxJjNKkqAK30xKTkBa6XCyYhf1FPffAwQJMnx-jI8qx7DDKvcKLVlRRXu1j9ZfvSBdT0z0tVbB2XsMt8m0O7di9Igxzily6GMRz0s0-JCmkn5jbEJfZxDzrUl5koDk_dO-llqxVM",
        "IT": "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?auto=format&fit=crop&w=1200&q=80",
        "ES": "https://images.unsplash.com/photo-1543785734-4b1ad6e5fd15?auto=format&fit=crop&w=1200&q=80",
        "US": "https://images.unsplash.com/photo-1496588152823-e7d8f8c7f8b9?auto=format&fit=crop&w=1200&q=80",
    ]

    private static let fallbackHero = "https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80"

    private let card = TFCardView(style: .elevated)
    private let photoContainer = UIView()
    private let tripImageView = UIImageView()
    private let locationIcon = UIImageView(image: UIImage(systemName: "location.fill"))
    private let locationLabel = UILabel()
    private let titleLabel = UILabel()
    private let durationBadge = InsetLabel(insets: UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7))
    private let dateLabel = UILabel()
    private let progressRing = TFProgressRingView()
    private let imageGradientLayer = CAGradientLayer()

    private var imageRequestToken: UUID?
    private var imageRequestID = UUID()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageGradientLayer.frame = tripImageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()
        tripImageView.image = nil
        tripImageView.tintColor = nil
    }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.layer.cornerRadius = 24
        card.layer.borderColor = TFColor.Border.subtle.cgColor

        photoContainer.layer.cornerRadius = 16
        photoContainer.clipsToBounds = true
        photoContainer.backgroundColor = TFColor.Surface.input

        tripImageView.contentMode = .scaleAspectFill
        tripImageView.clipsToBounds = true
        tripImageView.backgroundColor = TFColor.Surface.input

        imageGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
        ]
        imageGradientLayer.locations = [0.45, 1]

        locationIcon.tintColor = .white
        locationIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

        locationLabel.font = TFTypography.footnote.withSize(12)
        locationLabel.textColor = .white

        titleLabel.font = TFTypography.headline.withSize(20)
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 1

        durationBadge.font = TFTypography.footnote.withSize(11)
        durationBadge.textColor = TFColor.Brand.primary
        durationBadge.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.12)
        durationBadge.layer.cornerRadius = 8
        durationBadge.clipsToBounds = true

        dateLabel.font = TFTypography.footnote
        dateLabel.textColor = TFColor.Text.secondary

        progressRing.backgroundColor = TFColor.Surface.card
        progressRing.layer.cornerRadius = 28
        progressRing.layer.borderWidth = 1
        progressRing.layer.borderColor = TFColor.Border.subtle.cgColor

        card.addSubview(photoContainer)
        photoContainer.addSubview(tripImageView)
        tripImageView.layer.addSublayer(imageGradientLayer)
        photoContainer.addSubview(locationIcon)
        photoContainer.addSubview(locationLabel)
        card.addSubview(titleLabel)
        card.addSubview(durationBadge)
        card.addSubview(dateLabel)
        card.addSubview(progressRing)

        photoContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(192)
        }
        tripImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        locationIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
            make.size.equalTo(14)
        }
        locationLabel.snp.makeConstraints { make in
            make.centerY.equalTo(locationIcon)
            make.leading.equalTo(locationIcon.snp.trailing).offset(5)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(photoContainer.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(14)
            make.trailing.lessThanOrEqualTo(progressRing.snp.leading).offset(-12)
        }

        durationBadge.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationBadge)
            make.leading.equalTo(durationBadge.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(progressRing.snp.leading).offset(-12)
        }

        progressRing.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalTo(titleLabel.snp.bottom)
            make.size.equalTo(56)
        }
    }

    func configure(with trip: Trip) {
        titleLabel.text = trip.name
        dateLabel.text = TFDateFormatter.tripRange(start: trip.startDate, end: trip.endDate)
        durationBadge.text = "\(tripDurationDays(for: trip)) days"
        locationLabel.text = locationText(for: trip)
        progressRing.setProgress(current: trip.packedCount, total: max(trip.totalCount, 1))
        loadImage(for: trip)
    }

    private func tripDurationDays(for trip: Trip) -> Int {
        let dayDiff = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        return max(dayDiff + 1, 1)
    }

    private func locationText(for trip: Trip) -> String {
        if let destination = trip.destination, !destination.isEmpty {
            return destination
        }
        if let code = trip.destinationCountryCode, !code.isEmpty {
            return code
        }
        return "No destination"
    }

    private func imageURL(for trip: Trip) -> String {
        if let code = trip.destinationCountryCode, let mapped = Self.heroByCountryCode[code] {
            return mapped
        }
        if let destination = trip.destination?.lowercased() {
            if destination.contains("tokyo") { return Self.heroByCountryCode["JP"] ?? Self.fallbackHero }
            if destination.contains("paris") { return Self.heroByCountryCode["FR"] ?? Self.fallbackHero }
            if destination.contains("rome") || destination.contains("milan") { return Self.heroByCountryCode["IT"] ?? Self.fallbackHero }
        }
        return Self.fallbackHero
    }

    private func loadImage(for trip: Trip) {
        TFRemoteImageLoader.shared.cancel(imageRequestToken)
        imageRequestToken = nil
        imageRequestID = UUID()

        tripImageView.image = UIImage(systemName: "airplane")
        tripImageView.contentMode = .scaleAspectFit
        tripImageView.tintColor = TFColor.Brand.primary

        let requestID = imageRequestID
        imageRequestToken = TFRemoteImageLoader.shared.load(from: imageURL(for: trip)) { [weak self] image in
            guard let self, self.imageRequestID == requestID, let image else { return }
            self.tripImageView.image = image
            self.tripImageView.contentMode = .scaleAspectFill
            self.tripImageView.tintColor = nil
        }
    }
}

private final class InsetLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
