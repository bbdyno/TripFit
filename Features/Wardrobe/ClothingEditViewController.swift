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
    private let context: ModelContext
    private var editingItem: ClothingItem?
    private var selectedImageData: Data?
    private var selectedImageURL: String?
    private var selectedCategory: ClothingCategory = .tops
    private var selectedSeason: Season?
    private var imageLoadToken: UUID?
    private var imageLoadRequestID = UUID()

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let imageButton = UIButton(type: .system)
    private let nameField = UITextField()
    private let categoryPicker = UIButton(type: .system)
    private let seasonPicker = UIButton(type: .system)
    private let colorField = UITextField()
    private let noteField = UITextField()

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
        title = editingItem == nil ? "New Item" : "Edit Item"
        view.backgroundColor = TFColor.Surface.canvas
        setupNav()
        setupForm()
        populateIfEditing()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .save,
            primaryAction: UIAction { [weak self] _ in self?.save() }
        )

        if editingItem != nil {
            let deleteButton = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                primaryAction: UIAction { [weak self] _ in self?.deleteItem() }
            )
            deleteButton.tintColor = .systemRed
            navigationItem.rightBarButtonItems = [
                navigationItem.rightBarButtonItem!, deleteButton
            ]
        }
    }

    private func setupForm() {
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        stackView.axis = .vertical
        stackView.spacing = TFSpacing.md
        stackView.layoutMargins = UIEdgeInsets(top: TFSpacing.md, left: TFSpacing.md, bottom: TFSpacing.md, right: TFSpacing.md)
        stackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        // Image
        imageButton.setImage(UIImage(systemName: "photo.badge.plus"), for: .normal)
        imageButton.tintColor = TFColor.Brand.primary
        imageButton.backgroundColor = TFColor.Surface.input
        imageButton.layer.cornerRadius = TFRadius.lg
        imageButton.layer.borderWidth = 2
        imageButton.layer.borderColor = TFColor.Brand.primary.withAlphaComponent(0.22).cgColor
        imageButton.clipsToBounds = true
        imageButton.addTarget(self, action: #selector(pickPhoto), for: .touchUpInside)
        stackView.addArrangedSubview(imageButton)
        imageButton.snp.makeConstraints { $0.height.equalTo(220) }

        // Name
        stackView.addArrangedSubview(makeFieldCard(title: "Name *", field: nameField, placeholder: "Item name"))

        // Category
        categoryPicker.setTitle("Category: Tops", for: .normal)
        categoryPicker.setTitleColor(TFColor.textPrimary, for: .normal)
        categoryPicker.contentHorizontalAlignment = .leading
        categoryPicker.showsMenuAsPrimaryAction = true
        categoryPicker.menu = makeCategoryMenu()
        stackView.addArrangedSubview(makeCard(title: "Category *", content: categoryPicker))

        // Season
        seasonPicker.setTitle("Season: None", for: .normal)
        seasonPicker.setTitleColor(TFColor.textPrimary, for: .normal)
        seasonPicker.contentHorizontalAlignment = .leading
        seasonPicker.showsMenuAsPrimaryAction = true
        seasonPicker.menu = makeSeasonMenu()
        stackView.addArrangedSubview(makeCard(title: "Season", content: seasonPicker))

        // Color
        stackView.addArrangedSubview(makeFieldCard(title: "Color", field: colorField, placeholder: "e.g. Blue"))

        // Note
        stackView.addArrangedSubview(makeFieldCard(title: "Note", field: noteField, placeholder: "Optional note"))
    }

    private func makeFieldCard(title: String, field: UITextField, placeholder: String) -> UIView {
        field.placeholder = placeholder
        field.font = TFTypography.body
        field.textColor = TFColor.Text.primary
        field.borderStyle = .none
        return makeCard(title: title, content: field)
    }

    private func makeCard(title: String, content: UIView) -> UIView {
        TFFormFieldCard(title: title, content: content, style: .flat)
    }

    private func makeCategoryMenu() -> UIMenu {
        let actions = ClothingCategory.allCases.map { cat in
            UIAction(title: cat.displayName, state: cat == selectedCategory ? .on : .off) { [weak self] _ in
                self?.selectedCategory = cat
                self?.categoryPicker.setTitle("Category: \(cat.displayName)", for: .normal)
                self?.categoryPicker.menu = self?.makeCategoryMenu()
            }
        }
        return UIMenu(children: actions)
    }

    private func makeSeasonMenu() -> UIMenu {
        var actions: [UIAction] = [
            UIAction(title: "None", state: selectedSeason == nil ? .on : .off) { [weak self] _ in
                self?.selectedSeason = nil
                self?.seasonPicker.setTitle("Season: None", for: .normal)
                self?.seasonPicker.menu = self?.makeSeasonMenu()
            }
        ]
        actions += Season.allCases.map { season in
            UIAction(
                title: season.displayName,
                state: season == selectedSeason ? .on : .off
            ) { [weak self] _ in
                self?.selectedSeason = season
                self?.seasonPicker.setTitle("Season: \(season.displayName)", for: .normal)
                self?.seasonPicker.menu = self?.makeSeasonMenu()
            }
        }
        return UIMenu(children: actions)
    }

    private func populateIfEditing() {
        guard let item = editingItem else { return }
        nameField.text = item.name
        selectedCategory = item.category
        categoryPicker.setTitle("Category: \(item.category.displayName)", for: .normal)
        selectedSeason = item.season
        seasonPicker.setTitle("Season: \(item.season?.displayName ?? "None")", for: .normal)
        colorField.text = item.color
        noteField.text = item.note
        selectedImageData = item.imageData
        selectedImageURL = item.imageURL

        if let data = item.imageData, let image = UIImage(data: data) {
            showSelectedImage(image)
        } else {
            loadImageFromURLIfNeeded()
        }

        categoryPicker.menu = makeCategoryMenu()
        seasonPicker.menu = makeSeasonMenu()
    }

    @objc private func pickPhoto() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func save() {
        guard let name = nameField.text, !name.isEmpty else {
            showAlert("Please enter a name")
            return
        }

        let imageData: Data? = selectedImageData.flatMap { ImageDownsampler.downsample($0) } ?? selectedImageData

        if let item = editingItem {
            item.name = name
            item.category = selectedCategory
            item.season = selectedSeason
            item.color = colorField.text?.isEmpty == true ? nil : colorField.text
            item.note = noteField.text?.isEmpty == true ? nil : noteField.text
            item.imageData = imageData
            item.imageURL = selectedImageURL
            item.updatedAt = Date()
        } else {
            let item = ClothingItem(
                name: name,
                category: selectedCategory,
                color: colorField.text?.isEmpty == true ? nil : colorField.text,
                season: selectedSeason,
                note: noteField.text?.isEmpty == true ? nil : noteField.text,
                imageData: imageData,
                imageURL: selectedImageURL
            )
            context.insert(item)
        }

        try? context.save()
        dismiss(animated: true)
    }

    private func deleteItem() {
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

    private func showSelectedImage(_ image: UIImage) {
        imageButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        imageButton.imageView?.contentMode = .scaleAspectFill
        imageButton.tintColor = nil
    }

    private func showImagePlaceholder() {
        imageButton.setImage(UIImage(systemName: "photo.badge.plus"), for: .normal)
        imageButton.imageView?.contentMode = .scaleAspectFit
        imageButton.tintColor = TFColor.Brand.primary
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
}

extension ClothingEditViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let uiImage = image as? UIImage else { return }
            DispatchQueue.main.async {
                self?.selectedImageURL = nil
                self?.selectedImageData = uiImage.jpegData(compressionQuality: 0.9)
                self?.showSelectedImage(uiImage)
            }
        }
    }
}
