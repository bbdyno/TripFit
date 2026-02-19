import Core
import Domain
import SnapKit
import UIKit

final class TripCell: UICollectionViewCell {
    static let reuseId = "TripCell"

    private let card = TFCardView()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let destinationLabel = UILabel()
    private let progressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.textColor = TFColor.textPrimary

        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = TFColor.textSecondary

        destinationLabel.font = .preferredFont(forTextStyle: .caption1)
        destinationLabel.textColor = TFColor.sky

        progressLabel.font = .preferredFont(forTextStyle: .caption1)
        progressLabel.textColor = TFColor.mint
        progressLabel.textAlignment = .right

        let topRow = UIStackView(arrangedSubviews: [nameLabel, progressLabel])
        topRow.distribution = .fill

        let vStack = UIStackView(arrangedSubviews: [topRow, dateLabel, destinationLabel])
        vStack.axis = .vertical
        vStack.spacing = 6
        card.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(with trip: Trip) {
        nameLabel.text = trip.name
        dateLabel.text = TFDateFormatter.tripRange(start: trip.startDate, end: trip.endDate)
        destinationLabel.text = trip.destination
        destinationLabel.isHidden = trip.destination?.isEmpty != false
        progressLabel.text = "Packed: \(trip.progressText)"
    }
}
