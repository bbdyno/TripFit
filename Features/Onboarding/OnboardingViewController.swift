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
        nextButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)

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
            self.nextButton.backgroundColor = isLast ? TFColor.Brand.primaryDark : TFColor.Brand.primary
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
        let korean = TFAppLanguage.current() == .korean
        return [
            WalkthroughPage(
                kind: .wardrobe,
                step: korean ? "옷장  ·  01" : "WARDROBE  ·  01",
                title: korean ? "내 옷장을\n한눈에." : "Your closet,\nin one view.",
                subtitle: korean
                    ? "사진 한 장으로 옷을 정리하고, 계절과 색상으로 필요한 순간 바로 찾아보세요."
                    : "Save each piece once, then find what fits the season, color, and moment.",
                accentColor: TFColor.Brand.primary
            ),
            WalkthroughPage(
                kind: .outfits,
                step: korean ? "코디  ·  02" : "OUTFITS  ·  02",
                title: korean ? "고민 대신\n저장해 둔 코디." : "Looks ready\nwhen you are.",
                subtitle: korean
                    ? "내 옷으로 만든 조합을 룩처럼 저장하고, 오늘 입을 옷을 더 빠르게 결정하세요."
                    : "Turn pieces you own into looks you can revisit whenever plans come up.",
                accentColor: TFColor.Brand.accentSky
            ),
            WalkthroughPage(
                kind: .trips,
                step: korean ? "함께 여행  ·  03" : "TRIPS TOGETHER  ·  03",
                title: korean ? "여행 준비는\n함께, 더 가볍게." : "Plan together.\nPack lighter.",
                subtitle: korean
                    ? "가능한 날짜를 맞추고 준비물과 여행 룩까지, 초대받은 사람끼리 함께 준비하세요."
                    : "Match dates, share packing, and plan trip looks with the people you invite.",
                accentColor: TFColor.Brand.accentMint
            ),
        ]
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean ? korean : english
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
        stack.spacing = 16
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView.contentLayoutGuide).inset(8)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(TFSpacing.xl)
            make.width.equalTo(scrollView.frameLayoutGuide).inset(TFSpacing.xl)
        }

        artwork.layer.cornerRadius = TFRadius.hero
        artwork.layer.cornerCurve = .continuous
        artwork.clipsToBounds = true
        stack.addArrangedSubview(artwork)
        artwork.snp.makeConstraints { make in
            make.height.equalTo(318).priority(.high)
            make.height.greaterThanOrEqualTo(260)
        }
        stack.setCustomSpacing(24, after: artwork)

        stepLabel.font = TFTypography.caption.withSize(12)
        stepLabel.textColor = TFColor.Brand.primary
        stepLabel.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(stepLabel)

        titleLabel.font = TFTypography.display
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.addArrangedSubview(titleLabel)

        subtitleLabel.font = TFTypography.bodyRegular.withSize(17)
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
        backgroundColor = TFColor.Surface.hero
        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(kind: WalkthroughPage.Kind, accentColor: UIColor) {
        content.subviews.forEach { $0.removeFromSuperview() }
        layer.sublayers?.filter { $0.name == "accent" }.forEach { $0.removeFromSuperlayer() }

        let glow = CAGradientLayer()
        glow.name = "accent"
        glow.colors = [accentColor.withAlphaComponent(0.48).cgColor, UIColor.clear.cgColor]
        glow.startPoint = CGPoint(x: 0.05, y: 0.05)
        glow.endPoint = CGPoint(x: 0.72, y: 0.75)
        glow.frame = bounds.isEmpty ? CGRect(x: 0, y: 0, width: 420, height: 340) : bounds
        layer.insertSublayer(glow, at: 0)

        switch kind {
        case .wardrobe:
            makeWardrobe(accentColor: accentColor)
        case .outfits:
            makeOutfits(accentColor: accentColor)
        case .trips:
            makeTrips(accentColor: accentColor)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first(where: { $0.name == "accent" })?.frame = bounds
    }

    private func makeWardrobe(accentColor: UIColor) {
        let number = makeOversizedNumber("01")
        content.addSubview(number)
        number.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-20)
            make.trailing.equalToSuperview().offset(10)
        }

        let rail = UIView()
        rail.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        content.addSubview(rail)
        rail.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.top.equalToSuperview().offset(68)
            make.height.equalTo(2)
        }

        let garments = UIStackView()
        garments.axis = .horizontal
        garments.alignment = .fill
        garments.distribution = .fillEqually
        garments.spacing = 12
        content.addSubview(garments)
        garments.snp.makeConstraints { make in
            make.top.equalTo(rail.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(32)
            make.height.equalTo(150)
        }

        let items = [
            ("tshirt.fill", UIColor(hex: 0xF9D4E3), "LINEN"),
            ("jacket.fill", UIColor(hex: 0xB8D9EA), "DENIM"),
            ("shoe.2.fill", UIColor(hex: 0xCDE7D9), "TRAVEL"),
        ]
        for (index, item) in items.enumerated() {
            let tile = ArtworkTile(icon: item.0, tint: item.1, caption: item.2)
            tile.transform = CGAffineTransform(rotationAngle: CGFloat(index - 1) * 0.025)
            garments.addArrangedSubview(tile)
        }

        let tag = makeTag(title: localized("24개 아이템", "24 PIECES"), color: accentColor)
        content.addSubview(tag)
        tag.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.bottom.equalToSuperview().inset(24)
        }
    }

    private func makeOutfits(accentColor: UIColor) {
        let number = makeOversizedNumber("02")
        content.addSubview(number)
        number.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-20)
            make.trailing.equalToSuperview().offset(10)
        }

        let board = UIView()
        board.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        board.layer.cornerRadius = 22
        board.layer.cornerCurve = .continuous
        board.transform = CGAffineTransform(rotationAngle: -0.035)
        content.addSubview(board)
        board.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.trailing.equalToSuperview().inset(54)
            make.top.equalToSuperview().offset(38)
            make.bottom.equalToSuperview().inset(30)
        }

        let label = UILabel()
        label.text = "LOOK 07"
        label.font = TFTypography.caption.withSize(11)
        label.textColor = UIColor(hex: 0x20262B)
        board.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(18)
        }

        let date = UILabel()
        date.text = localized("일요일 브런치", "SUNDAY BRUNCH")
        date.font = TFTypography.footnote.withSize(10)
        date.textColor = UIColor(hex: 0x62686D)
        board.addSubview(date)
        date.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(3)
            make.leading.equalTo(label)
        }

        let collage = UIStackView()
        collage.axis = .horizontal
        collage.distribution = .fillEqually
        collage.spacing = 10
        board.addSubview(collage)
        collage.snp.makeConstraints { make in
            make.top.equalTo(date.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview().inset(18)
        }
        collage.addArrangedSubview(ArtworkTile(icon: "tshirt.fill", tint: UIColor(hex: 0xF2C7D9), caption: "TOP"))
        collage.addArrangedSubview(ArtworkTile(icon: "shoe.2.fill", tint: UIColor(hex: 0xBFDDEB), caption: "SHOES"))

        let tag = makeTag(title: localized("저장된 코디", "SAVED LOOK"), color: accentColor)
        content.addSubview(tag)
        tag.transform = CGAffineTransform(rotationAngle: 0.055)
        tag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(18)
        }
    }

    private func makeTrips(accentColor: UIColor) {
        let number = makeOversizedNumber("03")
        content.addSubview(number)
        number.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-20)
            make.trailing.equalToSuperview().offset(10)
        }

        let ticket = UIView()
        ticket.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        ticket.layer.cornerRadius = 24
        ticket.layer.cornerCurve = .continuous
        content.addSubview(ticket)
        ticket.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(30)
            make.top.equalToSuperview().offset(42)
            make.height.equalTo(190)
        }

        let route = UILabel()
        route.text = "SEOUL   →   TOKYO"
        route.font = TFTypography.headline.withSize(17)
        route.textColor = UIColor(hex: 0x20262B)
        ticket.addSubview(route)
        route.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(20)
        }

        let date = UILabel()
        date.text = localized("8월 18–21일  ·  3박 4일", "AUG 18–21  ·  4 DAYS")
        date.font = TFTypography.footnote.withSize(11)
        date.textColor = UIColor(hex: 0x62686D)
        ticket.addSubview(date)
        date.snp.makeConstraints { make in
            make.top.equalTo(route.snp.bottom).offset(6)
            make.leading.equalTo(route)
        }

        let divider = UIView()
        divider.backgroundColor = UIColor(hex: 0xD7D0CA)
        ticket.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.top.equalTo(date.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }

        let members = UIStackView()
        members.axis = .horizontal
        members.spacing = -7
        ticket.addSubview(members)
        members.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().inset(20)
        }
        ["person.fill", "person.fill", "person.fill"].enumerated().forEach { index, symbol in
            let avatar = UIImageView(image: UIImage(systemName: symbol))
            avatar.backgroundColor = [UIColor(hex: 0xF2C7D9), UIColor(hex: 0xBFDDEB), UIColor(hex: 0xCDE7D9)][index]
            avatar.tintColor = UIColor(hex: 0x20262B)
            avatar.contentMode = .center
            avatar.layer.cornerRadius = 17
            avatar.layer.borderWidth = 2
            avatar.layer.borderColor = UIColor.white.cgColor
            avatar.clipsToBounds = true
            avatar.snp.makeConstraints { $0.size.equalTo(34) }
            members.addArrangedSubview(avatar)
        }

        let progress = UILabel()
        progress.text = localized("준비물  8 / 12", "PACKED  8 / 12")
        progress.font = TFTypography.caption.withSize(11)
        progress.textColor = UIColor(hex: 0x20262B)
        ticket.addSubview(progress)
        progress.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(20)
        }

        let tag = makeTag(title: localized("3명이 함께", "3 TRAVELERS"), color: accentColor)
        content.addSubview(tag)
        tag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    private func makeOversizedNumber(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = TFTypography.display.withSize(96)
        label.textColor = UIColor.white.withAlphaComponent(0.08)
        return label
    }

    private func makeTag(title: String, color: UIColor) -> UILabel {
        let label = InsetLabel(insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        label.text = title
        label.font = TFTypography.caption.withSize(10)
        label.textColor = .white
        label.backgroundColor = color
        label.layer.cornerRadius = 14
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true
        return label
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean ? korean : english
    }
}

private final class ArtworkTile: UIView {
    init(icon: String, tint: UIColor, caption: String) {
        super.init(frame: .zero)
        backgroundColor = tint
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = UIColor(hex: 0x20262B)
        image.contentMode = .scaleAspectFit
        image.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 38, weight: .medium)
        addSubview(image)
        image.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.size.lessThanOrEqualTo(54)
        }

        let label = UILabel()
        label.text = caption
        label.font = TFTypography.footnote.withSize(9)
        label.textColor = UIColor(hex: 0x20262B).withAlphaComponent(0.72)
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(10)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
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
