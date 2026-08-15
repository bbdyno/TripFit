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
        "FR": "TFDestinationParisV2",
        "JP": "TFDestinationTokyoV2",
        "IT": "TFDestinationAmalfiV2",
    ]

    private static let fallbackHero = "TFDestinationGenericV2"

    private let card = TFCardView(style: .flat)
    private let photoContainer = UIView()
    private let tripImageView = UIImageView()
    private let locationLabel = UILabel()
    private let titleLabel = UILabel()
    private let statusBadge = InsetLabel(insets: UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
    private let durationBadge = InsetLabel(insets: UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7))
    private let dateLabel = UILabel()
    private let localTimeLabel = UILabel()
    private let packingLabel = UILabel()
    private let packingProgressView = UIProgressView(progressViewStyle: .default)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 0

        photoContainer.layer.cornerRadius = 16
        photoContainer.layer.cornerCurve = .continuous
        photoContainer.clipsToBounds = true
        photoContainer.backgroundColor = TFColor.Surface.input

        tripImageView.contentMode = .scaleAspectFill
        tripImageView.clipsToBounds = true
        tripImageView.backgroundColor = TFColor.Surface.input

        locationLabel.font = TFTypography.footnote.withSize(12)
        locationLabel.textColor = TFColor.Text.secondary
        locationLabel.numberOfLines = 1

        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 1

        statusBadge.font = TFTypography.footnote.withSize(10)
        statusBadge.textColor = TFColor.Brand.accentMint
        statusBadge.backgroundColor = TFColor.Brand.accentMint.withAlphaComponent(0.12)
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true

        durationBadge.font = TFTypography.footnote.withSize(11)
        durationBadge.textColor = TFColor.Brand.primary
        durationBadge.backgroundColor = .clear
        durationBadge.clipsToBounds = true

        dateLabel.font = TFTypography.footnote
        dateLabel.textColor = TFColor.Text.secondary

        localTimeLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        localTimeLabel.textColor = TFColor.Text.tertiary
        localTimeLabel.numberOfLines = 1

        packingLabel.font = TFTypography.footnote.withSize(11)
        packingLabel.textColor = TFColor.Text.secondary
        packingProgressView.progressTintColor = TFColor.Brand.primary
        packingProgressView.trackTintColor = TFColor.Surface.input
        packingProgressView.layer.cornerRadius = 2
        packingProgressView.clipsToBounds = true

        card.addSubview(photoContainer)
        photoContainer.addSubview(tripImageView)
        card.addSubview(titleLabel)
        card.addSubview(statusBadge)
        card.addSubview(locationLabel)
        card.addSubview(durationBadge)
        card.addSubview(dateLabel)
        card.addSubview(localTimeLabel)
        card.addSubview(packingLabel)
        card.addSubview(packingProgressView)

        photoContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.size.equalTo(60)
        }
        tripImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(photoContainer.snp.trailing).offset(11)
            make.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-8)
        }

        statusBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(12)
        }

        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.equalToSuperview().inset(12)
        }

        durationBadge.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(locationLabel.snp.bottom).offset(5)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(durationBadge.snp.trailing).offset(8)
            make.centerY.equalTo(durationBadge)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        localTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(durationBadge.snp.bottom).offset(3)
            make.trailing.equalToSuperview().inset(12)
        }

        packingLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.top.equalTo(photoContainer.snp.bottom).offset(7)
        }

        packingProgressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(packingLabel.snp.bottom).offset(3)
            make.height.equalTo(3)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }
    }

    func configure(with trip: Trip) {
        titleLabel.text = trip.name
        dateLabel.text = TFDateFormatter.tripRange(start: trip.startDate, end: trip.endDate)
        let durationDays = tripDurationDays(for: trip)
        durationBadge.text = TFAppLanguage.current() == .korean ? "\(durationDays)일" : "\(durationDays) days"
        locationLabel.text = locationText(for: trip)
        statusBadge.text = statusText(for: trip)
        refreshLiveTime(for: trip)
        let totalCount = trip.totalCount
        let progress = totalCount > 0 ? Float(trip.packedCount) / Float(totalCount) : 0
        packingProgressView.setProgress(progress, animated: false)
        packingLabel.text = TFAppLanguage.current() == .korean
            ? "패킹 \(trip.packedCount)/\(totalCount)"
            : "Packing \(trip.packedCount)/\(totalCount)"
        loadImage(for: trip)
    }

    func refreshLiveTime(for trip: Trip) {
        let now = Date()
        guard let info = destinationInfo(for: trip) else {
            localTimeLabel.text = nil
            return
        }

        let localTime = TFDestinationCatalog.locationTimeString(
            for: info.timeZoneIdentifier,
            at: now,
            includeSeconds: false
        ) ?? "--:--"
        let delta = TFDestinationCatalog.localDeltaString(for: info.timeZoneIdentifier, at: now) ?? "Local"
        let localizedDelta = TFAppLanguage.current() == .korean
            ? delta.replacingOccurrences(of: "Local", with: "현지").replacingOccurrences(of: "h", with: "시간")
            : delta
        localTimeLabel.text = "\(localTime) · \(localizedDelta)"
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

    private func statusText(for trip: Trip) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        if today < start {
            let days = calendar.dateComponents([.day], from: today, to: start).day ?? 0
            return "D-\(days)"
        }
        if today <= end {
            return TFAppLanguage.current() == .korean ? "여행 중" : "NOW"
        }
        return TFAppLanguage.current() == .korean ? "완료" : "DONE"
    }

    private func imageAssetName(for trip: Trip) -> String {
        if let code = trip.destinationCountryCode, let mapped = Self.heroByCountryCode[code] {
            return mapped
        }
        if let destination = trip.destination?.lowercased() {
            if destination.contains("tokyo") { return Self.heroByCountryCode["JP"] ?? Self.fallbackHero }
            if destination.contains("paris") { return Self.heroByCountryCode["FR"] ?? Self.fallbackHero }
            if destination.contains("amalfi") || destination.contains("rome") || destination.contains("milan") {
                return Self.heroByCountryCode["IT"] ?? Self.fallbackHero
            }
        }
        return Self.fallbackHero
    }

    private func destinationInfo(for trip: Trip) -> TFDestinationInfo? {
        if let byCode = TFDestinationCatalog.info(forCountryCode: trip.destinationCountryCode) {
            return byCode
        }
        return TFDestinationCatalog.info(matchingDestinationText: trip.destination)
    }

    private func loadImage(for trip: Trip) {
        tripImageView.image = UIImage(named: imageAssetName(for: trip))
        tripImageView.contentMode = .scaleAspectFill
        tripImageView.tintColor = nil
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
