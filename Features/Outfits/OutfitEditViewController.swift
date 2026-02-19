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
        view.backgroundColor = TFColor.pageBackground
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
        stackView.spacing = 16
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        let nameCard = TFCardView(showShadow: false)
        let nameTitle = UILabel()
        nameTitle.text = "Name *"
        nameTitle.font = .preferredFont(forTextStyle: .caption1)
        nameTitle.textColor = TFColor.textSecondary
        nameField.placeholder = "Outfit name"
        nameField.font = .preferredFont(forTextStyle: .body)
        nameCard.addSubview(nameTitle)
        nameCard.addSubview(nameField)
        nameTitle.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(12) }
        nameField.snp.makeConstraints { make in
            make.top.equalTo(nameTitle.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(32)
        }
        stackView.addArrangedSubview(nameCard)

        let noteCard = TFCardView(showShadow: false)
        let noteTitle = UILabel()
        noteTitle.text = "Note"
        noteTitle.font = .preferredFont(forTextStyle: .caption1)
        noteTitle.textColor = TFColor.textSecondary
        noteField.placeholder = "Optional note"
        noteField.font = .preferredFont(forTextStyle: .body)
        noteCard.addSubview(noteTitle)
        noteCard.addSubview(noteField)
        noteTitle.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(12) }
        noteField.snp.makeConstraints { make in
            make.top.equalTo(noteTitle.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(32)
        }
        stackView.addArrangedSubview(noteCard)

        selectButton.addTarget(self, action: #selector(selectItemsTapped), for: .touchUpInside)
        stackView.addArrangedSubview(selectButton)

        selectedItemsStack.axis = .horizontal
        selectedItemsStack.spacing = 8
        let itemsScroll = UIScrollView()
        itemsScroll.showsHorizontalScrollIndicator = false
        itemsScroll.addSubview(selectedItemsStack)
        selectedItemsStack.snp.makeConstraints { $0.edges.height.equalToSuperview() }
        stackView.addArrangedSubview(itemsScroll)
        itemsScroll.snp.makeConstraints { $0.height.equalTo(60) }
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
