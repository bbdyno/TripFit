//
//  TripsListViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class TripsListViewController: UIViewController {
    private let context: ModelContext
    private let authService: any AuthService
    private let collaborationRepository: any CollaborationRepository
    private let pendingInviteStore: any PendingInviteHandling
    private let appleSignInCoordinator = AppleSignInCoordinator()
    private var trips: [Trip] = []
    private var sharedRooms: [SharedTripRoom] = []
    private var sharedStats: [String: (submitted: Int, packed: Int, totalPacking: Int)] = [:]
    private var sharedRoomsTask: Task<Void, Never>?
    private var pendingInviteObserver: NSObjectProtocol?
    private var isPresentingInviteGate = false
    private var clockTimer: Timer?
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let sharedSection = UIView()
    private let sharedTitleLabel = UILabel()
    private let sharedScrollView = UIScrollView()
    private let sharedStack = UIStackView()
    private let personalTitleLabel = UILabel()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private var emptyView: TFEmptyStateView!

    public init(
        context: ModelContext,
        authService: any AuthService,
        collaborationRepository: any CollaborationRepository,
        pendingInviteStore: any PendingInviteHandling
    ) {
        self.context = context
        self.authService = authService
        self.collaborationRepository = collaborationRepository
        self.pendingInviteStore = pendingInviteStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let pendingInviteObserver {
            NotificationCenter.default.removeObserver(pendingInviteObserver)
        }
        sharedRoomsTask?.cancel()
        clockTimer?.invalidate()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupHeader()
        setupSharedSection()
        setupCollectionView()
        setupEmptyView()
        pendingInviteObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("tripfit.pendingInvite.didChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.processPendingInviteIfNeeded() }
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchTrips()
        startSharedRoomsObservation()
        processPendingInviteIfNeeded()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        sharedRoomsTask?.cancel()
        sharedRoomsTask = nil
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startClockTimer()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopClockTimer()
    }

    private func setupHeader() {
        headerContainer.backgroundColor = TFColor.Surface.card.withAlphaComponent(0.96)
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.text = "Trips"
        titleLabel.font = TFTypography.largeTitle.withSize(36)
        titleLabel.textColor = TFColor.Text.primary

        subtitleLabel.text = "Ready for your next adventure?"
        subtitleLabel.font = TFTypography.caption
        subtitleLabel.textColor = TFColor.Text.secondary

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = .white
        addButton.backgroundColor = TFColor.Brand.primary
        addButton.layer.cornerRadius = 22
        addButton.layer.shadowColor = TFColor.Brand.primary.cgColor
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowRadius = 10
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.addAction(UIAction { [weak self] _ in self?.addTapped() }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [titleStack, UIView(), addButton])
        titleRow.alignment = .center
        titleRow.spacing = TFSpacing.md
        headerContainer.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.bottom.equalToSuperview().inset(8)
        }
        addButton.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
        addButton.isHidden = true
    }

    private func setupSharedSection() {
        sharedSection.backgroundColor = TFColor.Surface.canvas
        view.addSubview(sharedSection)
        sharedSection.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(170)
        }

        sharedTitleLabel.text = localized("함께 준비하는 여행", "Trips We Plan Together")
        sharedTitleLabel.font = TFTypography.headline
        sharedTitleLabel.textColor = TFColor.Text.primary
        sharedSection.addSubview(sharedTitleLabel)
        sharedTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
        }

        sharedScrollView.showsHorizontalScrollIndicator = false
        sharedScrollView.alwaysBounceHorizontal = true
        sharedSection.addSubview(sharedScrollView)
        sharedScrollView.snp.makeConstraints { make in
            make.top.equalTo(sharedTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        sharedStack.axis = .horizontal
        sharedStack.spacing = 12
        sharedScrollView.addSubview(sharedStack)
        sharedStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(sharedScrollView.contentLayoutGuide).inset(4)
            make.leading.trailing.equalTo(sharedScrollView.contentLayoutGuide).inset(TFSpacing.md)
            make.height.equalTo(sharedScrollView.frameLayoutGuide).inset(4)
        }

        personalTitleLabel.text = localized("내 여행", "My Trips")
        personalTitleLabel.font = TFTypography.headline
        personalTitleLabel.textColor = TFColor.Text.primary
        view.addSubview(personalTitleLabel)
        personalTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(sharedSection.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
        }
        renderSharedRooms()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = TFSpacing.lg
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.md, left: TFSpacing.md, bottom: 112, right: TFSpacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(TripCell.self, forCellWithReuseIdentifier: TripCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(personalTitleLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TripCell.reuseId, for: indexPath
            ) as! TripCell
            if let trip = self?.trips.first(where: { $0.id == itemId }) {
                cell.configure(with: trip)
            }
            return cell
        }
    }

    private func setupEmptyView() {
        emptyView = TFEmptyStateView(
            icon: "suitcase",
            title: "No Trips Yet",
            subtitle: "Plan your first trip\nand start packing",
            buttonTitle: "Create Trip"
        )
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(personalTitleLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    @objc private func addTapped() {
        let editVC = TripEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    public func presentSharedTripCreate() {
        let create = SharedTripCreateViewController(
            authService: authService,
            repository: collaborationRepository
        )
        create.onCreated = { [weak self] _ in self?.startSharedRoomsObservation() }
        let nav = UINavigationController(rootViewController: create)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func startSharedRoomsObservation() {
        sharedRoomsTask?.cancel()
        guard let userID = authService.session?.user.id else {
            sharedRooms = []
            sharedStats = [:]
            renderSharedRooms()
            return
        }
        sharedRoomsTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await rooms in collaborationRepository.observeActiveRooms(for: userID) {
                    guard Task.isCancelled == false else { return }
                    sharedRooms = rooms
                    await loadSharedStats()
                    renderSharedRooms()
                }
            } catch {
                guard Task.isCancelled == false else { return }
                renderSharedRooms(error: error)
            }
        }
    }

    private func loadSharedStats() async {
        var result: [String: (submitted: Int, packed: Int, totalPacking: Int)] = [:]
        for room in sharedRooms {
            do {
                async let availability = collaborationRepository.fetchAvailability(roomID: room.id)
                async let packing = collaborationRepository.fetchPackingItems(roomID: room.id)
                let submissions = try await availability
                let packingItems = try await packing
                result[room.id] = (
                    submitted: submissions.count,
                    packed: packingItems.filter(\.isPacked).count,
                    totalPacking: packingItems.count
                )
            } catch {
                result[room.id] = (0, 0, 0)
            }
        }
        sharedStats = result
    }

    private func renderSharedRooms(error: Error? = nil) {
        sharedStack.arrangedSubviews.forEach {
            sharedStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if let error {
            sharedStack.addArrangedSubview(makeSharedPlaceholder(
                title: localized("공유 여행을 불러올 수 없음", "Unable to Load Shared Trips"),
                subtitle: error.localizedDescription
            ))
            return
        }
        guard authService.session != nil else {
            sharedStack.addArrangedSubview(makeSharedPlaceholder(
                title: localized("로그인 없이 개인 여행을 계속 사용할 수 있어요", "Personal trips stay available without sign-in"),
                subtitle: localized("공유 여행을 시작할 때만 Apple 로그인이 필요합니다.", "Apple sign-in is needed only when starting a shared trip.")
            ))
            return
        }
        guard sharedRooms.isEmpty == false else {
            sharedStack.addArrangedSubview(makeSharedPlaceholder(
                title: localized("아직 함께 준비하는 여행이 없어요", "No shared trips yet"),
                subtitle: localized("가운데 + 버튼에서 친구와 날짜부터 맞춰보세요.", "Use the center + button to coordinate dates with friends.")
            ))
            return
        }
        for room in sharedRooms {
            let stats = sharedStats[room.id] ?? (0, 0, 0)
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.filled()
            config.title = room.title
            config.subtitle = localized(
                "\(room.destination) · \(room.stage == .confirmed ? "날짜 확정" : "일정 조율 중")\n제출 \(stats.submitted)/\(room.memberCount) · 준비물 \(stats.packed)/\(stats.totalPacking)",
                "\(room.destination) · \(room.stage == .confirmed ? "Confirmed" : "Coordinating")\nSubmissions \(stats.submitted)/\(room.memberCount) · Packing \(stats.packed)/\(stats.totalPacking)"
            )
            config.titleAlignment = .leading
            config.baseBackgroundColor = TFColor.Surface.card
            config.baseForegroundColor = TFColor.Text.primary
            config.cornerStyle = .large
            config.image = UIImage(systemName: "person.2.fill")
            config.imagePlacement = .leading
            config.imagePadding = 10
            button.configuration = config
            button.addAction(UIAction { [weak self] _ in self?.openSharedRoom(room) }, for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.width.equalTo(260)
                make.height.equalTo(112)
            }
            sharedStack.addArrangedSubview(button)
        }
    }

    private func makeSharedPlaceholder(title: String, subtitle: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = TFTypography.body
        titleLabel.textColor = TFColor.Text.primary
        titleLabel.numberOfLines = 1
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = TFTypography.footnote
        subtitleLabel.textColor = TFColor.Text.secondary
        subtitleLabel.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        let card = TFCardView(style: .outlined)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(TFSpacing.md) }
        card.snp.makeConstraints { make in
            make.width.equalTo(view.snp.width).offset(-(TFSpacing.md * 2))
            make.height.equalTo(112)
        }
        return card
    }

    private func openSharedRoom(_ room: SharedTripRoom) {
        navigationController?.pushViewController(
            SharedTripRoomViewController(
                room: room,
                authService: authService,
                repository: collaborationRepository,
                context: context
            ),
            animated: true
        )
    }

    private func processPendingInviteIfNeeded() {
        guard isPresentingInviteGate == false,
              let rawToken = pendingInviteStore.rawToken,
              viewIfLoaded?.window != nil else { return }
        if authService.session == nil {
            isPresentingInviteGate = true
            let alert = UIAlertController(
                title: localized("여행 초대를 받았어요", "Trip Invitation Received"),
                message: localized("참여하려면 Apple로 로그인해 주세요.", "Sign in with Apple to join."),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: localized("Apple로 로그인", "Sign in with Apple"), style: .default) { [weak self] _ in
                guard let self else { return }
                Task {
                    defer { self.isPresentingInviteGate = false }
                    do {
                        _ = try await self.appleSignInCoordinator.signIn(using: self.authService, presenting: self)
                        self.startSharedRoomsObservation()
                        self.joinPendingInvite(rawToken)
                    } catch AuthServiceError.cancelled {
                        return
                    } catch {
                        self.showMessage(error.localizedDescription)
                    }
                }
            })
            alert.addAction(UIAlertAction(title: localized("나중에", "Later"), style: .cancel) { [weak self] _ in
                self?.isPresentingInviteGate = false
            })
            present(alert, animated: true)
        } else {
            joinPendingInvite(rawToken)
        }
    }

    private func joinPendingInvite(_ rawToken: String) {
        guard let session = authService.session else { return }
        Task {
            do {
                let roomID = try await collaborationRepository.joinInvite(
                    rawToken: rawToken,
                    member: SharedTripMember(
                        userID: session.user.id,
                        displayName: session.user.displayName,
                        role: .member
                    )
                )
                pendingInviteStore.clear()
                let room = try await collaborationRepository.fetchRoom(id: roomID)
                startSharedRoomsObservation()
                openSharedRoom(room)
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private func showMessage(_ message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localized("확인", "OK"), style: .default))
        present(alert, animated: true)
    }

    private func localized(_ ko: String, _ en: String) -> String {
        TFAppLanguage.current() == .korean ? ko : en
    }

    private func fetchTrips() {
        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        trips = (try? context.fetch(descriptor)) ?? []
        applySnapshot()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(trips.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !trips.isEmpty
        refreshVisibleLocalTimes()
    }

    private func startClockTimer() {
        guard clockTimer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshVisibleLocalTimes()
        }
        clockTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        refreshVisibleLocalTimes()
    }

    private func stopClockTimer() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func refreshVisibleLocalTimes() {
        guard collectionView != nil else { return }
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard
                let itemID = dataSource.itemIdentifier(for: indexPath),
                let trip = trips.first(where: { $0.id == itemID }),
                let cell = collectionView.cellForItem(at: indexPath) as? TripCell
            else { continue }
            cell.refreshLiveTime(for: trip)
        }
    }
}

extension TripsListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let trip = trips.first(where: { $0.id == itemID })
        else { return }
        let detail = TripDetailViewController(context: context, trip: trip)
        navigationController?.pushViewController(detail, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let trip = trips.first(where: { $0.id == itemID })
        else { return nil }
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let delete = UIAction(title: CoreStrings.Common.delete, attributes: .destructive) { _ in
                self?.context.delete(trip)
                try? self?.context.save()
                self?.fetchTrips()
            }
            return UIMenu(children: [delete])
        })
    }
}

extension TripsListViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width - (TFSpacing.md * 2)
        return CGSize(width: width, height: 292)
    }
}
