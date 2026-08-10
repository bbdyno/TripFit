import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class SharedTripRoomViewController: UIViewController {
    private var room: SharedTripRoom
    private let authService: any AuthService
    private let repository: any CollaborationRepository
    private let context: ModelContext
    private let stack = UIStackView()
    private let summaryLabel = UILabel()
    private let recommendationLabel = UILabel()
    private let confirmButton = UIButton(type: .system)
    private let addToMyTripsButton = UIButton(type: .system)
    private var members: [SharedTripMember] = []
    private var submissions: [AvailabilitySubmission] = []
    private var bestCandidate: ScheduleCandidate?

    public init(
        room: SharedTripRoom,
        authService: any AuthService,
        repository: any CollaborationRepository,
        context: ModelContext
    ) {
        self.room = room
        self.authService = authService
        self.repository = repository
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        title = room.title
        setupContent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    private func setupContent() {
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        stack.axis = .vertical
        stack.spacing = TFSpacing.md
        scrollView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(TFSpacing.md)
            $0.width.equalTo(scrollView.frameLayoutGuide).inset(TFSpacing.md)
        }

        let hero = UILabel()
        hero.font = TFTypography.largeTitle
        hero.textColor = TFColor.Text.primary
        hero.numberOfLines = 0
        hero.text = room.title
        stack.addArrangedSubview(hero)

        summaryLabel.font = TFTypography.bodyRegular
        summaryLabel.textColor = TFColor.Text.secondary
        summaryLabel.numberOfLines = 0
        stack.addArrangedSubview(summaryLabel)

        recommendationLabel.font = TFTypography.bodyRegular
        recommendationLabel.textColor = TFColor.Text.primary
        recommendationLabel.numberOfLines = 0
        recommendationLabel.backgroundColor = TFColor.Surface.card
        recommendationLabel.layer.cornerRadius = TFRadius.md
        recommendationLabel.clipsToBounds = true
        stack.addArrangedSubview(recommendationLabel)

        stack.addArrangedSubview(makeButton(localized("내 가능한 날짜 제출", "Submit My Availability"), icon: "calendar.badge.check") { [weak self] in
            self?.openAvailability()
        })
        stack.addArrangedSubview(makeButton(localized("공동 준비물", "Shared Packing"), icon: "shippingbox") { [weak self] in
            self?.openPacking()
        })
        stack.addArrangedSubview(makeButton(localized("여행 룩북", "Trip Lookbook"), icon: "square.grid.2x2") { [weak self] in
            self?.openLookbook()
        })
        stack.addArrangedSubview(makeButton(localized("초대 링크 공유", "Share Invite Link"), icon: "person.badge.plus") { [weak self] in
            self?.shareInvite()
        })

        configureActionButton(confirmButton, title: localized("이 일정으로 확정", "Confirm This Schedule")) { [weak self] in
            self?.confirmBestSchedule()
        }
        stack.addArrangedSubview(confirmButton)
        configureActionButton(addToMyTripsButton, title: localized("내 여행에 추가", "Add to My Trips")) { [weak self] in
            self?.addConfirmedTripLocally()
        }
        stack.addArrangedSubview(addToMyTripsButton)
    }

    private func makeButton(_ title: String, icon: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 10
        config.baseBackgroundColor = TFColor.Surface.card
        config.baseForegroundColor = TFColor.Text.primary
        config.cornerStyle = .large
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(54) }
        return button
    }

    private func configureActionButton(_ button: UIButton, title: String, action: @escaping () -> Void) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = TFColor.Brand.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.equalTo(54) }
    }

    private func refresh() {
        Task {
            do {
                async let fetchedRoom = repository.fetchRoom(id: room.id)
                async let fetchedMembers = repository.fetchMembers(roomID: room.id)
                async let fetchedAvailability = repository.fetchAvailability(roomID: room.id)
                async let packing = repository.fetchPackingItems(roomID: room.id)
                room = try await fetchedRoom
                members = try await fetchedMembers
                submissions = try await fetchedAvailability
                let packingItems = try await packing
                let packedCount = packingItems.filter(\.isPacked).count
                summaryLabel.text = localized(
                    "\(room.destination)\n\(stageText)\n제출 \(submissions.count)/\(room.memberCount) · 준비물 \(packedCount)/\(packingItems.count)",
                    "\(room.destination)\n\(stageText)\nSubmissions \(submissions.count)/\(room.memberCount) · Packing \(packedCount)/\(packingItems.count)"
                )
                let candidates = try ScheduleRecommendationEngine().recommend(
                    room: room,
                    members: members,
                    submissions: submissions
                )
                bestCandidate = candidates.first
                if let candidate = candidates.first {
                    recommendationLabel.text = localized(
                        "  추천 일정\n  \(candidate.startDay) – \(candidate.endDay)\n  점수 \(Int(candidate.score.total)) · 가능 \(candidate.availableMemberUIDs.count) · 미정 \(candidate.undecidedMemberUIDs.count)  ",
                        "  Recommended\n  \(candidate.startDay) – \(candidate.endDay)\n  Score \(Int(candidate.score.total)) · Available \(candidate.availableMemberUIDs.count) · Undecided \(candidate.undecidedMemberUIDs.count)  "
                    )
                } else {
                    recommendationLabel.text = localized("  제출된 가능 날짜를 기다리는 중입니다.  ", "  Waiting for availability submissions.  ")
                }
                confirmButton.isHidden = room.ownerUID != authService.session?.user.id || room.stage != .coordinating || bestCandidate == nil
                addToMyTripsButton.isHidden = room.stage != .confirmed
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private var stageText: String {
        switch room.stage {
        case .coordinating: localized("일정 조율 중", "Coordinating dates")
        case .confirmed: localized("날짜 확정 · \(room.confirmedStartDay ?? "") – \(room.confirmedEndDay ?? "")", "Confirmed · \(room.confirmedStartDay ?? "") – \(room.confirmedEndDay ?? "")")
        case .completed: localized("완료", "Completed")
        case .archived: localized("보관됨", "Archived")
        }
    }

    private func openAvailability() {
        guard let userID = authService.session?.user.id else { return }
        let editor = AvailabilityEditorViewController(
            room: room,
            userID: userID,
            repository: repository,
            existing: submissions.first(where: { $0.ownerUID == userID })
        )
        editor.onSubmitted = { [weak self] in self?.refresh() }
        navigationController?.pushViewController(editor, animated: true)
    }

    private func openPacking() {
        guard let userID = authService.session?.user.id else { return }
        navigationController?.pushViewController(
            SharedPackingListViewController(room: room, userID: userID, context: context, repository: repository),
            animated: true
        )
    }

    private func openLookbook() {
        guard let userID = authService.session?.user.id else { return }
        navigationController?.pushViewController(
            SharedLookbookViewController(room: room, userID: userID, repository: repository),
            animated: true
        )
    }

    private func shareInvite() {
        guard let userID = authService.session?.user.id else { return }
        Task {
            do {
                let expiry = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                let url = try await repository.createInvite(roomID: room.id, ownerUID: userID, expiresAt: expiry)
                present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private func confirmBestSchedule() {
        guard let candidate = bestCandidate else { return }
        Task {
            do {
                try await repository.confirmSchedule(
                    roomID: room.id,
                    startDay: candidate.startDay,
                    endDay: candidate.endDay,
                    expectedRevision: room.revision
                )
                refresh()
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private func addConfirmedTripLocally() {
        guard let startDay = room.confirmedStartDay,
              let endDay = room.confirmedEndDay,
              let start = try? CalendarDayCodec.date(from: startDay, timezoneID: room.timezoneID),
              let end = try? CalendarDayCodec.date(from: endDay, timezoneID: room.timezoneID) else { return }
        let links = (try? context.fetch(FetchDescriptor<TripCollaborationLink>())) ?? []
        guard links.contains(where: { $0.roomID == room.id }) == false else {
            showMessage(localized("이미 내 여행에 추가되어 있습니다.", "Already added to My Trips."))
            return
        }
        let trip = Trip(name: room.title, startDate: start, endDate: end, destination: room.destination, destinationCountryCode: room.countryCode)
        context.insert(trip)
        context.insert(TripCollaborationLink(roomID: room.id, localTripID: trip.id, revision: room.revision))
        try? context.save()
        showMessage(localized("내 여행에 추가했습니다.", "Added to My Trips."))
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localized("확인", "OK"), style: .default))
        present(alert, animated: true)
    }

    private func localized(_ ko: String, _ en: String) -> String {
        TFAppLanguage.current() == .korean ? ko : en
    }
}
