//
//  OutfitEditViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class OutfitEditViewController: UIViewController {
    private let context: ModelContext
    private var editingOutfit: Outfit?
    private var selectedItems: [ClothingItem] = []
    private var imageLoadTokens: [UUID: UUID] = [:]

    private let headerContainer = UIView()
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let headerDivider = UIView()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let nameField = UITextField()
    private let noteTextView = UITextView()
    private let notePlaceholderLabel = UILabel()

    private let selectedCountLabel = UILabel()
    private let selectedItemsScrollView = UIScrollView()
    private let selectedItemsStack = UIStackView()

    private let selectItemsButton = UIButton(type: .system)
    private let pickerPanel = UIView()
    private let pickerHandle = UIView()
    private let pickerSearchContainer = UIView()
    private let pickerSearchField = UITextField()

    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let bottomBar = UIView()
    private let saveButton = UIButton(type: .system)
    private let saveButtonGradientLayer = CAGradientLayer()

    public init(context: ModelContext, editingOutfit: Outfit? = nil) {
        self.context = context
        self.editingOutfit = editingOutfit
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        for token in imageLoadTokens.values {
            TFRemoteImageLoader.shared.cancel(token)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupLayout()
        setupActions()
        populateIfEditing()
        refreshNotePlaceholder()
        refreshSelectedItems()
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
        saveButtonGradientLayer.frame = saveButton.bounds
    }

    private func setupLayout() {
        setupHeader()
        setupBottomBar()
        setupContent()
    }

    private func setupHeader() {
        headerContainer.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.95)
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(TFColor.Text.secondary, for: .normal)
        cancelButton.titleLabel?.font = TFTypography.body.withSize(17)
        headerContainer.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(TFSpacing.md)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.height.equalTo(34)
            make.bottom.equalToSuperview().inset(8)
        }

        titleLabel.text = editingOutfit == nil ? "Create Outfit" : "Edit Outfit"
        titleLabel.font = TFTypography.headline.withSize(17)
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
        bottomBar.backgroundColor = .clear
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        bottomFadeView.isUserInteractionEnabled = false
        view.addSubview(bottomFadeView)
        bottomFadeView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
            make.height.equalTo(56)
        }

        bottomFadeLayer.colors = [
            TFColor.Surface.card.withAlphaComponent(0).cgColor,
            TFColor.Surface.card.withAlphaComponent(0.9).cgColor,
            TFColor.Surface.card.cgColor,
        ]
        bottomFadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomFadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
        bottomFadeView.layer.addSublayer(bottomFadeLayer)

        saveButton.setTitle(editingOutfit == nil ? "Add selected (0)" : "Save Outfit", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = TFTypography.button.withSize(17)
        saveButton.layer.cornerRadius = 22
        saveButton.layer.masksToBounds = true
        saveButton.layer.insertSublayer(saveButtonGradientLayer, at: 0)
        saveButtonGradientLayer.colors = [UIColor(hex: 0x58C4FF).cgColor, UIColor(hex: 0x3AB0FF).cgColor]
        saveButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        saveButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        bottomBar.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.bottom.equalTo(bottomBar.safeAreaLayoutGuide.snp.bottom).inset(10)
            make.height.equalTo(56)
        }
    }

    private func setupContent() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }

        contentStack.axis = .vertical
        contentStack.spacing = TFSpacing.xl
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 120, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        setupNameSection()
        setupNotesSection()
        setupSelectedItemsSection()
        setupSelectItemsSection()
        setupPickerPanel()
    }

    private func setupNameSection() {
        contentStack.addArrangedSubview(makeSectionLabel("Name your look"))

        let container = makeInputContainer()
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(52) }

        nameField.font = TFTypography.bodyRegular.withSize(17)
        nameField.textColor = TFColor.Text.primary
        nameField.returnKeyType = .done
        nameField.delegate = self
        nameField.attributedPlaceholder = NSAttributedString(
            string: "e.g., Beach Day Vibes",
            attributes: [.foregroundColor: TFColor.Text.tertiary]
        )
        container.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().inset(44)
            make.centerY.equalToSuperview()
        }

        let iconView = UIImageView(
            image: TFMaterialIcon.image(named: "edit", pointSize: 18, weight: .medium)
                ?? UIImage(systemName: "pencil")
        )
        iconView.tintColor = TFColor.Brand.primary
        container.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(14)
            make.size.equalTo(18)
        }
    }

    private func setupNotesSection() {
        contentStack.addArrangedSubview(makeSectionLabel("Notes"))

        let container = makeInputContainer()
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(110) }

        noteTextView.font = TFTypography.bodyRegular.withSize(17)
        noteTextView.textColor = TFColor.Text.primary
        noteTextView.backgroundColor = .clear
        noteTextView.delegate = self
        container.addSubview(noteTextView)
        noteTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }

        notePlaceholderLabel.text = "Any accessories or occasion details..."
        notePlaceholderLabel.font = TFTypography.bodyRegular.withSize(17)
        notePlaceholderLabel.textColor = TFColor.Text.tertiary
        noteTextView.addSubview(notePlaceholderLabel)
        notePlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(5)
            make.top.equalToSuperview().inset(8)
        }
    }

    private func setupSelectedItemsSection() {
        let headerRow = UIView()
        contentStack.addArrangedSubview(headerRow)
        headerRow.snp.makeConstraints { $0.height.equalTo(24) }

        let selectedTitleLabel = UILabel()
        selectedTitleLabel.text = "Selected Items"
        selectedTitleLabel.font = TFTypography.subtitle.withSize(32)
        selectedTitleLabel.textColor = TFColor.Text.primary
        headerRow.addSubview(selectedTitleLabel)
        selectedTitleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        selectedCountLabel.font = TFTypography.body.withSize(16)
        selectedCountLabel.textColor = TFColor.Text.tertiary
        headerRow.addSubview(selectedCountLabel)
        selectedCountLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }

        selectedItemsScrollView.showsHorizontalScrollIndicator = false
        selectedItemsScrollView.contentInsetAdjustmentBehavior = .never
        contentStack.addArrangedSubview(selectedItemsScrollView)
        selectedItemsScrollView.snp.makeConstraints { $0.height.equalTo(122) }

        selectedItemsStack.axis = .horizontal
        selectedItemsStack.spacing = 12
        selectedItemsScrollView.addSubview(selectedItemsStack)
        selectedItemsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    private func setupSelectItemsSection() {
        selectItemsButton.backgroundColor = TFColor.Surface.card
        selectItemsButton.layer.cornerRadius = TFRadius.xl
        selectItemsButton.layer.shadowColor = UIColor.black.cgColor
        selectItemsButton.layer.shadowOpacity = 0.04
        selectItemsButton.layer.shadowRadius = 10
        selectItemsButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentStack.addArrangedSubview(selectItemsButton)
        selectItemsButton.snp.makeConstraints { $0.height.equalTo(88) }

        let iconBubble = UIView()
        iconBubble.backgroundColor = UIColor(hex: 0xEAF5FF)
        iconBubble.layer.cornerRadius = 22
        selectItemsButton.addSubview(iconBubble)
        iconBubble.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }

        let bubbleIcon = UIImageView(
            image: TFMaterialIcon.image(named: "styler", pointSize: 22, weight: .regular)
                ?? UIImage(systemName: "checkroom")
        )
        bubbleIcon.tintColor = UIColor(hex: 0x4BAAF6)
        iconBubble.addSubview(bubbleIcon)
        bubbleIcon.snp.makeConstraints { $0.center.equalToSuperview() }

        let title = UILabel()
        title.text = "Select Items"
        title.font = TFTypography.body.withSize(18)
        title.textColor = TFColor.Text.primary
        selectItemsButton.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalTo(iconBubble.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(20)
        }

        let subtitle = UILabel()
        subtitle.text = "Add from wardrobe"
        subtitle.font = TFTypography.bodyRegular.withSize(14)
        subtitle.textColor = TFColor.Text.secondary
        selectItemsButton.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(2)
        }

        let chevron = UIImageView(
            image: TFMaterialIcon.image(named: "chevron_right", pointSize: 20, weight: .regular)
                ?? UIImage(systemName: "chevron.right")
        )
        chevron.tintColor = TFColor.Text.tertiary
        selectItemsButton.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }

    private func setupPickerPanel() {
        pickerPanel.backgroundColor = TFColor.Surface.card
        pickerPanel.layer.cornerRadius = 28
        pickerPanel.layer.shadowColor = UIColor.black.cgColor
        pickerPanel.layer.shadowOpacity = 0.06
        pickerPanel.layer.shadowRadius = 14
        pickerPanel.layer.shadowOffset = CGSize(width: 0, height: -2)
        contentStack.addArrangedSubview(pickerPanel)
        pickerPanel.snp.makeConstraints { $0.height.equalTo(196) }

        pickerHandle.backgroundColor = TFColor.Border.strong
        pickerHandle.layer.cornerRadius = 2.5
        pickerPanel.addSubview(pickerHandle)
        pickerHandle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 5))
        }

        let panelTitle = UILabel()
        panelTitle.text = "Add to Outfit"
        panelTitle.font = TFTypography.subtitle.withSize(32)
        panelTitle.textColor = TFColor.Text.primary
        pickerPanel.addSubview(panelTitle)
        panelTitle.snp.makeConstraints { make in
            make.top.equalTo(pickerHandle.snp.bottom).offset(18)
            make.leading.equalToSuperview().inset(18)
        }

        pickerSearchContainer.backgroundColor = TFColor.Surface.input
        pickerSearchContainer.layer.cornerRadius = 22
        pickerPanel.addSubview(pickerSearchContainer)
        pickerSearchContainer.snp.makeConstraints { make in
            make.top.equalTo(panelTitle.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(44)
        }

        let searchIcon = UIImageView(
            image: TFMaterialIcon.image(named: "search", pointSize: 18, weight: .regular)
                ?? UIImage(systemName: "magnifyingglass")
        )
        searchIcon.tintColor = TFColor.Text.tertiary
        pickerSearchContainer.addSubview(searchIcon)
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        pickerSearchField.font = TFTypography.bodyRegular.withSize(16)
        pickerSearchField.textColor = TFColor.Text.secondary
        pickerSearchField.isUserInteractionEnabled = false
        pickerSearchField.attributedPlaceholder = NSAttributedString(
            string: "Search wardrobe...",
            attributes: [.foregroundColor: TFColor.Text.tertiary]
        )
        pickerSearchContainer.addSubview(pickerSearchField)
        pickerSearchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }

        let openOverlayButton = UIButton(type: .custom)
        openOverlayButton.backgroundColor = .clear
        pickerPanel.addSubview(openOverlayButton)
        openOverlayButton.snp.makeConstraints { make in
            make.top.equalTo(panelTitle.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        openOverlayButton.addTarget(self, action: #selector(selectItemsTapped), for: .touchUpInside)
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = TFTypography.body.withSize(16)
        label.textColor = TFColor.Text.primary
        return label
    }

    private func makeInputContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = TFColor.Surface.input
        view.layer.cornerRadius = 22
        return view
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        selectItemsButton.addTarget(self, action: #selector(selectItemsTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func populateIfEditing() {
        guard let outfit = editingOutfit else { return }
        nameField.text = outfit.name
        noteTextView.text = outfit.note
        selectedItems = outfit.items
        titleLabel.text = "Edit Outfit"
        saveButton.setTitle("Save Outfit", for: .normal)
    }

    private func refreshSelectedItems() {
        cancelImageLoads()
        selectedItemsStack.arrangedSubviews.forEach {
            selectedItemsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let count = selectedItems.count
        selectedCountLabel.text = "\(count) items"
        let bottomTitle = editingOutfit == nil ? "Add selected (\(count))" : "Save Outfit"
        saveButton.setTitle(bottomTitle, for: .normal)

        guard !selectedItems.isEmpty else {
            let empty = UILabel()
            empty.text = "No items selected yet"
            empty.font = TFTypography.bodyRegular.withSize(14)
            empty.textColor = TFColor.Text.tertiary
            empty.textAlignment = .left
            selectedItemsStack.addArrangedSubview(empty)
            empty.snp.makeConstraints { make in
                make.width.equalTo(200)
            }
            return
        }

        for item in selectedItems {
            let itemView = makeSelectedItemView(item)
            selectedItemsStack.addArrangedSubview(itemView)
        }
    }

    private func makeSelectedItemView(_ item: ClothingItem) -> UIView {
        let wrapper = UIView()
        wrapper.snp.makeConstraints { make in
            make.width.equalTo(86)
        }

        let imageCard = UIView()
        imageCard.backgroundColor = TFColor.Surface.input
        imageCard.layer.cornerRadius = 18
        imageCard.layer.borderWidth = 1
        imageCard.layer.borderColor = TFColor.Brand.primary.withAlphaComponent(0.22).cgColor
        imageCard.clipsToBounds = true
        wrapper.addSubview(imageCard)
        imageCard.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(82)
        }

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageCard.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        if let data = item.imageData, let image = UIImage(data: data) {
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = TFColor.Text.tertiary
            if let token = TFRemoteImageLoader.shared.load(
                from: item.imageURL,
                completion: { [weak imageView] image in
                    guard let image else { return }
                    imageView?.image = image
                }
            ) {
                imageLoadTokens[item.id] = token
            }
        }

        let removeButton = UIButton(type: .system)
        removeButton.backgroundColor = TFColor.Brand.primary
        removeButton.tintColor = .white
        removeButton.layer.cornerRadius = 11
        removeButton.setImage(
            TFMaterialIcon.image(named: "close", pointSize: 14, weight: .bold)
                ?? UIImage(systemName: "xmark"),
            for: .normal
        )
        removeButton.addAction(UIAction { [weak self] _ in
            self?.removeSelectedItem(item.id)
        }, for: .touchUpInside)
        wrapper.addSubview(removeButton)
        removeButton.snp.makeConstraints { make in
            make.size.equalTo(22)
            make.top.equalToSuperview().offset(-6)
            make.trailing.equalToSuperview().offset(6)
        }

        let title = UILabel()
        title.text = item.name
        title.font = TFTypography.footnote.withSize(12)
        title.textColor = TFColor.Text.primary
        title.textAlignment = .center
        title.numberOfLines = 1
        wrapper.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(imageCard.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }

        return wrapper
    }

    private func cancelImageLoads() {
        for token in imageLoadTokens.values {
            TFRemoteImageLoader.shared.cancel(token)
        }
        imageLoadTokens.removeAll()
    }

    private func removeSelectedItem(_ id: UUID) {
        selectedItems.removeAll { $0.id == id }
        refreshSelectedItems()
    }

    @objc private func cancelTapped() {
        closeScreen()
    }

    @objc private func selectItemsTapped() {
        let selectVC = ItemSelectViewController(context: context, selectedItems: selectedItems)
        selectVC.onDone = { [weak self] items in
            self?.selectedItems = items
            self?.refreshSelectedItems()
        }
        let nav = UINavigationController(rootViewController: selectVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert("Please enter a name")
            return
        }
        guard !selectedItems.isEmpty else {
            showAlert("Please select at least one item")
            return
        }

        let noteText = noteTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = noteText.isEmpty ? nil : noteText

        if let outfit = editingOutfit {
            outfit.name = name
            outfit.note = noteValue
            outfit.items = selectedItems
            outfit.updatedAt = Date()
        } else {
            let outfit = Outfit(name: name, note: noteValue, items: selectedItems)
            context.insert(outfit)
        }

        try? context.save()
        closeScreen()
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CoreStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }

    private func refreshNotePlaceholder() {
        notePlaceholderLabel.isHidden = !(noteTextView.text?.isEmpty ?? true)
    }

    private func closeScreen() {
        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension OutfitEditViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension OutfitEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        refreshNotePlaceholder()
    }
}
