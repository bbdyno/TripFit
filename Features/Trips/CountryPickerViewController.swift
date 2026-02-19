//
//  CountryPickerViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import SnapKit
import UIKit

public final class CountryPickerViewController: UIViewController {
    public var onSelect: ((String, String) -> Void)?

    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView(frame: .zero, style: .plain)

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
        view.backgroundColor = TFColor.Surface.canvas
        filtered = countries

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        let searchField = searchController.searchBar.searchTextField
        searchField.backgroundColor = TFColor.Surface.input
        searchField.font = TFTypography.bodyRegular
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search country or code",
            attributes: [
                .font: TFTypography.bodyRegular,
                .foregroundColor: TFColor.Text.tertiary,
            ]
        )
        navigationItem.searchController = searchController

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
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
        var content = cell.defaultContentConfiguration()
        content.text = country.name
        content.secondaryText = country.code
        content.textProperties.font = TFTypography.body
        content.secondaryTextProperties.font = TFTypography.footnote
        content.secondaryTextProperties.color = TFColor.Text.secondary
        cell.contentConfiguration = content
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        let cardTag = 9001
        let card: TFCardView
        if let existing = cell.contentView.viewWithTag(cardTag) as? TFCardView {
            card = existing
        } else {
            card = TFCardView(style: .flat)
            card.tag = cardTag
            cell.contentView.insertSubview(card, at: 0)
            card.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
            }
        }
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
