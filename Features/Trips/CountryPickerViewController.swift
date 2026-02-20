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
    private var destinationOptions: [TFDestinationInfo] = TFDestinationCatalog.all.sorted {
        if $0.countryName == $1.countryName {
            return $0.cityName < $1.cityName
        }
        return $0.countryName < $1.countryName
    }
    private var filtered: [TFDestinationInfo] = []
    private let allCountryFilterTitle = "All Countries"
    private var selectedCountryCode: String?
    private var clockTimer: Timer?
    private lazy var countries: [(code: String, name: String)] = {
        Dictionary(grouping: destinationOptions, by: \.countryCode)
            .compactMap { key, value in
                guard let name = value.first?.countryName else { return nil }
                return (code: key, name: name)
            }
            .sorted { $0.name < $1.name }
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Destination"
        view.backgroundColor = TFColor.Surface.canvas
        filtered = destinationOptions

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Country",
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            menu: makeCountryFilterMenu()
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        let searchField = searchController.searchBar.searchTextField
        searchField.backgroundColor = TFColor.Surface.input
        searchField.font = TFTypography.bodyRegular
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search country, city or code",
            attributes: [
                .font: TFTypography.bodyRegular,
                .foregroundColor: TFColor.Text.tertiary,
            ]
        )
        navigationItem.searchController = searchController
        updateFilterSummary()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 100
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        tableView.register(DestinationOptionCell.self, forCellReuseIdentifier: DestinationOptionCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        applyFilters()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startClockTimer()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopClockTimer()
    }

    deinit {
        stopClockTimer()
    }

    private func startClockTimer() {
        guard clockTimer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateVisibleCellTimes()
        }
        clockTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        updateVisibleCellTimes()
    }

    private func stopClockTimer() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func updateVisibleCellTimes() {
        let now = Date()
        for case let cell as DestinationOptionCell in tableView.visibleCells {
            cell.updateTime(at: now)
        }
    }

    private func applyFilters() {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        filtered = destinationOptions.filter { destination in
            let matchesCountry = selectedCountryCode.map {
                destination.countryCode.caseInsensitiveCompare($0) == .orderedSame
            } ?? true
            guard matchesCountry else { return false }
            guard !query.isEmpty else { return true }

            return destination.countryName.lowercased().contains(query)
                || destination.cityName.lowercased().contains(query)
                || destination.countryCode.lowercased().contains(query)
        }

        tableView.reloadData()
        updateVisibleCellTimes()
    }

    private func makeCountryFilterMenu() -> UIMenu {
        var actions: [UIAction] = []

        let allAction = UIAction(
            title: allCountryFilterTitle,
            state: selectedCountryCode == nil ? .on : .off
        ) { [weak self] _ in
            self?.selectedCountryCode = nil
            self?.updateCountryFilterMenu()
            self?.applyFilters()
        }
        actions.append(allAction)

        actions += countries.map { country in
            UIAction(
                title: "\(country.name) (\(country.code))",
                state: selectedCountryCode == country.code ? .on : .off
            ) { [weak self] _ in
                self?.selectedCountryCode = country.code
                self?.updateCountryFilterMenu()
                self?.applyFilters()
            }
        }

        return UIMenu(title: "Filter by Country", children: actions)
    }

    private func updateCountryFilterMenu() {
        navigationItem.rightBarButtonItem?.menu = makeCountryFilterMenu()
        updateFilterSummary()
    }

    private func updateFilterSummary() {
        let filterName = selectedCountryCode.flatMap { code in
            countries.first(where: { $0.code == code })?.name
        } ?? allCountryFilterTitle
        searchController.searchBar.prompt = "Country Filter: \(filterName)"
    }
}

extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DestinationOptionCell.reuseID,
            for: indexPath
        ) as! DestinationOptionCell
        cell.configure(with: filtered[indexPath.row], now: Date())
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = filtered[indexPath.row]
        onSelect?(destination.countryCode, destination.displayName)
        dismiss(animated: true)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
}

extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        applyFilters()
    }
}

private final class DestinationOptionCell: UITableViewCell {
    static let reuseID = "DestinationOptionCell"

    private let card = TFCardView(style: .flat)
    private let cityLabel = UILabel()
    private let countryLabel = UILabel()
    private let metaLabel = UILabel()
    private let currentCaptionLabel = UILabel()
    private let timeLabel = UILabel()
    private var destination: TFDestinationInfo?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cityLabel.font = TFTypography.body.withSize(17)
        cityLabel.textColor = TFColor.Text.primary

        countryLabel.font = TFTypography.bodyRegular.withSize(13)
        countryLabel.textColor = TFColor.Text.secondary

        metaLabel.font = TFTypography.footnote.withSize(12)
        metaLabel.textColor = TFColor.Text.tertiary

        currentCaptionLabel.font = TFTypography.footnote.withSize(11)
        currentCaptionLabel.textColor = TFColor.Text.tertiary
        currentCaptionLabel.textAlignment = .right
        currentCaptionLabel.text = "Current Time"
        currentCaptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        timeLabel.textColor = TFColor.Brand.primary
        timeLabel.textAlignment = .right
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(card)
        card.addSubview(cityLabel)
        card.addSubview(countryLabel)
        card.addSubview(metaLabel)
        card.addSubview(currentCaptionLabel)
        card.addSubview(timeLabel)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        cityLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.top.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(currentCaptionLabel.snp.leading).offset(-12)
        }
        countryLabel.snp.makeConstraints { make in
            make.leading.equalTo(cityLabel)
            make.top.equalTo(cityLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(currentCaptionLabel.snp.leading).offset(-12)
        }
        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(cityLabel)
            make.top.equalTo(countryLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(currentCaptionLabel.snp.leading).offset(-12)
            make.bottom.equalToSuperview().inset(12)
        }
        currentCaptionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().inset(14)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.top.equalTo(currentCaptionLabel.snp.bottom).offset(2)
            make.leading.greaterThanOrEqualTo(cityLabel.snp.trailing).offset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with destination: TFDestinationInfo, now: Date) {
        self.destination = destination
        cityLabel.text = destination.cityName
        countryLabel.text = destination.countryName
        updateTime(at: now)
    }

    func updateTime(at date: Date) {
        guard let destination else { return }
        let gmt = TFDestinationCatalog.gmtOffsetString(for: destination.timeZoneIdentifier, at: date) ?? "GMT"
        let delta = TFDestinationCatalog.localDeltaString(for: destination.timeZoneIdentifier, at: date) ?? "Local"
        let localTime = TFDestinationCatalog.locationTimeString(
            for: destination.timeZoneIdentifier,
            at: date,
            includeSeconds: false
        ) ?? "--:--"

        metaLabel.text = "\(destination.countryCode) • \(gmt) • \(delta)"
        timeLabel.text = localTime
    }
}
