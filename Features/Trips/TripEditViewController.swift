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

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let nameField = UITextField()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let destinationField = UITextField()
    private let countryButton = UIButton(type: .system)
    private let noteField = UITextField()
    private var selectedCountryCode: String?

    public init(context: ModelContext, editingTrip: Trip? = nil) {
        self.context = context
        self.editingTrip = editingTrip
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = editingTrip == nil ? "New Trip" : "Edit Trip"
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

        stackView.addArrangedSubview(makeFieldCard(title: "Name *", field: nameField, placeholder: "Trip name"))
        stackView.addArrangedSubview(makeDateCard(title: "Start Date *", picker: startDatePicker))
        stackView.addArrangedSubview(makeDateCard(title: "End Date *", picker: endDatePicker))
        stackView.addArrangedSubview(
            makeFieldCard(title: "Destination", field: destinationField, placeholder: "e.g. Tokyo")
        )

        countryButton.setTitle("Country: None", for: .normal)
        countryButton.setTitleColor(TFColor.Text.primary, for: .normal)
        countryButton.titleLabel?.font = TFTypography.body
        countryButton.contentHorizontalAlignment = .leading
        countryButton.addTarget(self, action: #selector(selectCountry), for: .touchUpInside)
        stackView.addArrangedSubview(makeCard(title: "Country Code", content: countryButton))

        stackView.addArrangedSubview(makeFieldCard(title: "Note", field: noteField, placeholder: "Optional note"))
    }

    private func makeFieldCard(title: String, field: UITextField, placeholder: String) -> UIView {
        field.placeholder = placeholder
        field.font = TFTypography.body
        field.textColor = TFColor.Text.primary
        return makeCard(title: title, content: field)
    }

    private func makeDateCard(title: String, picker: UIDatePicker) -> UIView {
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        return makeCard(title: title, content: picker)
    }

    private func makeCard(title: String, content: UIView) -> UIView {
        TFFormFieldCard(title: title, content: content, style: .flat)
    }

    @objc private func selectCountry() {
        let picker = CountryPickerViewController()
        picker.onSelect = { [weak self] code, name in
            self?.selectedCountryCode = code
            self?.countryButton.setTitle("Country: \(name) (\(code))", for: .normal)
        }
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }

    private func populateIfEditing() {
        guard let trip = editingTrip else { return }
        nameField.text = trip.name
        startDatePicker.date = trip.startDate
        endDatePicker.date = trip.endDate
        destinationField.text = trip.destination
        noteField.text = trip.note
        selectedCountryCode = trip.destinationCountryCode
        if let code = trip.destinationCountryCode {
            countryButton.setTitle("Country: \(code)", for: .normal)
        }
    }

    private func save() {
        guard let name = nameField.text, !name.isEmpty else {
            let alert = UIAlertController(title: nil, message: "Please enter a name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        if let trip = editingTrip {
            trip.name = name
            trip.startDate = startDatePicker.date
            trip.endDate = endDatePicker.date
            trip.destination = destinationField.text?.isEmpty == true ? nil : destinationField.text
            trip.destinationCountryCode = selectedCountryCode
            trip.note = noteField.text?.isEmpty == true ? nil : noteField.text
            trip.updatedAt = Date()
        } else {
            let trip = Trip(
                name: name,
                startDate: startDatePicker.date,
                endDate: endDatePicker.date,
                destination: destinationField.text?.isEmpty == true ? nil : destinationField.text,
                destinationCountryCode: selectedCountryCode,
                note: noteField.text?.isEmpty == true ? nil : noteField.text
            )
            context.insert(trip)
        }
        try? context.save()
        dismiss(animated: true)
    }
}
