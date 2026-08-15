import Core
import Domain
import UIKit

final class AvailabilityEditorViewController: UITableViewController {
    var onSubmitted: (() -> Void)?

    private let room: SharedTripRoom
    private let userID: String
    private let repository: any CollaborationRepository
    private let calendarService = CalendarAvailabilitySuggestionService()
    private let days: [String]
    private var manualByDay: [String: AvailabilityDay] = [:]
    private var suggestionByDay: [String: AvailabilityDay] = [:]
    private var leaveUnits = 0.0
    private var lateJoin = false
    private var earlyLeave = false

    init(
        room: SharedTripRoom,
        userID: String,
        repository: any CollaborationRepository,
        existing: AvailabilitySubmission?
    ) {
        self.room = room
        self.userID = userID
        self.repository = repository
        self.days = (try? CalendarDayCodec.days(
            from: room.candidateStartDay,
            through: room.candidateEndDay,
            timezoneID: room.timezoneID
        )) ?? []
        if let existing {
            self.manualByDay = Dictionary(uniqueKeysWithValues: existing.days.map { ($0.day, $0) })
            self.leaveUnits = existing.leaveUnits
            self.lateJoin = existing.lateJoin
            self.earlyLeave = existing.earlyLeave
        }
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localized("가능한 날짜", "Availability")
        tableView.backgroundColor = TFColor.Surface.canvas
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: localized("옵션", "Options"),
            style: .plain,
            target: self,
            action: #selector(optionsTapped)
        )
        toolbarItems = [
            UIBarButtonItem(
                title: localized("캘린더에서 불러오기", "Import Calendar"),
                style: .plain,
                target: self,
                action: #selector(importCalendarTapped)
            ),
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: localized("제출", "Submit"),
                style: .done,
                target: self,
                action: #selector(submitTapped)
            ),
        ]
        navigationController?.setToolbarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent { navigationController?.setToolbarHidden(true, animated: animated) }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { days.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "availability")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "availability")
        let day = days[indexPath.row]
        let value = resolvedDay(day)
        cell.textLabel?.text = day
        cell.detailTextLabel?.text = value.source == .manual
            ? localized("직접 입력", "Manual")
            : localized("캘린더 제안 · 확인 필요", "Calendar suggestion · review required")
        cell.detailTextLabel?.textColor = TFColor.Text.secondary
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(systemName: icon(for: value.status))
        cell.imageView?.tintColor = color(for: value.status)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentStatusPicker(for: days[indexPath.row])
    }

    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let day = days[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            let slotMenus = AvailabilityTimeSlot.allCases.map { slot in
                UIMenu(title: self.slotTitle(slot), children: AvailabilityStatus.allCases.map { status in
                    UIAction(title: self.statusTitle(status)) { [weak self] _ in
                        self?.setSlot(status, slot: slot, day: day)
                    }
                })
            }
            return UIMenu(title: localized("시간대 상세", "Time Slots"), children: slotMenus)
        }
    }

    @objc private func importCalendarTapped() {
        Task {
            do {
                let suggestions = try await calendarService.suggestions(for: room)
                let alert = UIAlertController(
                    title: localized("캘린더 제안 검토", "Review Calendar Suggestions"),
                    message: localized(
                        "바쁜 날짜만 제안으로 표시합니다. 일정 제목과 내용은 업로드되지 않으며 직접 입력을 덮어쓰지 않습니다.",
                        "Busy days are shown only as suggestions. Event details are never uploaded and manual choices stay unchanged."
                    ),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: localized("적용", "Apply"), style: .default) { [weak self] _ in
                    self?.suggestionByDay = Dictionary(uniqueKeysWithValues: suggestions.map { ($0.day, $0) })
                    self?.tableView.reloadData()
                })
                alert.addAction(UIAlertAction(title: localized("취소", "Cancel"), style: .cancel))
                present(alert, animated: true)
            } catch {
                showError(localized(
                    "캘린더 접근이 거부되었습니다. 직접 입력은 계속 사용할 수 있습니다.",
                    "Calendar access was denied. Manual entry remains fully available."
                ))
            }
        }
    }

    @objc private func optionsTapped() {
        let alert = UIAlertController(
            title: localized("참여 옵션", "Participation Options"),
            message: localized(
                "필요 연차 \(leaveUnits)일 · 늦은 합류 \(lateJoin ? "예" : "아니오") · 조기 귀가 \(earlyLeave ? "예" : "아니오")",
                "Leave \(leaveUnits) days · Late join \(lateJoin ? "Yes" : "No") · Early leave \(earlyLeave ? "Yes" : "No")"
            ),
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: localized("연차/반차 0.5일 추가", "Add 0.5 Leave Day"), style: .default) { [weak self] _ in
            guard let self else { return }
            leaveUnits = min(Double(room.durationDays), leaveUnits + 0.5)
        })
        alert.addAction(UIAlertAction(title: localized("연차 초기화", "Reset Leave"), style: .default) { [weak self] _ in
            self?.leaveUnits = 0
        })
        alert.addAction(UIAlertAction(title: localized("늦은 합류 전환", "Toggle Late Join"), style: .default) { [weak self] _ in
            self?.lateJoin.toggle()
        })
        alert.addAction(UIAlertAction(title: localized("조기 귀가 전환", "Toggle Early Leave"), style: .default) { [weak self] _ in
            self?.earlyLeave.toggle()
        })
        alert.addAction(UIAlertAction(title: localized("닫기", "Close"), style: .cancel))
        present(alert, animated: true)
    }

    @objc private func submitTapped() {
        Task {
            do {
                let submission = AvailabilitySubmission(
                    ownerUID: userID,
                    days: days.map(resolvedDay),
                    leaveUnits: leaveUnits,
                    lateJoin: lateJoin,
                    earlyLeave: earlyLeave
                )
                try await repository.submitAvailability(submission, roomID: room.id)
                onSubmitted?()
                navigationController?.popViewController(animated: true)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func presentStatusPicker(for day: String) {
        let alert = UIAlertController(title: day, message: nil, preferredStyle: .actionSheet)
        AvailabilityStatus.allCases.forEach { status in
            alert.addAction(UIAlertAction(title: statusTitle(status), style: .default) { [weak self] _ in
                self?.setStatus(status, day: day)
            })
        }
        alert.addAction(UIAlertAction(title: localized("취소", "Cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func setStatus(_ status: AvailabilityStatus, day: String) {
        var value = resolvedDay(day)
        value.status = status
        value.source = .manual
        manualByDay[day] = value
        tableView.reloadData()
    }

    private func setSlot(_ status: AvailabilityStatus, slot: AvailabilityTimeSlot, day: String) {
        var value = resolvedDay(day)
        value.slots[slot] = status
        value.source = .manual
        manualByDay[day] = value
        tableView.reloadData()
    }

    private func resolvedDay(_ day: String) -> AvailabilityDay {
        manualByDay[day]
            ?? suggestionByDay[day]
            ?? AvailabilityDay(day: day, status: .undecided, source: .calendarSuggestion)
    }

    private func statusTitle(_ status: AvailabilityStatus) -> String {
        switch status {
        case .available: localized("가능", "Available")
        case .maybe: localized("아마 가능", "Maybe")
        case .unavailable: localized("불가", "Unavailable")
        case .undecided: localized("미정", "Undecided")
        }
    }

    private func slotTitle(_ slot: AvailabilityTimeSlot) -> String {
        switch slot {
        case .morning: localized("오전", "Morning")
        case .afternoon: localized("오후", "Afternoon")
        case .evening: localized("저녁", "Evening")
        }
    }

    private func icon(for status: AvailabilityStatus) -> String {
        switch status {
        case .available: "checkmark.circle.fill"
        case .maybe: "questionmark.circle.fill"
        case .unavailable: "xmark.circle.fill"
        case .undecided: "circle.dashed"
        }
    }

    private func color(for status: AvailabilityStatus) -> UIColor {
        switch status {
        case .available: .systemGreen
        case .maybe: .systemOrange
        case .unavailable: .systemRed
        case .undecided: TFColor.Text.tertiary
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: localized("처리할 수 없음", "Unable to Continue"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localized("확인", "OK"), style: .default))
        present(alert, animated: true)
    }

    private func localized(_ ko: String, _ en: String) -> String {
        TFAppLanguage.current() == .korean ? ko : en
    }
}
