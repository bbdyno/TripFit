//
//  OnboardingViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import SnapKit
import UIKit

public final class OnboardingViewController: UIViewController {
    public var onComplete: (() -> Void)?

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()

    private let pageIndicator = WalkthroughPageIndicatorView()
    private let nextButton = TFPrimaryButton(title: "Next")
    private let skipButton = UIButton(type: .system)

    private var currentPage = 0 {
        didSet {
            guard oldValue != currentPage else { return }
            applyPageState(animated: true)
        }
    }

    private let pages: [WalkthroughPage] = [
        WalkthroughPage(
            symbol: "photo.badge.plus",
            title: "Build Your Wardrobe Fast",
            subtitle: "Add clothing photos, set color + season, and keep everything organized in one place.",
            previewTitle: "Add Item",
            previewSubtitle: "Vintage Denim Jacket",
            chips: ["Color", "Season", "Notes"],
            canvasColor: UIColor(hex: 0xFFE8F3)
        ),
        WalkthroughPage(
            symbol: "person.crop.rectangle.stack.fill",
            title: "Create Looks from Your Closet",
            subtitle: "Pick your favorite pieces, combine them into outfits, and save ready-to-wear sets.",
            previewTitle: "Create Outfit",
            previewSubtitle: "Sunday Brunch • 3 items",
            chips: ["Tops", "Bottoms", "Shoes"],
            canvasColor: UIColor(hex: 0xEAF3FF)
        ),
        WalkthroughPage(
            symbol: "airplane.departure",
            title: "Plan Trips with Live Local Time",
            subtitle: "Set destinations, build packing checklists, and stay aligned with local time at your destination.",
            previewTitle: "Add Trip",
            previewSubtitle: "Tokyo, Japan • GMT+09:00",
            chips: ["Destination", "Dates", "Checklist"],
            canvasColor: UIColor(hex: 0xF5ECFF)
        ),
    ]

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyPageState(animated: false)
    }

    private func setupUI() {
        view.backgroundColor = .white

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WalkthroughPageCell.self, forCellWithReuseIdentifier: WalkthroughPageCell.reuseId)

        view.addSubview(collectionView)
        view.addSubview(pageIndicator)
        view.addSubview(nextButton)
        view.addSubview(skipButton)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageIndicator.snp.top).offset(-22)
        }

        pageIndicator.numberOfPages = pages.count
        pageIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-24)
            make.height.equalTo(8)
        }

        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(skipButton.snp.top).offset(-10)
        }
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(TFColor.Text.tertiary, for: .normal)
        skipButton.titleLabel?.font = TFTypography.caption.withSize(14)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        skipButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(14)
            make.height.equalTo(24)
        }
    }

    @objc private func nextTapped() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            scrollToPage(currentPage, animated: true)
        } else {
            onComplete?()
        }
    }

    @objc private func skipTapped() {
        onComplete?()
    }

    private func scrollToPage(_ page: Int, animated: Bool) {
        let targetPage = max(0, min(pages.count - 1, page))
        let indexPath = IndexPath(item: targetPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        if !animated {
            currentPage = targetPage
        }
    }

    private func applyPageState(animated: Bool) {
        pageIndicator.setCurrentPage(currentPage, animated: animated)
        let isLast = currentPage == pages.count - 1
        nextButton.setTitle(isLast ? "Get Started" : "Next", for: .normal)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.skipButton.alpha = isLast ? 0 : 1
            }
        } else {
            skipButton.alpha = isLast ? 0 : 1
        }
        skipButton.isUserInteractionEnabled = !isLast
    }

    private func syncCurrentPage(with scrollView: UIScrollView) {
        let width = max(scrollView.bounds.width, 1)
        let page = Int(round(scrollView.contentOffset.x / width))
        currentPage = max(0, min(pages.count - 1, page))
    }
}

extension OnboardingViewController: UICollectionViewDataSource {
    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        pages.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WalkthroughPageCell.reuseId, for: indexPath
        ) as! WalkthroughPageCell
        let page = pages[indexPath.item]
        cell.configure(with: page)
        return cell
    }
}

extension OnboardingViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncCurrentPage(with: scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncCurrentPage(with: scrollView)
    }
}

private struct WalkthroughPage {
    let symbol: String
    let title: String
    let subtitle: String
    let previewTitle: String
    let previewSubtitle: String
    let chips: [String]
    let canvasColor: UIColor
}

private final class WalkthroughPageCell: UICollectionViewCell {
    static let reuseId = "WalkthroughPageCell"

    private let cardView = TFCardView(style: .flat)
    private let stack = UIStackView()
    private let artworkCanvas = UIView()
    private let previewCard = UIView()
    private let previewIcon = UIImageView()
    private let previewTitleLabel = UILabel()
    private let previewSubtitleLabel = UILabel()
    private let chipsStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.layer.cornerRadius = 26
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18))
        }

        stack.axis = .vertical
        stack.spacing = 18
        cardView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 18, bottom: 24, right: 18))
        }

        artworkCanvas.layer.cornerRadius = 20
        artworkCanvas.layer.borderWidth = 1
        artworkCanvas.layer.borderColor = TFColor.Border.subtle.cgColor
        artworkCanvas.clipsToBounds = true
        stack.addArrangedSubview(artworkCanvas)
        artworkCanvas.snp.makeConstraints { make in
            make.height.equalTo(280)
        }

        previewCard.backgroundColor = TFColor.Surface.card
        previewCard.layer.cornerRadius = 18
        previewCard.layer.borderWidth = 1
        previewCard.layer.borderColor = TFColor.Border.subtle.cgColor
        artworkCanvas.addSubview(previewCard)
        previewCard.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(228)
            make.height.equalTo(170)
        }

        previewIcon.tintColor = TFColor.Brand.primary
        previewIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        previewCard.addSubview(previewIcon)
        previewIcon.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(30)
        }

        previewTitleLabel.font = TFTypography.headline.withSize(18)
        previewTitleLabel.textColor = TFColor.Text.primary
        previewCard.addSubview(previewTitleLabel)
        previewTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.top.equalTo(previewIcon.snp.bottom).offset(8)
            make.trailing.equalToSuperview().inset(14)
        }

        previewSubtitleLabel.font = TFTypography.bodyRegular.withSize(14)
        previewSubtitleLabel.textColor = TFColor.Text.secondary
        previewCard.addSubview(previewSubtitleLabel)
        previewSubtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(previewTitleLabel)
            make.top.equalTo(previewTitleLabel.snp.bottom).offset(4)
        }

        chipsStack.axis = .horizontal
        chipsStack.alignment = .center
        chipsStack.spacing = 8
        chipsStack.distribution = .fillProportionally
        previewCard.addSubview(chipsStack)
        chipsStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.trailing.lessThanOrEqualToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(14)
        }

        titleLabel.font = TFTypography.largeTitle.withSize(34)
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 2
        stack.addArrangedSubview(titleLabel)

        subtitleLabel.font = TFTypography.bodyRegular.withSize(17)
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.addArrangedSubview(subtitleLabel)
    }

    func configure(with page: WalkthroughPage) {
        previewIcon.image = UIImage(systemName: page.symbol)
        previewTitleLabel.text = page.previewTitle
        previewSubtitleLabel.text = page.previewSubtitle
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        artworkCanvas.backgroundColor = page.canvasColor

        chipsStack.arrangedSubviews.forEach { view in
            chipsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for chip in page.chips {
            let label = UILabel()
            label.text = " \(chip) "
            label.font = TFTypography.footnote.withSize(12)
            label.textColor = TFColor.Brand.primary
            label.textAlignment = .center
            label.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.1)
            label.layer.cornerRadius = 11
            label.clipsToBounds = true
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.snp.makeConstraints { make in
                make.height.equalTo(22)
            }
            chipsStack.addArrangedSubview(label)
        }
    }
}

private final class WalkthroughPageIndicatorView: UIView {
    var numberOfPages: Int = 0 {
        didSet { rebuildDots() }
    }

    private var currentPage = 0
    private let stackView = UIStackView()
    private var dots: [UIView] = []
    private var widthConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCurrentPage(_ page: Int, animated: Bool) {
        guard !dots.isEmpty else { return }
        currentPage = max(0, min(numberOfPages - 1, page))
        applyDotState(animated: animated)
    }

    private func rebuildDots() {
        dots.forEach { dot in
            stackView.removeArrangedSubview(dot)
            dot.removeFromSuperview()
        }
        dots.removeAll()
        widthConstraints.removeAll()

        guard numberOfPages > 0 else { return }

        for _ in 0..<numberOfPages {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.clipsToBounds = true
            dot.translatesAutoresizingMaskIntoConstraints = false
            let width = dot.widthAnchor.constraint(equalToConstant: 8)
            width.isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            widthConstraints.append(width)
            dots.append(dot)
            stackView.addArrangedSubview(dot)
        }
        currentPage = min(currentPage, numberOfPages - 1)
        applyDotState(animated: false)
    }

    private func applyDotState(animated: Bool) {
        guard !dots.isEmpty else { return }

        let update = {
            for (index, dot) in self.dots.enumerated() {
                let isCurrent = index == self.currentPage
                self.widthConstraints[index].constant = isCurrent ? 24 : 8
                dot.backgroundColor = isCurrent ? TFColor.Brand.primary : TFColor.Brand.primary.withAlphaComponent(0.22)
            }
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.24, delay: 0, options: .curveEaseInOut, animations: update)
        } else {
            update()
        }
    }
}
