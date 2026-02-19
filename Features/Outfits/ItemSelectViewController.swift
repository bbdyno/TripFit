import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class ItemSelectViewController: UIViewController {
    private let context: ModelContext
    private var allItems: [ClothingItem] = []
    private var selectedItems: Set<UUID>

    public var onDone: (([ClothingItem]) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    public init(context: ModelContext, selectedItems: [ClothingItem]) {
        self.context = context
        self.selectedItems = Set(selectedItems.map(\.id))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Items"
        view.backgroundColor = TFColor.pageBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in self?.doneTapped() }
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        fetchItems()
    }

    private func fetchItems() {
        let descriptor = FetchDescriptor<ClothingItem>(sortBy: [SortDescriptor(\.name)])
        allItems = (try? context.fetch(descriptor)) ?? []
        tableView.reloadData()
    }

    private func doneTapped() {
        let selected = allItems.filter { selectedItems.contains($0.id) }
        onDone?(selected)
        dismiss(animated: true)
    }
}

extension ItemSelectViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = allItems[indexPath.row]
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.category.displayName
        cell.accessoryType = selectedItems.contains(item.id) ? .checkmark : .none
        cell.tintColor = TFColor.pink
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = allItems[indexPath.row]
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
