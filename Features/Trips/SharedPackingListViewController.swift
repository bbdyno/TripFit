import Core
import Domain
import SwiftData
import UIKit

final class SharedPackingListViewController: UITableViewController {
    private let room: SharedTripRoom
    private let userID: String
    private let context: ModelContext
    private let repository: any CollaborationRepository
    private var items: [SharedPackingItem] = []
    private var members: [SharedTripMember] = []

    init(
        room: SharedTripRoom,
        userID: String,
        context: ModelContext,
        repository: any CollaborationRepository
    ) {
        self.room = room
        self.userID = userID
        self.context = context
        self.repository = repository
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localized("공동 준비물", "Shared Packing")
        tableView.backgroundColor = TFColor.Surface.canvas
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        refresh()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "packing")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "packing")
        let item = items[indexPath.row]
        cell.textLabel?.text = "\(item.title) × \(item.quantity)"
        cell.detailTextLabel?.text = assigneeName(item.assigneeUID)
        cell.accessoryType = item.isPacked ? .checkmark : .none
        cell.textLabel?.textColor = item.isPacked ? TFColor.Text.tertiary : TFColor.Text.primary
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var item = items[indexPath.row]
        if item.assigneeUID == nil {
            item.assigneeUID = userID
        } else if item.assigneeUID == userID {
            item.isPacked.toggle()
        } else {
            showMessage(localized("다른 멤버가 담당 중입니다.", "Another member is assigned."))
            return
        }
        item.revision += 1
        item.updatedAt = Date()
        save(item)
    }

    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let item = items[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            var actions: [UIMenuElement] = []
            if item.assigneeUID == userID {
                actions.append(UIAction(title: localized("내 패킹리스트에도 추가", "Add to My Packing List"), image: UIImage(systemName: "person.crop.circle.badge.plus")) { [weak self] _ in
                    self?.copyToPersonalPacking(item)
                })
            }
            if room.ownerUID == userID {
                let memberActions = [UIAction(title: localized("미배정", "Unassigned")) { [weak self] _ in
                    self?.reassign(item, to: nil)
                }] + members.map { member in
                    UIAction(title: member.displayName ?? member.userID) { [weak self] _ in
                        self?.reassign(item, to: member.userID)
                    }
                }
                actions.append(UIMenu(title: localized("담당자 변경", "Reassign"), children: memberActions))
            }
            return UIMenu(children: actions)
        }
    }

    @objc private func addTapped() {
        let alert = UIAlertController(title: localized("공동 준비물 추가", "Add Shared Item"), message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = self.localized("항목 이름", "Item name") }
        alert.addTextField { $0.placeholder = self.localized("카테고리", "Category") }
        alert.addAction(UIAlertAction(title: localized("추가", "Add"), style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let title = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  title.isEmpty == false else { return }
            let category = alert?.textFields?.dropFirst().first?.text ?? "shared"
            save(SharedPackingItem(
                id: UUID().uuidString.lowercased(),
                roomID: room.id,
                title: title,
                category: category,
                quantity: 1,
                createdByUID: userID
            ))
        })
        alert.addAction(UIAlertAction(title: localized("취소", "Cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func refresh() {
        Task {
            do {
                async let fetchedItems = repository.fetchPackingItems(roomID: room.id)
                async let fetchedMembers = repository.fetchMembers(roomID: room.id)
                items = try await fetchedItems
                members = try await fetchedMembers
                tableView.reloadData()
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private func save(_ item: SharedPackingItem) {
        Task {
            do {
                try await repository.upsertPackingItem(item)
                refresh()
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private func reassign(_ original: SharedPackingItem, to userID: String?) {
        var item = original
        item.assigneeUID = userID
        item.isPacked = false
        item.revision += 1
        item.updatedAt = Date()
        save(item)
    }

    private func copyToPersonalPacking(_ item: SharedPackingItem) {
        let links = (try? context.fetch(FetchDescriptor<TripCollaborationLink>())) ?? []
        guard let localTripID = links.first(where: { $0.roomID == room.id })?.localTripID else {
            showMessage(localized("먼저 확정된 일정을 내 여행에 추가해 주세요.", "Add the confirmed trip to My Trips first."))
            return
        }
        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        guard let trip = trips.first(where: { $0.id == localTripID }) else { return }
        let personal = PackingItem(trip: trip, customName: item.title, quantity: item.quantity)
        context.insert(personal)
        try? context.save()
        showMessage(localized("내 패킹리스트에 복사했습니다.", "Copied to your personal packing list."))
    }

    private func assigneeName(_ userID: String?) -> String {
        guard let userID else { return localized("담당자 없음 · 눌러서 맡기", "Unassigned · tap to claim") }
        return members.first(where: { $0.userID == userID })?.displayName ?? userID
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
