//
//  TripEditViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class TripEditViewController: UIViewController {
    private let context: ModelContext
    private var editingTrip: Trip?

    private var startDate = Date()
    private var endDate = Date()
    private var selectedDestinationName: String?
    private var selectedCountryCode: String?
    private var hasPickedDates = false

    private let headerContainer = UIView()
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let saveTopButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private weak var heroContainerView: UIView?
    private let heroGradientLayer = CAGradientLayer()

    private let nameField = UITextField()
    private let destinationValueLabel = UILabel()
    private let dateValueLabel = UILabel()
    private let dayCountBadgeLabel = UILabel()
    private let notesTextView = UITextView()
    private let notesPlaceholderLabel = UILabel()
    private let privacySwitch = UISwitch()

    private let bottomFadeView = UIView()
    private let bottomFadeLayer = CAGradientLayer()
    private let bottomBar = UIView()
    private let createButton = UIButton(type: .system)
    private let createButtonGradientLayer = CAGradientLayer()

    public init(context: ModelContext, editingTrip: Trip? = nil) {
        self.context = context
        self.editingTrip = editingTrip
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupLayout()
        setupActions()
        populateIfEditing()
        refreshDestinationUI()
        refreshDatesUI()
        refreshNotesPlaceholder()
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
        createButtonGradientLayer.frame = createButton.bounds
        heroGradientLayer.frame = heroContainerView?.bounds ?? .zero
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
            make.bottom.equalToSuperview().inset(8)
            make.height.equalTo(34)
        }

        titleLabel.text = editingTrip == nil ? "Add Trip" : "Edit Trip"
        titleLabel.font = TFTypography.headline.withSize(17)
        titleLabel.textColor = TFColor.Text.primary
        headerContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(cancelButton)
            make.centerX.equalToSuperview()
        }

        saveTopButton.setTitle("Save", for: .normal)
        saveTopButton.setTitleColor(TFColor.Brand.primary, for: .normal)
        saveTopButton.titleLabel?.font = TFTypography.body.withSize(17)
        headerContainer.addSubview(saveTopButton)
        saveTopButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(TFSpacing.md)
            make.centerY.equalTo(cancelButton)
            make.height.equalTo(34)
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

        createButton.setTitle(editingTrip == nil ? "Create Trip" : "Save Trip", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.titleLabel?.font = TFTypography.button.withSize(17)
        createButton.layer.cornerRadius = 22
        createButton.layer.masksToBounds = true
        createButton.layer.insertSublayer(createButtonGradientLayer, at: 0)
        createButtonGradientLayer.colors = [TFColor.Brand.primary.cgColor, UIColor(hex: 0xF9963B).cgColor]
        createButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        createButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        let arrow = TFMaterialIcon.image(named: "arrow_forward", pointSize: 18, weight: .medium)
            ?? UIImage(systemName: "arrow.right")
        createButton.setImage(arrow, for: .normal)
        createButton.semanticContentAttribute = .forceRightToLeft

        bottomBar.addSubview(createButton)
        createButton.snp.makeConstraints { make in
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
        contentStack.spacing = TFSpacing.lg
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 120, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        setupHeroSection()
        setupNameSection()
        setupDetailsSection()
        setupNotesSection()
        setupPrivacySection()
    }

    private func setupHeroSection() {
        let hero = UIView()
        heroContainerView = hero
        hero.layer.cornerRadius = TFRadius.xl
        hero.clipsToBounds = true
        contentStack.addArrangedSubview(hero)
        hero.snp.makeConstraints { $0.height.equalTo(96) }

        heroGradientLayer.colors = [TFColor.Brand.primary.withAlphaComponent(0.18).cgColor, UIColor(hex: 0xC49BFF, alpha: 0.2).cgColor]
        heroGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        heroGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        hero.layer.insertSublayer(heroGradientLayer, at: 0)

        let icon = UIImageView(
            image: TFMaterialIcon.image(named: "flight_takeoff", pointSize: 54, weight: .medium)
                ?? UIImage(systemName: "airplane.departure")
        )
        icon.tintColor = TFColor.Brand.primary.withAlphaComponent(0.65)
        hero.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    private func setupNameSection() {
        let nameLabel = UILabel()
        nameLabel.text = "Name your trip"
        nameLabel.font = TFTypography.title.withSize(34)
        nameLabel.textColor = TFColor.Text.primary
        contentStack.addArrangedSubview(nameLabel)

        let container = makeInputContainer(cornerRadius: 22)
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(52) }

        nameField.font = TFTypography.bodyRegular.withSize(17)
        nameField.textColor = TFColor.Text.primary
        nameField.attributedPlaceholder = NSAttributedString(
            string: "e.g., Paris Summer 2024",
            attributes: [.foregroundColor: TFColor.Text.tertiary]
        )
        nameField.returnKeyType = .done
        nameField.delegate = self
        container.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }

    private func setupDetailsSection() {
        let detailsTitle = UILabel()
        detailsTitle.text = "DETAILS"
        detailsTitle.font = TFTypography.caption.withSize(13)
        detailsTitle.textColor = TFColor.Text.secondary
        contentStack.addArrangedSubview(detailsTitle)

        let card = UIView()
        card.backgroundColor = TFColor.Surface.card
        card.layer.cornerRadius = TFRadius.xl
        contentStack.addArrangedSubview(card)

        let destinationRow = makeDetailsRow(
            icon: "location_on",
            iconBackground: TFColor.Brand.primary.withAlphaComponent(0.14),
            iconTint: TFColor.Brand.primary,
            title: "Destination",
            valueLabel: destinationValueLabel
        )
        destinationValueLabel.font = TFTypography.body.withSize(18)
        destinationValueLabel.adjustsFontSizeToFitWidth = true
        destinationValueLabel.minimumScaleFactor = 0.82
        destinationValueLabel.lineBreakMode = .byTruncatingTail
        card.addSubview(destinationRow)
        destinationRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(62)
        }
        destinationRow.addTarget(self, action: #selector(destinationTapped), for: .touchUpInside)

        let divider = UIView()
        divider.backgroundColor = TFColor.Border.subtle
        card.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.top.equalTo(destinationRow.snp.bottom).offset(2)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let datesRow = makeDetailsRow(
            icon: "calendar_month",
            iconBackground: UIColor(hex: 0xFFF0E1),
            iconTint: UIColor(hex: 0xF58431),
            title: "Dates",
            valueLabel: dateValueLabel
        )
        card.addSubview(datesRow)
        datesRow.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview().inset(10)
            make.height.equalTo(62)
        }
        datesRow.addTarget(self, action: #selector(datesTapped), for: .touchUpInside)

        dayCountBadgeLabel.font = TFTypography.footnote.withSize(12)
        dayCountBadgeLabel.textColor = TFColor.Text.secondary
        dayCountBadgeLabel.backgroundColor = TFColor.Surface.input
        dayCountBadgeLabel.layer.cornerRadius = 10
        dayCountBadgeLabel.layer.masksToBounds = true
        dayCountBadgeLabel.textAlignment = .center
        datesRow.addSubview(dayCountBadgeLabel)
        dayCountBadgeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(datesRow.snp.trailing).inset(30)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(60)
        }
    }

    private func makeDetailsRow(
        icon: String,
        iconBackground: UIColor,
        iconTint: UIColor,
        title: String,
        valueLabel: UILabel
    ) -> UIButton {
        let row = UIButton(type: .system)
        row.backgroundColor = .clear

        let iconContainer = UIView()
        iconContainer.backgroundColor = iconBackground
        iconContainer.layer.cornerRadius = 16
        row.addSubview(iconContainer)
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }

        let iconView = UIImageView(
            image: TFMaterialIcon.image(named: icon, pointSize: 18, weight: .regular)
                ?? UIImage(systemName: "circle.fill")
        )
        iconView.tintColor = iconTint
        iconContainer.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = TFTypography.footnote.withSize(14)
        titleLabel.textColor = TFColor.Text.secondary
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(10)
        }

        valueLabel.font = TFTypography.body.withSize(24)
        valueLabel.textColor = TFColor.Text.primary
        row.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(10)
        }

        let chevron = UIImageView(
            image: TFMaterialIcon.image(named: "chevron_right", pointSize: 18, weight: .regular)
                ?? UIImage(systemName: "chevron.right")
        )
        chevron.tintColor = TFColor.Text.tertiary
        row.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(2)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        return row
    }

    private func setupNotesSection() {
        let notesTitle = UILabel()
        notesTitle.text = "Notes & Goals"
        notesTitle.font = TFTypography.subtitle.withSize(30)
        notesTitle.textColor = TFColor.Text.primary
        contentStack.addArrangedSubview(notesTitle)

        let container = makeInputContainer(cornerRadius: TFRadius.xl)
        contentStack.addArrangedSubview(container)
        container.snp.makeConstraints { $0.height.equalTo(152) }

        notesTextView.font = TFTypography.bodyRegular.withSize(17)
        notesTextView.textColor = TFColor.Text.primary
        notesTextView.backgroundColor = .clear
        notesTextView.delegate = self
        container.addSubview(notesTextView)
        notesTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }

        notesPlaceholderLabel.text = "Dinner reservations, hiking gear, must-visit cafes..."
        notesPlaceholderLabel.font = TFTypography.bodyRegular.withSize(17)
        notesPlaceholderLabel.textColor = TFColor.Text.tertiary
        notesTextView.addSubview(notesPlaceholderLabel)
        notesPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(5)
            make.top.equalToSuperview().inset(8)
        }
    }

    private func setupPrivacySection() {
        let row = UIView()
        contentStack.addArrangedSubview(row)

        let title = UILabel()
        title.text = "Make Trip Private"
        title.font = TFTypography.body.withSize(18)
        title.textColor = TFColor.Text.primary
        row.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }

        let subtitle = UILabel()
        subtitle.text = "Only you can see this trip"
        subtitle.font = TFTypography.bodyRegular.withSize(16)
        subtitle.textColor = TFColor.Text.secondary
        row.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(title.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }

        row.addSubview(privacySwitch)
        privacySwitch.onTintColor = TFColor.Brand.primary
        privacySwitch.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
    }

    private func makeInputContainer(cornerRadius: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = TFColor.Surface.input
        view.layer.cornerRadius = cornerRadius
        return view
    }

    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveTopButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func populateIfEditing() {
        guard let trip = editingTrip else { return }
        nameField.text = trip.name
        startDate = trip.startDate
        endDate = trip.endDate
        selectedDestinationName = trip.destination
        selectedCountryCode = trip.destinationCountryCode
        notesTextView.text = trip.note
        hasPickedDates = true

        titleLabel.text = "Edit Trip"
        createButton.setTitle("Save Trip", for: .normal)
    }

    private func refreshDestinationUI() {
        if let destination = selectedDestinationName, !destination.isEmpty {
            destinationValueLabel.text = destination
        } else if let info = TFDestinationCatalog.info(forCountryCode: selectedCountryCode) {
            destinationValueLabel.text = info.displayName
        } else if let code = selectedCountryCode, !code.isEmpty {
            destinationValueLabel.text = code.uppercased()
        } else {
            destinationValueLabel.text = "Select location"
        }
    }

    private func refreshDatesUI() {
        if hasPickedDates {
            dateValueLabel.text = TFDateFormatter.tripRange(start: startDate, end: endDate)
            dayCountBadgeLabel.text = " \(tripDaysText(start: startDate, end: endDate)) "
        } else {
            dateValueLabel.text = "Start - End"
            dayCountBadgeLabel.text = " 0 Days "
        }
    }

    private func tripDaysText(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        let dayDiff = calendar.dateComponents([.day], from: s, to: e).day ?? 0
        let count = max(1, dayDiff + 1)
        return "\(count) Days"
    }

    @objc private func cancelTapped() {
        closeScreen()
    }

    @objc private func destinationTapped() {
        let actionSheet = UIAlertController(title: "Destination", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Choose Country & City", style: .default) { [weak self] _ in
            self?.openCountryPicker()
        })
        actionSheet.addAction(UIAlertAction(title: "Enter Manually", style: .default) { [weak self] _ in
            self?.presentManualDestinationInput()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(actionSheet, animated: true)
    }

    private func openCountryPicker() {
        let picker = CountryPickerViewController()
        picker.onSelect = { [weak self] code, name in
            self?.selectedCountryCode = code
            self?.selectedDestinationName = name
            self?.refreshDestinationUI()
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func presentManualDestinationInput() {
        let alert = UIAlertController(title: "Enter Destination", message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            textField.placeholder = "e.g., Tokyo, Japan"
            textField.text = self?.selectedDestinationName
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let destination = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            self?.selectedDestinationName = destination
            self?.selectedCountryCode = TFDestinationCatalog.info(matchingDestinationText: destination)?.countryCode
            self?.refreshDestinationUI()
        })
        present(alert, animated: true)
    }

    @objc private func datesTapped() {
        let picker = DateRangePickerViewController(startDate: startDate, endDate: endDate)
        picker.onApply = { [weak self] start, end in
            guard let self else { return }
            self.startDate = start
            self.endDate = max(start, end)
            self.hasPickedDates = true
            self.refreshDatesUI()
        }
        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert("Please enter a trip name")
            return
        }
        guard hasPickedDates else {
            showAlert("Please choose trip dates")
            return
        }

        let noteText = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = noteText.isEmpty ? nil : noteText
        let destinationValue = selectedDestinationName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let destination = destinationValue?.isEmpty == false ? destinationValue : nil

        if let trip = editingTrip {
            trip.name = name
            trip.startDate = startDate
            trip.endDate = max(startDate, endDate)
            trip.destination = destination
            trip.destinationCountryCode = selectedCountryCode
            trip.note = noteValue
            trip.updatedAt = Date()
        } else {
            let trip = Trip(
                name: name,
                startDate: startDate,
                endDate: max(startDate, endDate),
                destination: destination,
                destinationCountryCode: selectedCountryCode,
                note: noteValue
            )
            context.insert(trip)
        }

        try? context.save()
        closeScreen()
    }

    private func refreshNotesPlaceholder() {
        notesPlaceholderLabel.isHidden = !(notesTextView.text?.isEmpty ?? true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func closeScreen() {
        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension TripEditViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension TripEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        refreshNotesPlaceholder()
    }
}

private final class DateRangePickerViewController: UIViewController {
    var onApply: ((Date, Date) -> Void)?

    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let startDate: Date
    private let endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas

        let header = UIView()
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }

        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.setTitleColor(TFColor.Text.secondary, for: .normal)
        cancel.titleLabel?.font = TFTypography.body.withSize(16)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        header.addSubview(cancel)
        cancel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.setTitleColor(TFColor.Brand.primary, for: .normal)
        done.titleLabel?.font = TFTypography.body.withSize(16)
        done.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        header.addSubview(done)
        done.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        stack.addArrangedSubview(makePickerRow(title: "Start Date", picker: startDatePicker))
        stack.addArrangedSubview(makePickerRow(title: "End Date", picker: endDatePicker))

        [startDatePicker, endDatePicker].forEach { picker in
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .compact
            picker.tintColor = TFColor.Brand.primary
        }
        startDatePicker.date = startDate
        endDatePicker.date = max(endDate, startDate)
    }

    private func makePickerRow(title: String, picker: UIDatePicker) -> UIView {
        let container = UIView()
        container.backgroundColor = TFColor.Surface.card
        container.layer.cornerRadius = 16

        let label = UILabel()
        label.text = title
        label.font = TFTypography.body.withSize(16)
        label.textColor = TFColor.Text.primary
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }

        container.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        return container
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        onApply?(startDatePicker.date, endDatePicker.date)
        dismiss(animated: true)
    }
}
