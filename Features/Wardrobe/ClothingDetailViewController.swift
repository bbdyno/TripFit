//
//  ClothingDetailViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class ClothingDetailViewController: UIViewController {
    private let context: ModelContext
    private let item: ClothingItem

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let heroContainer = UIView()
    private let heroImageView = UIImageView()
    private let titleCard = TFCardView(style: .elevated)
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let updatedLabel = UILabel()
    private let noteTextLabel = UILabel()
    private let statsStack = UIStackView()
    private let attributesStack = UIStackView()

    private let backButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let favoriteButton = UIButton(type: .system)
    private let bottomActionButton = UIButton(type: .system)

    private let heroGradientLayer = CAGradientLayer()
    private let bottomGradientLayer = CAGradientLayer()
    private var heroTopConstraint: Constraint?

    private var imageToken: UUID?
    private var imageRequestID = UUID()

    public init(context: ModelContext, item: ClothingItem) {
        self.context = context
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        TFRemoteImageLoader.shared.cancel(imageToken)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupUI()
        configureContent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        configureContent()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradientLayer.frame = heroContainer.bounds
        let gradientHeight: CGFloat = 220
        bottomGradientLayer.frame = CGRect(
            x: 0,
            y: view.bounds.height - gradientHeight,
            width: view.bounds.width,
            height: gradientHeight
        )
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        heroTopConstraint?.update(offset: view.safeAreaInsets.top)
        scrollView.verticalScrollIndicatorInsets.top = view.safeAreaInsets.top
        scrollView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom + 88
    }

    private func setupUI() {
        setupScrollContainer()
        setupHero()
        setupTitleCard()
        setupSections()
        setupBottomAction()
    }

    private func setupScrollContainer() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func setupHero() {
        contentView.addSubview(heroContainer)
        heroContainer.clipsToBounds = true
        heroContainer.layer.cornerRadius = TFRadius.xl
        heroContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        heroContainer.snp.makeConstraints { make in
            heroTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(0.45)
            make.height.greaterThanOrEqualTo(330)
            make.height.lessThanOrEqualTo(420)
        }

        heroImageView.backgroundColor = TFColor.Surface.input
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroContainer.addSubview(heroImageView)
        heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        heroGradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.34).cgColor,
            UIColor.clear.cgColor,
        ]
        heroGradientLayer.locations = [0, 0.35]
        heroContainer.layer.addSublayer(heroGradientLayer)

        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.titleLabel?.font = TFTypography.headline
        editButton.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        editButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        editButton.layer.cornerRadius = 18
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        heroContainer.addSubview(backButton)
        heroContainer.addSubview(editButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.size.equalTo(40)
        }
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(backButton)
            make.height.equalTo(36)
        }
    }

    private func setupTitleCard() {
        titleCard.layer.cornerRadius = 16

        categoryLabel.font = TFTypography.caption
        categoryLabel.textColor = TFColor.Brand.primary

        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 2

        updatedLabel.font = TFTypography.footnote
        updatedLabel.textColor = TFColor.Text.secondary

        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.tintColor = TFColor.Text.tertiary

        contentView.addSubview(titleCard)
        titleCard.snp.makeConstraints { make in
            make.top.equalTo(heroContainer.snp.bottom).offset(-32)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        titleCard.addSubview(categoryLabel)
        titleCard.addSubview(titleLabel)
        titleCard.addSubview(updatedLabel)
        titleCard.addSubview(favoriteButton)

        categoryLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(18)
        }
        favoriteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(30)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(18)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-12)
        }
        updatedLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.bottom.equalToSuperview().inset(18)
        }
    }

    private func setupSections() {
        let attributesTitle = makeSectionTitle("Attributes")
        let notesTitle = makeSectionTitle("Notes")

        attributesStack.axis = .horizontal
        attributesStack.spacing = 10
        attributesStack.alignment = .leading

        let notesCard = TFCardView(style: .flat)
        notesCard.addSubview(noteTextLabel)
        noteTextLabel.font = TFTypography.bodyRegular
        noteTextLabel.textColor = TFColor.Text.secondary
        noteTextLabel.numberOfLines = 0
        noteTextLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }

        statsStack.axis = .horizontal
        statsStack.spacing = 10
        statsStack.distribution = .fillEqually

        let contentStack = UIStackView(arrangedSubviews: [
            attributesTitle,
            attributesStack,
            notesTitle,
            notesCard,
            statsStack,
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 14

        contentView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(titleCard.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(140)
        }

        notesCard.snp.makeConstraints { $0.height.greaterThanOrEqualTo(84) }
    }

    private func setupBottomAction() {
        bottomGradientLayer.colors = [
            TFColor.Surface.card.withAlphaComponent(0).cgColor,
            TFColor.Surface.card.withAlphaComponent(0.85).cgColor,
            TFColor.Surface.card.cgColor,
        ]
        bottomGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        bottomGradientLayer.locations = [0, 0.55, 1]
        view.layer.addSublayer(bottomGradientLayer)

        var config = UIButton.Configuration.filled()
        var title = AttributedString("Add to Packing List")
        title.font = TFTypography.button
        config.attributedTitle = title
        config.image = UIImage(systemName: "suitcase.fill")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)
        config.imagePlacement = .leading
        config.imagePadding = 10
        config.baseBackgroundColor = TFColor.Brand.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)
        bottomActionButton.configuration = config
        bottomActionButton.addTarget(self, action: #selector(addToPackingTapped), for: .touchUpInside)

        view.addSubview(bottomActionButton)
        bottomActionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.height.equalTo(56)
        }
    }

    private func configureContent() {
        categoryLabel.text = item.category.displayName.uppercased()
        titleLabel.text = item.name
        updatedLabel.text = "Updated \(relativeString(for: item.updatedAt))"
        noteTextLabel.text = item.note?.isEmpty == false ? item.note : "No notes yet."

        refreshAttributes()
        refreshStats()
        loadImage()
    }

    private func refreshAttributes() {
        attributesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if let color = item.color, !color.isEmpty {
            attributesStack.addArrangedSubview(makeAttributeChip(text: color, tint: TFColor.Brand.primary))
        }

        if let season = item.season {
            attributesStack.addArrangedSubview(makeAttributeChip(text: season.displayName, tint: TFColor.Brand.accentOrange))
        }

        attributesStack.addArrangedSubview(makeAttributeChip(text: item.category.displayName, tint: item.category.tintColor))
    }

    private func refreshStats() {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let outfitsCount = outfitCount()
        let packingCount = packingCount()

        statsStack.addArrangedSubview(makeStatCard(title: "In Outfits", value: "\(outfitsCount)", tint: TFColor.Brand.primary))
        statsStack.addArrangedSubview(makeStatCard(title: "Packing Lists", value: "\(packingCount)", tint: TFColor.Brand.accentSky))
    }

    private func loadImage() {
        TFRemoteImageLoader.shared.cancel(imageToken)
        imageToken = nil
        imageRequestID = UUID()

        if let data = item.imageData, let image = UIImage(data: data) {
            heroImageView.image = image
            heroImageView.contentMode = .scaleAspectFill
            heroImageView.tintColor = nil
            return
        }

        heroImageView.image = UIImage(systemName: item.category.icon)
        heroImageView.contentMode = .scaleAspectFit
        heroImageView.tintColor = item.category.tintColor

        let requestID = imageRequestID
        imageToken = TFRemoteImageLoader.shared.load(from: item.imageURL) { [weak self] image in
            guard let self, self.imageRequestID == requestID, let image else { return }
            self.heroImageView.image = image
            self.heroImageView.contentMode = .scaleAspectFill
            self.heroImageView.tintColor = nil
        }
    }

    private func outfitCount() -> Int {
        let outfits = (try? context.fetch(FetchDescriptor<Outfit>())) ?? []
        return outfits.filter { outfit in
            outfit.items.contains(where: { $0.id == item.id })
        }.count
    }

    private func packingCount() -> Int {
        let items = (try? context.fetch(FetchDescriptor<PackingItem>())) ?? []
        return items.filter { $0.clothingItem?.id == item.id }.count
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func editTapped() {
        let editVC = ClothingEditViewController(context: context, editingItem: item)
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    @objc private func addToPackingTapped() {
        let trips = (try? context.fetch(FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)]))) ?? []
        guard !trips.isEmpty else {
            showAlert("Create a trip first to add this item to a packing list.")
            return
        }

        let sheet = UIAlertController(title: "Add to Packing List", message: nil, preferredStyle: .actionSheet)
        for trip in trips {
            sheet.addAction(UIAlertAction(title: trip.name, style: .default) { [weak self] _ in
                self?.addItem(to: trip)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func addItem(to trip: Trip) {
        let exists = trip.packingItems.contains { $0.clothingItem?.id == item.id }
        guard !exists else {
            showAlert("This item is already in \(trip.name).")
            return
        }

        context.insert(PackingItem(trip: trip, clothingItem: item))
        try? context.save()
        showAlert("Added to \(trip.name).")
    }
}

private extension ClothingDetailViewController {
    func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = TFTypography.headline
        label.textColor = TFColor.Text.primary
        label.text = text
        return label
    }

    func makeAttributeChip(text: String, tint: UIColor) -> UIView {
        let label = UILabel()
        label.font = TFTypography.caption
        label.textColor = tint
        label.text = "  \(text)  "

        let chip = UIView()
        chip.backgroundColor = tint.withAlphaComponent(0.14)
        chip.layer.cornerRadius = 10
        chip.layer.borderColor = tint.withAlphaComponent(0.3).cgColor
        chip.layer.borderWidth = 1
        chip.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)) }
        return chip
    }

    func makeStatCard(title: String, value: String, tint: UIColor) -> UIView {
        let card = TFCardView(style: .flat)
        let valueLabel = UILabel()
        valueLabel.font = TFTypography.title
        valueLabel.textColor = tint
        valueLabel.text = value
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.font = TFTypography.footnote
        titleLabel.textColor = TFColor.Text.secondary
        titleLabel.text = title
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        return card
    }

    func relativeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
