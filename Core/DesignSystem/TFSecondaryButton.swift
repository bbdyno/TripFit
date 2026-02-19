import UIKit

public final class TFSecondaryButton: UIButton {
    public init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(TFColor.sky, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .headline)
        layer.cornerRadius = 12
        layer.borderWidth = 1.5
        layer.borderColor = TFColor.sky.cgColor
        backgroundColor = .clear

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
