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

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let nameField = UITextField()
    private let noteField = UITextField()
    private let selectButton = TFSecondaryButton(title: "Select Items")
    private let selectedItemsStack = UIStackView()

    public init(context: ModelContext, editingOutfit: Outfit? = nil) {
        self.context = context
        self.editingOutfit = editingOutfit
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = editingOutfit == nil ? "New Outfit" : "Edit Outfit"
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

        nameField.placeholder = "Outfit name"
        nameField.font = TFTypography.body
        nameField.textColor = TFColor.Text.primary
        stackView.addArrangedSubview(TFFormFieldCard(title: "Name *", content: nameField, style: .flat))

        noteField.placeholder = "Optional note"
        noteField.font = TFTypography.bodyRegular
        noteField.textColor = TFColor.Text.primary
        stackView.addArrangedSubview(TFFormFieldCard(title: "Note", content: noteField, style: .flat))

        selectButton.addTarget(self, action: #selector(selectItemsTapped), for: .touchUpInside)
        stackView.addArrangedSubview(selectButton)

        let selectedTitle = UILabel()
        selectedTitle.text = "Selected Items"
        selectedTitle.font = TFTypography.caption
        selectedTitle.textColor = TFColor.Text.secondary
        stackView.addArrangedSubview(selectedTitle)

        selectedItemsStack.axis = .horizontal
        selectedItemsStack.spacing = TFSpacing.xs
        let itemsScroll = UIScrollView()
        itemsScroll.showsHorizontalScrollIndicator = false
        itemsScroll.addSubview(selectedItemsStack)
        selectedItemsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        stackView.addArrangedSubview(itemsScroll)
        itemsScroll.snp.makeConstraints { $0.height.equalTo(64) }
    }

    private func populateIfEditing() {
        guard let outfit = editingOutfit else { return }
        nameField.text = outfit.name
        noteField.text = outfit.note
        selectedItems = outfit.items
        updateSelectedItemsDisplay()
    }

    @objc private func selectItemsTapped() {
        let selectVC = ItemSelectViewController(context: context, selectedItems: selectedItems)
        selectVC.onDone = { [weak self] items in
            self?.selectedItems = items
            self?.updateSelectedItemsDisplay()
        }
        let nav = UINavigationController(rootViewController: selectVC)
        present(nav, animated: true)
    }

    private func updateSelectedItemsDisplay() {
        selectedItemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in selectedItems {
            let chip = TFChip(title: item.name)
            chip.setAccentColor(item.category.tintColor)
            chip.isChipSelected = true
            selectedItemsStack.addArrangedSubview(chip)
        }
        selectButton.setTitle("Select Items (\(selectedItems.count))", for: .normal)
    }

    private func save() {
        guard let name = nameField.text, !name.isEmpty else {
            let alert = UIAlertController(title: nil, message: "Please enter a name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        if let outfit = editingOutfit {
            outfit.name = name
            outfit.note = noteField.text?.isEmpty == true ? nil : noteField.text
            outfit.items = selectedItems
            outfit.updatedAt = Date()
        } else {
            let outfit = Outfit(
                name: name,
                note: noteField.text?.isEmpty == true ? nil : noteField.text,
                items: selectedItems
            )
            context.insert(outfit)
        }
        try? context.save()
        dismiss(animated: true)
    }
}
