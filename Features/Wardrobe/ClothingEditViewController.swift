//
//  ClothingEditViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import PhotosUI
import SnapKit
import SwiftData
import UIKit

public final class ClothingEditViewController: UIViewController {
    private struct ColorOption {
        let name: String
        let color: UIColor
    }

    private static let colorOptions: [ColorOption] = [
        ColorOption(name: "Pink", color: UIColor(hex: 0xFF5CA3)),
        ColorOption(name: "Sky", color: UIColor(hex: 0xA2D2FF)),
        ColorOption(name: "Lavender", color: UIColor(hex: 0xCDB4DB)),
        ColorOption(name: "Black", color: UIColor(hex: 0x181014)),
        ColorOption(name: "White", color: UIColor(hex: 0xFFFFFF)),
        ColorOption(name: "Cream", color: UIColor(hex: 0xFFE5B4)),
    ]

    private static let seasonOptions: [Season] = [.spring, .summer, .fall, .winter, .all]

    private let context: ModelContext
    private var editingItem: ClothingItem?
    private var selectedImageData: Data?
    private var selectedImageURL: String?
    private var selectedCategory: ClothingCategory = .tops
    private var selectedSeason: Season = .all
    private var selectedColorName: String? = colorOptions.first?.name
    private var imageLoadToken: UUID?
    private var imageLoadRequestID = UUID()

    private let headerContainer = UIView()
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let headerDivider = UIView()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let photoButton = UIButton(type: .system)
    private let photoPreviewView = UIImageView()
    private let photoPlaceholderStack = UIStackView()
    private let photoIcon = UIImageView(image: UIImage(systemName: "camera.badge.plus"))
    private let photoHintLabel = UILabel()
    private let photoTypeBadge = UILabel()
    private let photoBorderLayer = CAShapeLayer()

    private let nameField = UITextField()
    private let categoryButton = UIButton(type: .system)
    private var colorButtons: [UIButton] = []
    private let colorScrollView = UIScrollView()
    private let colorStack = UIStackView()
    private var seasonButtons: [UIButton] = []
    private let seasonStack = UIStackView()
    private let noteTextView = UITextView()
    private let notePlaceholderLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let bottomBar = UIView()
    private let saveButton = TFPrimaryButton(title: "Save Item")

    public init(context: ModelContext, editingItem: ClothingItem? = nil) {
        self.context = context
        self.editingItem = editingItem
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        TFRemoteImageLoader.shared.cancel(imageLoadToken)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupLayout()
        setupActions()
        populateIfEditing()
        refreshCategoryButtonTitle()
        refreshColorButtons()
        refreshSeasonButtons()
        refreshNotePlaceholder()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomFadeLayer.frame = bottomFadeView.bounds
        photoBorderLayer.frame = photoButton.bounds
        photoBorderLayer.path = UIBezierPath(
            roundedRect: photoButton.bounds,
            cornerRadius: TFRadius.xl
        ).cgPath
    }

    private func setupLayout() {
        setupHeader()
        setupBottomBar()
        setupScrollContent()
    }

    private func setupHeader() {
        headerContainer.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.96)
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(TFColor.Brand.primary, for: .normal)
        cancelButton.titleLabel?.font = TFTypography.body
        headerContainer.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(TFSpacing.md)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().inset(10)
        }

        titleLabel.text = editingItem == nil ? "Add Item" : "Edit Item"
        titleLabel.font = TFTypography.headline
        titleLabel.textColor = TFColor.Text.primary
        headerContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(cancelButton)
        }

        headerDivider.backgroundColor = TFColor.Border.subtle
        headerContainer.addSubview(headerDivider)
        headerDivider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.98)
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        bottomFadeView.isUserInteractionEnabled = false
        view.addSubview(bottomFadeView)
        bottomFadeView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
            make.height.equalTo(34)
        }

        bottomFadeLayer.colors = [
            TFColor.Surface.card.withAlphaComponent(0).cgColor,
            TFColor.Surface.card.withAlphaComponent(0.92).cgColor,
        ]
        bottomFadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomFadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
        bottomFadeView.layer.addSublayer(bottomFadeLayer)

        bottomBar.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.bottom.equalTo(bottomBar.safeAreaLayoutGuide.snp.bottom).inset(8)
        }

        saveButton.setTitle(editingItem == nil ? "Save Item" : "Save Changes", for: .normal)
    }

    private func setupScrollContent() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }

        contentStack.axis = .vertical
        contentStack.spacing = TFSpacing.md
        contentStack.layoutMargins = UIEdgeInsets(
            top: TFSpacing.md,
            left: TFSpacing.md,
            bottom: TFSpacing.xl,
            right: TFSpacing.md
        )
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        setupPhotoSection()
        setupNameSection()
        setupCategorySection()
        setupColorSection()
        setupSeasonSection()
        setupNotesSection()
        setupDeleteSection()
    }

    private func setupPhotoSection() {
        photoButton.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.08)
        photoButton.layer.cornerRadius = TFRadius.xl
        photoButton.clipsToBounds = true
        photoButton.layer.addSublayer(photoBorderLayer)

        photoBorderLayer.fillColor = UIColor.clear.cgColor
        photoBorderLayer.strokeColor = TFColor.Brand.primary.withAlphaComponent(0.35).cgColor
        photoBorderLayer.lineWidth = 2.5
        photoBorderLayer.lineDashPattern = [8, 5]

        contentStack.addArrangedSubview(photoButton)
        photoButton.snp.makeConstraints { make in
            make.height.equalTo(photoButton.snp.width).multipliedBy(0.75)
        }

        photoPreviewView.contentMode = .scaleAspectFill
        photoPreviewView.clipsToBounds = true
        photoPreviewView.isHidden = true
        photoButton.addSubview(photoPreviewView)
        photoPreviewView.snp.makeConstraints { $0.edges.equalToSuperview() }

        photoIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .regular)
        photoIcon.tintColor = TFColor.Brand.primary

        photoHintLabel.text = "Tap to add photo"
        photoHintLabel.font = TFTypography.caption
        photoHintLabel.textColor = TFColor.Brand.primary

        photoPlaceholderStack.axis = .vertical
        photoPlaceholderStack.alignment = .center
        photoPlaceholderStack.spacing = TFSpacing.xs
        photoPlaceholderStack.addArrangedSubview(photoIcon)
        photoPlaceholderStack.addArrangedSubview(photoHintLabel)
        photoButton.addSubview(photoPlaceholderStack)
        photoPlaceholderStack.snp.makeConstraints { $0.center.equalToSuperview() }

        photoTypeBadge.text = "JPG, PNG"
        photoTypeBadge.font = TFTypography.footnote.withSize(11)
        photoTypeBadge.textColor = TFColor.Text.secondary
        photoTypeBadge.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.84)
        photoTypeBadge.layer.cornerRadius = 8
        photoTypeBadge.layer.masksToBounds = true
        photoTypeBadge.textAlignment = .center
        photoButton.addSubview(photoTypeBadge)
        photoTypeBadge.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(10)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(66)
        }
    }

    private func setupNameSection() {
        contentStack.addArrangedSubview(makeSectionLabel("Item Name"))

        let container = makeInputContainer()
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(52) }

        nameField.placeholder = "e.g. Vintage Denim Jacket"
        nameField.font = TFTypography.bodyRegular
        nameField.textColor = TFColor.Text.primary
        nameField.returnKeyType = .done
        nameField.delegate = self
        container.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }

    private func setupCategorySection() {
        contentStack.addArrangedSubview(makeSectionLabel("Category"))

        let container = makeInputContainer()
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(52) }

        categoryButton.setTitleColor(TFColor.Text.primary, for: .normal)
        categoryButton.titleLabel?.font = TFTypography.bodyRegular
        categoryButton.tintColor = TFColor.Brand.primary
        categoryButton.contentHorizontalAlignment = .leading
        categoryButton.showsMenuAsPrimaryAction = true
        categoryButton.semanticContentAttribute = .forceRightToLeft
        categoryButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        categoryButton.menu = makeCategoryMenu()
        container.addSubview(categoryButton)
        categoryButton.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14))
        }
    }

    private func setupColorSection() {
        contentStack.addArrangedSubview(makeSectionLabel("Color"))

        colorScrollView.showsHorizontalScrollIndicator = false
        colorScrollView.contentInsetAdjustmentBehavior = .never
        contentStack.addArrangedSubview(colorScrollView)
        colorScrollView.snp.makeConstraints { $0.height.equalTo(52) }

        colorStack.axis = .horizontal
        colorStack.spacing = 10
        colorScrollView.addSubview(colorStack)
        colorStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        for (index, option) in Self.colorOptions.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.backgroundColor = option.color
            button.layer.cornerRadius = 22
            button.clipsToBounds = true

            let checkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
            checkImageView.tag = 101
            checkImageView.tintColor = option.name == "White" ? TFColor.Text.primary : .white
            checkImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
            button.addSubview(checkImageView)
            checkImageView.snp.makeConstraints { $0.center.equalToSuperview() }

            button.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
            colorStack.addArrangedSubview(button)
            button.snp.makeConstraints { $0.size.equalTo(44) }
            colorButtons.append(button)
        }
    }

    private func setupSeasonSection() {
        contentStack.addArrangedSubview(makeSectionLabel("Season"))

        let container = makeInputContainer()
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(50) }

        seasonStack.axis = .horizontal
        seasonStack.spacing = 6
        seasonStack.distribution = .fillEqually
        container.addSubview(seasonStack)
        seasonStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        }

        for (index, season) in Self.seasonOptions.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.layer.cornerRadius = 10
            button.titleLabel?.font = TFTypography.footnote
            button.setTitle(shortSeasonLabel(for: season), for: .normal)
            button.addTarget(self, action: #selector(seasonTapped(_:)), for: .touchUpInside)
            seasonStack.addArrangedSubview(button)
            seasonButtons.append(button)
        }
    }

    private func setupNotesSection() {
        contentStack.addArrangedSubview(makeSectionLabel("Notes"))

        let container = makeInputContainer()
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(108) }

        noteTextView.font = TFTypography.bodyRegular
        noteTextView.textColor = TFColor.Text.primary
        noteTextView.backgroundColor = .clear
        noteTextView.delegate = self
        container.addSubview(noteTextView)
        noteTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }

        notePlaceholderLabel.text = "Dry clean only..."
        notePlaceholderLabel.font = TFTypography.bodyRegular
        notePlaceholderLabel.textColor = TFColor.Text.tertiary
        noteTextView.addSubview(notePlaceholderLabel)
        notePlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(5)
            make.top.equalToSuperview().inset(8)
        }
    }

    private func setupDeleteSection() {
        deleteButton.setTitle("Delete Item", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.titleLabel?.font = TFTypography.body
        deleteButton.isHidden = editingItem == nil
        contentStack.addArrangedSubview(deleteButton)
        deleteButton.snp.makeConstraints { $0.height.equalTo(44) }
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(pickPhoto), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    private func populateIfEditing() {
        guard let item = editingItem else { return }
        nameField.text = item.name
        selectedCategory = item.category
        selectedSeason = item.season ?? .all
        selectedColorName = item.color ?? selectedColorName
        noteTextView.text = item.note
        selectedImageData = item.imageData
        selectedImageURL = item.imageURL
        refreshCategoryButtonTitle()
        refreshColorButtons()
        refreshSeasonButtons()
        refreshNotePlaceholder()

        if let data = item.imageData, let image = UIImage(data: data) {
            showSelectedImage(image)
        } else {
            showImagePlaceholder()
            loadImageFromURLIfNeeded()
        }
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = TFTypography.caption
        label.textColor = TFColor.Text.secondary
        return label
    }

    private func makeInputContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = TFColor.Surface.input
        view.layer.cornerRadius = 12
        return view
    }

    private func makeCategoryMenu() -> UIMenu {
        let actions = ClothingCategory.allCases.map { category in
            UIAction(title: category.displayName, state: category == selectedCategory ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.selectedCategory = category
                self.refreshCategoryButtonTitle()
                self.categoryButton.menu = self.makeCategoryMenu()
            }
        }
        return UIMenu(children: actions)
    }

    private func refreshCategoryButtonTitle() {
        categoryButton.setTitle(selectedCategory.displayName, for: .normal)
    }

    private func shortSeasonLabel(for season: Season) -> String {
        switch season {
        case .spring: "Spr"
        case .summer: "Sum"
        case .fall: "Aut"
        case .winter: "Win"
        case .all: "All"
        }
    }

    private func refreshColorButtons() {
        for button in colorButtons {
            guard button.tag < Self.colorOptions.count else { continue }
            let option = Self.colorOptions[button.tag]
            let isSelected = option.name == selectedColorName

            if isSelected {
                button.layer.borderWidth = 2
                button.layer.borderColor = TFColor.Brand.primary.cgColor
            } else if option.name == "White" {
                button.layer.borderWidth = 1
                button.layer.borderColor = TFColor.Border.strong.cgColor
            } else {
                button.layer.borderWidth = 0
                button.layer.borderColor = nil
            }

            if let check = button.viewWithTag(101) as? UIImageView {
                check.isHidden = !isSelected
            }
        }
    }

    private func refreshSeasonButtons() {
        for button in seasonButtons {
            guard button.tag < Self.seasonOptions.count else { continue }
            let season = Self.seasonOptions[button.tag]
            let isSelected = season == selectedSeason
            button.backgroundColor = isSelected ? TFColor.Surface.card : .clear
            button.setTitleColor(isSelected ? TFColor.Brand.primary : TFColor.Text.secondary, for: .normal)
            button.layer.borderWidth = isSelected ? 1 : 0
            button.layer.borderColor = isSelected ? TFColor.Border.subtle.cgColor : UIColor.clear.cgColor
        }
    }

    private func refreshNotePlaceholder() {
        notePlaceholderLabel.isHidden = !(noteTextView.text?.isEmpty ?? true)
    }

    private func showSelectedImage(_ image: UIImage) {
        photoPreviewView.image = image
        photoPreviewView.isHidden = false
        photoPlaceholderStack.isHidden = true
        photoTypeBadge.isHidden = true
    }

    private func showImagePlaceholder() {
        photoPreviewView.image = nil
        photoPreviewView.isHidden = true
        photoPlaceholderStack.isHidden = false
        photoTypeBadge.isHidden = false
    }

    private func loadImageFromURLIfNeeded() {
        TFRemoteImageLoader.shared.cancel(imageLoadToken)
        imageLoadToken = nil

        guard selectedImageData == nil else { return }

        let requestID = UUID()
        imageLoadRequestID = requestID
        imageLoadToken = TFRemoteImageLoader.shared.load(from: selectedImageURL) { [weak self] image in
            guard let self, self.imageLoadRequestID == requestID else { return }
            if let image {
                self.showSelectedImage(image)
            } else {
                self.showImagePlaceholder()
            }
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func colorTapped(_ sender: UIButton) {
        guard sender.tag < Self.colorOptions.count else { return }
        selectedColorName = Self.colorOptions[sender.tag].name
        refreshColorButtons()
    }

    @objc private func seasonTapped(_ sender: UIButton) {
        guard sender.tag < Self.seasonOptions.count else { return }
        selectedSeason = Self.seasonOptions[sender.tag]
        refreshSeasonButtons()
    }

    @objc private func pickPhoto() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert("Please enter a name")
            return
        }

        let optimizedImageData = selectedImageData.flatMap { ImageDownsampler.downsample($0) } ?? selectedImageData
        let noteText = noteTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = noteText.isEmpty ? nil : noteText

        if let item = editingItem {
            item.name = name
            item.category = selectedCategory
            item.color = selectedColorName
            item.season = selectedSeason
            item.note = noteValue
            item.imageData = optimizedImageData
            item.imageURL = selectedImageURL
            item.updatedAt = Date()
        } else {
            let newItem = ClothingItem(
                name: name,
                category: selectedCategory,
                color: selectedColorName,
                season: selectedSeason,
                note: noteValue,
                imageData: optimizedImageData,
                imageURL: selectedImageURL
            )
            context.insert(newItem)
        }

        try? context.save()
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        guard let item = editingItem else { return }
        context.delete(item)
        try? context.save()
        dismiss(animated: true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ClothingEditViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let self, let uiImage = image as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedImageURL = nil
                self.selectedImageData = uiImage.jpegData(compressionQuality: 0.9)
                self.showSelectedImage(uiImage)
            }
        }
    }
}

extension ClothingEditViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ClothingEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        refreshNotePlaceholder()
    }
}
