//
//  TripDetailViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class TripDetailViewController: UIViewController {
    private let context: ModelContext
    private let trip: Trip

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerStack = UIStackView()

    public init(context: ModelContext, trip: Trip) {
        self.context = context
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = trip.name
        view.backgroundColor = TFColor.Surface.canvas
        setupNavBar()
        setupTableView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        rebuildHeader()
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                primaryAction: UIAction { [weak self] _ in self?.addPackingItem() }
            ),
            UIBarButtonItem(
                systemItem: .edit,
                primaryAction: UIAction { [weak self] _ in self?.editTrip() }
            ),
        ]
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = TFColor.Brand.primary }
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 74
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PackingItemCell.self, forCellReuseIdentifier: PackingItemCell.reuseId)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        rebuildHeader()
    }

    private func rebuildHeader() {
        headerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        headerStack.axis = .vertical
        headerStack.spacing = TFSpacing.md
        headerStack.layoutMargins = UIEdgeInsets(top: TFSpacing.xs, left: TFSpacing.md, bottom: TFSpacing.xs, right: TFSpacing.md)
        headerStack.isLayoutMarginsRelativeArrangement = true

        // Trip info card
        let infoCard = TFCardView(style: .elevated)
        let nameLabel = UILabel()
        nameLabel.text = trip.name
        nameLabel.font = TFTypography.title
        nameLabel.textColor = TFColor.Text.primary

        let dateLabel = UILabel()
        dateLabel.text = TFDateFormatter.tripRange(start: trip.startDate, end: trip.endDate)
        dateLabel.font = TFTypography.caption
        dateLabel.textColor = TFColor.Text.secondary

        let progressLabel = UILabel()
        progressLabel.font = TFTypography.headline
        progressLabel.textColor = TFColor.Brand.accentMint
        progressLabel.text = "Packed: \(trip.progressText)"

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, dateLabel, progressLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoCard.addSubview(infoStack)
        infoStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        headerStack.addArrangedSubview(infoCard)

        // Destination Essentials card
        if let code = trip.destinationCountryCode,
           let essentials = CountryEssentialsService.shared.essentials(for: code) {
            let essCard = TFCardView(style: .elevated)

            let essTitle = UILabel()
            essTitle.text = "Destination Essentials"
            essTitle.font = TFTypography.headline
            essTitle.textColor = TFColor.Text.primary

            let countryLabel = UILabel()
            countryLabel.text = essentials.countryName
            countryLabel.font = TFTypography.body
            countryLabel.textColor = TFColor.Brand.accentSky

            let voltageLabel = UILabel()
            voltageLabel.text = "Voltage: \(essentials.voltageText)"
            voltageLabel.font = TFTypography.bodyRegular
            voltageLabel.textColor = TFColor.Text.secondary

            let freqLabel = UILabel()
            freqLabel.text = "Frequency: \(essentials.frequencyText)"
            freqLabel.font = TFTypography.bodyRegular
            freqLabel.textColor = TFColor.Text.secondary

            let plugLabel = UILabel()
            plugLabel.text = "Plug Types: \(essentials.plugTypes.joined(separator: ", "))"
            plugLabel.font = TFTypography.bodyRegular
            plugLabel.textColor = TFColor.Text.secondary

            let addButton = TFSecondaryButton(title: "Add recommended items")
            addButton.addTarget(self, action: #selector(addRecommendedItems), for: .touchUpInside)

            let essStack = UIStackView(
                arrangedSubviews: [essTitle, countryLabel, voltageLabel, freqLabel, plugLabel, addButton]
            )
            essStack.axis = .vertical
            essStack.spacing = 6
            essStack.setCustomSpacing(12, after: plugLabel)
            essCard.addSubview(essStack)
            essStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
            headerStack.addArrangedSubview(essCard)
        }

        // Size the header
        headerStack.setNeedsLayout()
        headerStack.layoutIfNeeded()
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = headerStack.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        headerStack.frame = CGRect(origin: .zero, size: size)
        tableView.tableHeaderView = headerStack
    }

    @objc private func addRecommendedItems() {
        let existingNames = Set(trip.packingItems.compactMap(\.customName))
        var addedCount = 0

        for itemName in CountryEssentialsService.recommendedPackingItems where !existingNames.contains(itemName) {
            let packing = PackingItem(trip: trip, customName: itemName)
            context.insert(packing)
            addedCount += 1
        }

        // Add note item
        let noteName = CountryEssentialsService.recommendedNote
        if !existingNames.contains(noteName) {
            let noteItem = PackingItem(trip: trip, customName: noteName)
            context.insert(noteItem)
            addedCount += 1
        }

        try? context.save()

        if addedCount > 0 {
            tableView.reloadData()
            rebuildHeader()
        }

        let message = addedCount > 0 ? "Added \(addedCount) items" : "All items already in list"
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func editTrip() {
        let editVC = TripEditViewController(context: context, editingTrip: trip)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func addPackingItem() {
        let alert = UIAlertController(title: "Add Packing Item", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "From Wardrobe", style: .default) { [weak self] _ in
            self?.addFromWardrobe()
        })
        alert.addAction(UIAlertAction(title: "Custom Item", style: .default) { [weak self] _ in
            self?.addCustomItem()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func addFromWardrobe() {
        let selectVC = ItemSelectViewController(context: context, selectedItems: [])
        selectVC.onDone = { [weak self] items in
            guard let self else { return }
            for item in items {
                let existing = self.trip.packingItems.contains { $0.clothingItem?.id == item.id }
                if !existing {
                    let packing = PackingItem(trip: self.trip, clothingItem: item)
                    self.context.insert(packing)
                }
            }
            try? self.context.save()
            self.tableView.reloadData()
            self.rebuildHeader()
        }
        let nav = UINavigationController(rootViewController: selectVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func addCustomItem() {
        let alert = UIAlertController(title: "Custom Item", message: "Enter item name", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Item name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let packing = PackingItem(trip: self.trip, customName: name)
            self.context.insert(packing)
            try? self.context.save()
            self.tableView.reloadData()
            self.rebuildHeader()
        })
        present(alert, animated: true)
    }
}

extension TripDetailViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trip.packingItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PackingItemCell.reuseId, for: indexPath
        ) as! PackingItemCell
        let item = trip.packingItems[indexPath.row]
        cell.configure(with: item) { [weak self] in
            self?.tableView.reloadData()
            self?.rebuildHeader()
        }
        return cell
    }

    public func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = trip.packingItems[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.context.delete(item)
            try? self?.context.save()
            self?.tableView.reloadData()
            self?.rebuildHeader()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        nil
    }
}
