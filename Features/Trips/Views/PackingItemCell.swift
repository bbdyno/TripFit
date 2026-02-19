import Core
import Domain
import SnapKit
import UIKit

final class PackingItemCell: UITableViewCell {
    static let reuseId = "PackingItemCell"

    private let nameLabel = UILabel()
    private let quantityLabel = UILabel()
    private let stepper = UIStepper()
    private let checkButton = UIButton(type: .system)

    private var item: PackingItem?
    private var onChange: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.textColor = TFColor.textPrimary
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        quantityLabel.font = .preferredFont(forTextStyle: .caption1)
        quantityLabel.textColor = TFColor.textSecondary
        quantityLabel.textAlignment = .center

        stepper.minimumValue = 1
        stepper.maximumValue = 99
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)

        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)

        let rightStack = UIStackView(arrangedSubviews: [quantityLabel, stepper, checkButton])
        rightStack.spacing = 8
        rightStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [nameLabel, rightStack])
        mainStack.spacing = 8
        mainStack.alignment = .center

        contentView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }

        checkButton.snp.makeConstraints { $0.size.equalTo(30) }
    }

    func configure(with item: PackingItem, onChange: @escaping () -> Void) {
        self.item = item
        self.onChange = onChange
        nameLabel.text = item.displayName
        quantityLabel.text = "×\(item.quantity)"
        stepper.value = Double(item.quantity)
        updateCheckState()

        if item.isPacked {
            nameLabel.textColor = TFColor.textSecondary
        } else {
            nameLabel.textColor = TFColor.textPrimary
        }
    }

    private func updateCheckState() {
        guard let item else { return }
        let imageName = item.isPacked ? "checkmark.circle.fill" : "circle"
        let color = item.isPacked ? TFColor.mint : TFColor.textSecondary
        checkButton.setImage(UIImage(systemName: imageName), for: .normal)
        checkButton.tintColor = color
    }

    @objc private func stepperChanged() {
        guard let item else { return }
        item.quantity = Int(stepper.value)
        item.updatedAt = Date()
        quantityLabel.text = "×\(item.quantity)"
        try? item.modelContext?.save()
        onChange?()
    }

    @objc private func checkTapped() {
        guard let item else { return }
        item.isPacked.toggle()
        item.updatedAt = Date()
        try? item.modelContext?.save()
        updateCheckState()
        nameLabel.textColor = item.isPacked ? TFColor.textSecondary : TFColor.textPrimary
        onChange?()
    }
}
