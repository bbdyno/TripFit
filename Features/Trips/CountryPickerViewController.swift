import Core
import SnapKit
import UIKit

public final class CountryPickerViewController: UIViewController {
    public var onSelect: ((String, String) -> Void)?

    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let countries: [(code: String, name: String)] = [
        ("US", "United States"), ("CA", "Canada"), ("JP", "Japan"), ("KR", "South Korea"),
        ("CN", "China"), ("TW", "Taiwan"), ("HK", "Hong Kong"), ("TH", "Thailand"),
        ("VN", "Vietnam"), ("SG", "Singapore"), ("ID", "Indonesia"), ("PH", "Philippines"),
        ("AU", "Australia"), ("NZ", "New Zealand"), ("IN", "India"), ("AE", "UAE"),
        ("SA", "Saudi Arabia"), ("TR", "Turkey"), ("MX", "Mexico"), ("BR", "Brazil"),
        ("AR", "Argentina"), ("CL", "Chile"), ("EG", "Egypt"), ("ZA", "South Africa"),
        ("MA", "Morocco"), ("KE", "Kenya"), ("GB", "United Kingdom"), ("FR", "France"),
        ("DE", "Germany"), ("IT", "Italy"), ("ES", "Spain"),
    ]
    private var filtered: [(code: String, name: String)] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Country"
        view.backgroundColor = TFColor.pageBackground
        filtered = countries

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let country = filtered[indexPath.row]
        cell.textLabel?.text = "\(country.name) (\(country.code))"
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = filtered[indexPath.row]
        onSelect?(country.code, country.name)
        dismiss(animated: true)
    }
}

extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        if query.isEmpty {
            filtered = countries
        } else {
            filtered = countries.filter {
                $0.name.lowercased().contains(query) || $0.code.lowercased().contains(query)
            }
        }
        tableView.reloadData()
    }
}
