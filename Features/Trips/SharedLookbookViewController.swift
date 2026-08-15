import Core
import Domain
import UIKit

final class SharedLookbookViewController: UITableViewController {
    private let room: SharedTripRoom
    private let userID: String
    private let repository: any CollaborationRepository
    private var plans: [SharedLookPlan] = []

    init(room: SharedTripRoom, userID: String, repository: any CollaborationRepository) {
        self.room = room
        self.userID = userID
        self.repository = repository
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localized("여행 룩북", "Trip Lookbook")
        tableView.backgroundColor = TFColor.Surface.canvas
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        refresh()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { plans.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "look")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "look")
        let plan = plans[indexPath.row]
        cell.textLabel?.text = "\(plan.day) · \(plan.outfitName)"
        cell.detailTextLabel?.text = plan.categories.joined(separator: " · ")
        cell.accessoryView = paletteView(plan.paletteHex)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        shareCard(for: plans[indexPath.row])
    }

    @objc private func addTapped() {
        let alert = UIAlertController(
            title: localized("룩 메타데이터 추가", "Add Look Metadata"),
            message: localized("사진과 옷장 ID는 공유되지 않습니다.", "Photos and wardrobe IDs are never shared."),
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = self.localized("코디 이름", "Outfit name") }
        alert.addTextField { $0.placeholder = self.localized("카테고리 (쉼표 구분)", "Categories (comma separated)") }
        alert.addAction(UIAlertAction(title: localized("추가", "Add"), style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  name.isEmpty == false else { return }
            let categories = (alert?.textFields?.dropFirst().first?.text ?? "")
                .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let day = room.confirmedStartDay ?? room.candidateStartDay
            let plan = SharedLookPlan(
                id: "\(userID)_\(day)",
                roomID: room.id,
                ownerUID: userID,
                day: day,
                outfitName: name,
                categories: categories,
                paletteHex: [],
                styleTags: [],
                formality: 2,
                rainReady: false
            )
            Task {
                do {
                    try await self.repository.upsertLookPlan(plan)
                    self.refresh()
                } catch {
                    self.showMessage(error.localizedDescription)
                }
            }
        })
        alert.addAction(UIAlertAction(title: localized("취소", "Cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func refresh() {
        Task {
            do {
                plans = try await repository.fetchLookPlans(roomID: room.id)
                tableView.reloadData()
            } catch {
                showMessage(error.localizedDescription)
            }
        }
    }

    private func paletteView(_ colors: [String]) -> UIView? {
        guard colors.isEmpty == false else { return nil }
        let stack = UIStackView()
        stack.spacing = 3
        colors.prefix(4).forEach { value in
            let chip = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            chip.layer.cornerRadius = 8
            chip.backgroundColor = UIColor(hexString: value)
            chip.widthAnchor.constraint(equalToConstant: 16).isActive = true
            stack.addArrangedSubview(chip)
        }
        return stack
    }

    private func shareCard(for plan: SharedLookPlan) {
        let size = CGSize(width: 1080, height: 1080)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.08, green: 0.08, blue: 0.11, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let title = "TripFit\n\(plan.day)\n\(plan.outfitName)\n\(plan.categories.joined(separator: " · "))"
            title.draw(
                in: CGRect(x: 90, y: 100, width: 900, height: 800),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                    .foregroundColor: UIColor.white,
                ]
            )
        }
        present(UIActivityViewController(activityItems: [image], applicationActivities: nil), animated: true)
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

private extension UIColor {
    convenience init?(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        self.init(
            red: CGFloat((value >> 16) & 0xff) / 255,
            green: CGFloat((value >> 8) & 0xff) / 255,
            blue: CGFloat(value & 0xff) / 255,
            alpha: 1
        )
    }
}
