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

    private let brandLabel = UILabel()
    private let skipButton = UIButton(type: .system)
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceHorizontal = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    private let progressView = WalkthroughProgressView()
    private let nextButton = TFPrimaryButton(title: "")

    private lazy var pages = Self.makePages()
    private var currentPage = 0 {
        didSet {
            guard oldValue != currentPage else { return }
            applyPageState(animated: true)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyPageState(animated: false)
    }

    private func setupUI() {
        view.backgroundColor = TFColor.Surface.canvas

        brandLabel.text = "TRIPFIT"
        brandLabel.font = TFTypography.caption.withSize(13)
        brandLabel.textColor = TFColor.Text.primary
        brandLabel.accessibilityLabel = "TripFit"
        brandLabel.adjustsFontForContentSizeCategory = true

        skipButton.setTitle(localized("건너뛰기", "Skip"), for: .normal)
        skipButton.setTitleColor(TFColor.Text.secondary, for: .normal)
        skipButton.titleLabel?.font = TFTypography.caption.withSize(14)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [brandLabel, UIView(), skipButton])
        header.alignment = .center
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(14)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.xl)
            make.height.equalTo(32)
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WalkthroughPageCell.self, forCellWithReuseIdentifier: WalkthroughPageCell.reuseID)

        progressView.numberOfPages = pages.count
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.semanticContentAttribute = .forceRightToLeft
        nextButton.setImage(
            UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)),
            for: .normal
        )
        nextButton.tintColor = .white
        if var configuration = nextButton.configuration {
            configuration.imagePlacement = .trailing
            configuration.imagePadding = 8
            nextButton.configuration = configuration
        }

        view.addSubview(collectionView)
        view.addSubview(progressView)
        view.addSubview(nextButton)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(progressView.snp.top).offset(-18)
        }

        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(TFSpacing.xl)
            make.bottom.equalTo(nextButton.snp.top).offset(-18)
            make.height.equalTo(24)
        }

        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(TFSpacing.xl)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
    }

    @objc private func nextTapped() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            collectionView.scrollToItem(
                at: IndexPath(item: currentPage, section: 0),
                at: .centeredHorizontally,
                animated: !UIAccessibility.isReduceMotionEnabled
            )
        } else {
            onComplete?()
        }
    }

    @objc private func skipTapped() {
        onComplete?()
    }

    private func applyPageState(animated: Bool) {
        progressView.setCurrentPage(currentPage, animated: animated)
        let isLast = currentPage == pages.count - 1
        nextButton.setTitle(
            isLast ? localized("TripFit 시작하기", "Start with TripFit") : localized("다음", "Continue"),
            for: .normal
        )

        let changes = {
            self.skipButton.alpha = isLast ? 0 : 1
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.22, animations: changes)
        } else {
            changes()
        }
        skipButton.isUserInteractionEnabled = !isLast
    }

    private func syncCurrentPage(with scrollView: UIScrollView) {
        let width = max(scrollView.bounds.width, 1)
        currentPage = max(0, min(pages.count - 1, Int(round(scrollView.contentOffset.x / width))))
    }

    private static func makePages() -> [WalkthroughPage] {
        return [
            WalkthroughPage(
                kind: .journey,
                step: CoreStrings.Onboarding.Walkthrough.journeyStep,
                title: CoreStrings.Onboarding.Walkthrough.journeyTitle,
                subtitle: CoreStrings.Onboarding.Walkthrough.journeySubtitle,
                accentColor: TFColor.Brand.primary
            ),
            WalkthroughPage(
                kind: .wardrobe,
                step: CoreStrings.Onboarding.Walkthrough.wardrobeStep,
                title: CoreStrings.Onboarding.Walkthrough.wardrobeTitle,
                subtitle: CoreStrings.Onboarding.Walkthrough.wardrobeSubtitle,
                accentColor: TFColor.Brand.accentMint
            ),
            WalkthroughPage(
                kind: .outfits,
                step: CoreStrings.Onboarding.Walkthrough.outfitsStep,
                title: CoreStrings.Onboarding.Walkthrough.outfitsTitle,
                subtitle: CoreStrings.Onboarding.Walkthrough.outfitsSubtitle,
                accentColor: TFColor.Brand.accentPurple
            ),
        ]
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean
            ? korean
            : (TFLocalizationRuntime.localized(english) ?? english)
    }
}

extension OnboardingViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pages.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WalkthroughPageCell.reuseID,
            for: indexPath
        ) as! WalkthroughPageCell
        cell.configure(with: pages[indexPath.item])
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
    enum Kind {
        case journey
        case wardrobe
        case outfits
        case trips
    }

    let kind: Kind
    let step: String
    let title: String
    let subtitle: String
    let accentColor: UIColor
}

private final class WalkthroughPageCell: UICollectionViewCell {
    static let reuseID = "WalkthroughPageCell"

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let artwork = WalkthroughArtworkView()
    private let stepLabel = UILabel()
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

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        stack.axis = .vertical
        stack.spacing = 12
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView.contentLayoutGuide).inset(8)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(TFSpacing.xl)
            make.width.equalTo(scrollView.frameLayoutGuide).inset(TFSpacing.xl)
        }

        artwork.layer.cornerRadius = TFRadius.xl
        artwork.layer.cornerCurve = .continuous
        artwork.clipsToBounds = true
        stack.addArrangedSubview(artwork)
        artwork.snp.makeConstraints { make in
            make.height.equalTo(258).priority(.high)
            make.height.greaterThanOrEqualTo(220)
        }
        stack.setCustomSpacing(18, after: artwork)

        stepLabel.font = TFTypography.caption.withSize(12)
        stepLabel.textColor = TFColor.Brand.primary
        stepLabel.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(stepLabel)

        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.addArrangedSubview(titleLabel)

        subtitleLabel.font = TFTypography.bodyRegular.withSize(16)
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.addArrangedSubview(subtitleLabel)

        applyAccessibilityLayout()
    }

    func configure(with page: WalkthroughPage) {
        stepLabel.text = page.step.uppercased()
        stepLabel.textColor = page.accentColor
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        artwork.configure(kind: page.kind, accentColor: page.accentColor)
        accessibilityLabel = [page.step, page.title, page.subtitle].joined(separator: ". ")
        applyAccessibilityLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }
        applyAccessibilityLayout()
    }

    private func applyAccessibilityLayout() {
        let shouldPrioritizeCopy: Bool
        switch traitCollection.preferredContentSizeCategory {
        case .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            shouldPrioritizeCopy = true
        default:
            shouldPrioritizeCopy = false
        }

        artwork.isHidden = shouldPrioritizeCopy
        scrollView.alwaysBounceVertical = shouldPrioritizeCopy
    }
}

private final class WalkthroughArtworkView: UIView {
    private let content = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(kind: WalkthroughPage.Kind, accentColor: UIColor) {
        content.subviews.forEach { $0.removeFromSuperview() }
        content.backgroundColor = TFColor.Surface.card
        content.layer.cornerRadius = TFRadius.xl
        content.layer.cornerCurve = .continuous
        content.layer.borderWidth = 1 / UIScreen.main.scale
        content.layer.borderColor = TFColor.Border.subtle.cgColor
        content.clipsToBounds = true

        let heroImage = UIImageView(image: UIImage(named: kind.editorialHeroName))
        heroImage.contentMode = .scaleAspectFill
        heroImage.clipsToBounds = true
        content.addSubview(heroImage)
        heroImage.snp.makeConstraints { $0.edges.equalToSuperview() }

        let caption = UIView()
        caption.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.94)
        caption.layer.cornerRadius = 14
        caption.layer.cornerCurve = .continuous

        let accent = UIView()
        accent.backgroundColor = accentColor
        accent.layer.cornerRadius = 2

        let pictogram = UIImageView(image: UIImage(systemName: kind.symbolName))
        pictogram.contentMode = .scaleAspectFit
        pictogram.tintColor = accentColor

        let tag = UILabel()
        tag.text = kind.tag
        tag.font = TFTypography.caption.withSize(11)
        tag.textColor = TFColor.Text.primary

        let captionStack = UIStackView(arrangedSubviews: [accent, pictogram, tag])
        captionStack.axis = .horizontal
        captionStack.alignment = .center
        captionStack.spacing = 9
        caption.addSubview(captionStack)
        captionStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 14))
        }
        accent.snp.makeConstraints { make in
            make.width.equalTo(4)
            make.height.equalTo(28)
        }
        pictogram.snp.makeConstraints { $0.size.equalTo(28) }

        content.addSubview(caption)
        caption.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview().inset(14)
        }

        let number = InsetLabel(insets: UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10))
        number.text = kind.serial
        number.font = TFTypography.caption.withSize(11)
        number.textColor = TFColor.Text.primary
        number.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.92)
        number.layer.cornerRadius = 13
        number.layer.cornerCurve = .continuous
        number.clipsToBounds = true
        content.addSubview(number)
        number.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(14)
        }
    }
}

private extension WalkthroughPage.Kind {
    var serial: String {
        switch self {
        case .journey: "01"
        case .wardrobe: "02"
        case .outfits: "03"
        case .trips: "04"
        }
    }

    var editorialHeroName: String {
        switch self {
        case .journey: "TFDestinationTokyoV2"
        case .wardrobe: "TFWardrobeEditorialV2"
        case .outfits: "TFOutfitEditorialV2"
        case .trips: "TFPackingEditorialV2"
        }
    }

    var symbolName: String {
        switch self {
        case .journey: "airplane.departure"
        case .wardrobe: "square.grid.3x3.fill"
        case .outfits: "sparkles.rectangle.stack.fill"
        case .trips: "suitcase.rolling.fill"
        }
    }

    var tag: String {
        switch self {
        case .journey: CoreStrings.Onboarding.Walkthrough.tagNextJourney
        case .wardrobe: CoreStrings.Onboarding.Walkthrough.tagWardrobe
        case .outfits: CoreStrings.Onboarding.Walkthrough.tagOutfits
        case .trips: CoreStrings.Onboarding.Walkthrough.tagTogether
        }
    }
}

private final class WalkthroughProgressView: UIView {
    var numberOfPages = 0 {
        didSet { rebuild() }
    }

    private let countLabel = UILabel()
    private let stack = UIStackView()
    private var segments: [UIView] = []
    private var currentPage = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        countLabel.font = TFTypography.caption.withSize(11)
        countLabel.textColor = TFColor.Text.secondary
        countLabel.setContentHuggingPriority(.required, for: .horizontal)

        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually

        addSubview(countLabel)
        addSubview(stack)
        countLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(40)
        }
        stack.snp.makeConstraints { make in
            make.leading.equalTo(countLabel.snp.trailing).offset(12)
            make.trailing.centerY.equalToSuperview()
            make.height.equalTo(3)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCurrentPage(_ page: Int, animated: Bool) {
        currentPage = max(0, min(numberOfPages - 1, page))
        let update = {
            self.countLabel.text = String(format: "%02d / %02d", self.currentPage + 1, self.numberOfPages)
            for (index, segment) in self.segments.enumerated() {
                segment.backgroundColor = index <= self.currentPage
                    ? TFColor.Brand.primary
                    : TFColor.Border.strong
            }
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: update)
        } else {
            update()
        }
    }

    private func rebuild() {
        segments.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        segments = (0..<numberOfPages).map { _ in
            let view = UIView()
            view.layer.cornerRadius = 1.5
            stack.addArrangedSubview(view)
            return view
        }
        setCurrentPage(currentPage, animated: false)
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
