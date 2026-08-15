import Core
import Domain
import SnapKit
import UIKit

public final class SharedTripCreateViewController: UIViewController {
    public var onCreated: ((SharedTripRoom) -> Void)?

    private let authService: any AuthService
    private let repository: any CollaborationRepository
    private let appleSignInCoordinator = AppleSignInCoordinator()
    private let titleField = UITextField()
    private let destinationField = UITextField()
    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()
    private let durationStepper = UIStepper()
    private let durationLabel = UILabel()
    private let createButton = TFPrimaryButton(title: "")

    public init(authService: any AuthService, repository: any CollaborationRepository) {
        self.authService = authService
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        title = localized("함께 준비하는 여행", "Plan a Trip Together")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: localized("취소", "Cancel"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        setupForm()
    }

    private func setupForm() {
        let scrollView = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = TFSpacing.md
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        stack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(TFSpacing.lg)
            $0.width.equalTo(scrollView.frameLayoutGuide).inset(TFSpacing.lg)
        }

        stack.addArrangedSubview(makeIntroHero())
        stack.setCustomSpacing(TFSpacing.xl, after: stack.arrangedSubviews.last!)

        configure(field: titleField, placeholder: localized("방 제목", "Room title"))
        configure(field: destinationField, placeholder: localized("목적지", "Destination"))
        stack.addArrangedSubview(makeFieldCard(title: localized("여행 이름", "Trip Name"), control: titleField))
        stack.addArrangedSubview(makeFieldCard(title: localized("목적지", "Destination"), control: destinationField))

        let calendar = Calendar.current
        startPicker.datePickerMode = .date
        startPicker.preferredDatePickerStyle = .compact
        startPicker.minimumDate = calendar.startOfDay(for: Date())
        startPicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        endPicker.datePickerMode = .date
        endPicker.preferredDatePickerStyle = .compact
        endPicker.minimumDate = startPicker.date
        endPicker.maximumDate = calendar.date(byAdding: .day, value: 89, to: startPicker.date)
        endPicker.date = calendar.date(byAdding: .day, value: 14, to: startPicker.date) ?? startPicker.date
        stack.addArrangedSubview(makeFieldCard(title: localized("후보 시작일", "Candidate Start"), control: startPicker))
        stack.addArrangedSubview(makeFieldCard(title: localized("후보 종료일", "Candidate End"), control: endPicker))

        durationStepper.minimumValue = 1
        durationStepper.maximumValue = 30
        durationStepper.value = 3
        durationStepper.addTarget(self, action: #selector(durationChanged), for: .valueChanged)
        durationLabel.font = TFTypography.bodyRegular
        durationLabel.textColor = TFColor.Text.primary
        let durationRow = UIStackView(arrangedSubviews: [durationLabel, UIView(), durationStepper])
        durationRow.alignment = .center
        stack.addArrangedSubview(makeFieldCard(title: localized("여행 기간", "Trip Duration"), control: durationRow))
        updateDurationLabel()

        createButton.setTitle(localized("여행방 만들기", "Create Trip Room"), for: .normal)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        if let previousView = stack.arrangedSubviews.last {
            stack.setCustomSpacing(TFSpacing.xl, after: previousView)
        }
        stack.addArrangedSubview(createButton)
    }

    private func configure(field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.textColor = TFColor.Text.primary
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
    }

    private func makeFieldCard(title: String, control: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = TFTypography.caption
        titleLabel.textColor = TFColor.Text.secondary
        let stack = UIStackView(arrangedSubviews: [titleLabel, control])
        stack.axis = .vertical
        stack.spacing = 8
        let card = TFCardView(style: .flat)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(TFSpacing.md) }
        card.snp.makeConstraints { $0.height.greaterThanOrEqualTo(72) }
        return card
    }

    private func makeIntroHero() -> UIView {
        let hero = UIView()
        hero.backgroundColor = .clear
        hero.layer.cornerRadius = TFRadius.xl
        hero.layer.cornerCurve = .continuous
        hero.clipsToBounds = true

        let backdrop = TFAuroraBackdropView()
        hero.addSubview(backdrop)
        backdrop.snp.makeConstraints { $0.edges.equalToSuperview() }

        let eyebrow = UILabel()
        eyebrow.text = "TRIPFIT TOGETHER"
        eyebrow.font = TFTypography.caption.withSize(11)
        eyebrow.textColor = TFColor.Brand.primaryLight

        let title = UILabel()
        title.text = localized("날짜부터\n함께 맞춰보세요.", "Start with dates\nyou can all make.")
        title.font = TFTypography.title.withSize(26)
        title.textColor = .white
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = localized(
            "여행방을 만들면 친구들의 가능한 날을 한눈에 비교할 수 있어요.",
            "Create a private room, invite friends, and compare everyone’s availability."
        )
        subtitle.font = TFTypography.bodyRegular.withSize(14)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.72)
        subtitle.numberOfLines = 0

        let iconPanel = TFGlassPanelView(
            style: .systemUltraThinMaterialDark,
            cornerRadius: 28,
            tintColor: UIColor.white.withAlphaComponent(0.08)
        )
        let icon = UIImageView(image: UIImage(named: "TFSharedPlanningEditorialV2"))
        icon.contentMode = .scaleAspectFill
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 20
        iconPanel.contentView.addSubview(icon)
        icon.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }

        let textStack = UIStackView(arrangedSubviews: [eyebrow, title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 7
        hero.addSubview(textStack)
        hero.addSubview(iconPanel)
        textStack.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview().inset(TFSpacing.lg)
            make.trailing.equalTo(iconPanel.snp.leading).offset(-12)
        }
        iconPanel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(TFSpacing.lg)
            make.top.equalToSuperview().inset(TFSpacing.lg)
            make.size.equalTo(72)
        }
        hero.snp.makeConstraints { $0.height.greaterThanOrEqualTo(176) }
        return hero
    }

    @objc private func dateChanged() {
        let calendar = Calendar.current
        endPicker.minimumDate = startPicker.date
        endPicker.maximumDate = calendar.date(byAdding: .day, value: 89, to: startPicker.date)
        if endPicker.date < startPicker.date { endPicker.date = startPicker.date }
    }

    @objc private func durationChanged() { updateDurationLabel() }

    private func updateDurationLabel() {
        let days = Int(durationStepper.value)
        durationLabel.text = localized("\(days)일", "\(days) days")
    }

    @objc private func createTapped() {
        Task { await createRoom() }
    }

    private func createRoom() async {
        guard let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              title.isEmpty == false else {
            showError(localized("방 제목을 입력해 주세요.", "Enter a room title."))
            return
        }
        let destination = destinationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        do {
            let session: AuthSession
            if let current = authService.session {
                session = current
            } else {
                session = try await appleSignInCoordinator.signIn(using: authService, presenting: self)
            }
            createButton.isEnabled = false
            let timezoneID = TimeZone.current.identifier
            let room = SharedTripRoom(
                id: UUID().uuidString.lowercased(),
                ownerUID: session.user.id,
                memberUIDs: [session.user.id],
                title: title,
                destination: destination,
                countryCode: nil,
                timezoneID: timezoneID,
                candidateStartDay: CalendarDayCodec.string(from: startPicker.date, timezoneID: timezoneID),
                candidateEndDay: CalendarDayCodec.string(from: endPicker.date, timezoneID: timezoneID),
                durationDays: Int(durationStepper.value)
            )
            try await repository.createRoom(
                room,
                owner: SharedTripMember(
                    userID: session.user.id,
                    displayName: session.user.displayName,
                    role: .owner
                )
            )
            onCreated?(room)
            dismiss(animated: true)
        } catch AuthServiceError.cancelled {
            createButton.isEnabled = true
        } catch {
            createButton.isEnabled = true
            showError(error.localizedDescription)
        }
    }

    @objc private func cancelTapped() { dismiss(animated: true) }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: localized("만들 수 없음", "Unable to Create"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localized("확인", "OK"), style: .default))
        present(alert, animated: true)
    }

    private func localized(_ ko: String, _ en: String) -> String {
        TFAppLanguage.current() == .korean ? ko : en
    }
}
