//
//  OutfitsListViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import SnapKit
import SwiftData
import UIKit

public final class OutfitsListViewController: UIViewController {
    private enum FilterType: CaseIterable {
        case all
        case favorites
        case summer

        var title: String {
            let korean = TFAppLanguage.current() == .korean
            switch self {
            case .all: return korean ? "전체" : "All"
            case .favorites: return korean ? "즐겨찾기" : "Favorites"
            case .summer: return korean ? "여름" : "Summer"
            }
        }
    }

    private let context: ModelContext
    private var outfits: [Outfit] = []
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private let plannerCard = TFCardView(style: .flat)
    private let plannerCountLabel = UILabel()
    private let weekStack = UIStackView()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private var emptyView: TFEmptyStateView!
    private let filterScrollView = UIScrollView()
    private let filterStack = UIStackView()
    private var filterButtons: [TFChip] = []
    private var selectedFilter: FilterType = .all

    public init(context: ModelContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TFColor.Surface.canvas
        setupHeader()
        setupPlannerStrip()
        setupFilterBar()
        setupCollectionView()
        setupEmptyView()
    }

    private func setupPlannerStrip() {
        view.addSubview(plannerCard)
        plannerCard.layer.cornerRadius = 18
        plannerCard.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.md)
            make.height.equalTo(108)
        }

        let plannerTitle = UILabel()
        plannerTitle.text = localized("이번 주의 룩 보드", "This week's look board")
        plannerTitle.font = TFTypography.caption.withSize(14)
        plannerTitle.textColor = TFColor.Text.primary

        plannerCountLabel.font = TFTypography.footnote.withSize(10)
        plannerCountLabel.textColor = TFColor.Brand.accentPurple
        plannerCountLabel.textAlignment = .right

        plannerCard.addSubview(plannerTitle)
        plannerCard.addSubview(plannerCountLabel)
        plannerTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
        }
        plannerCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(plannerTitle)
            make.trailing.equalToSuperview().inset(14)
        }

        weekStack.axis = .horizontal
        weekStack.distribution = .fillEqually
        weekStack.spacing = 5
        plannerCard.addSubview(weekStack)
        weekStack.snp.makeConstraints { make in
            make.top.equalTo(plannerTitle.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let start = calendar.date(byAdding: .day, value: -(weekday - calendar.firstWeekday + 7) % 7, to: today) ?? today
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = TFAppLanguage.current() == .korean ? Locale(identifier: "ko_KR") : Locale(identifier: "en_US")
        weekdayFormatter.dateFormat = "EEEEE"

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? today
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let day = UILabel()
            day.text = "\(weekdayFormatter.string(from: date))\n\(calendar.component(.day, from: date))"
            day.numberOfLines = 2
            day.textAlignment = .center
            day.font = TFTypography.footnote.withSize(10)
            day.textColor = isToday ? .white : TFColor.Text.secondary
            day.backgroundColor = isToday ? TFColor.Brand.accentPurple : TFColor.Surface.input
            day.layer.cornerRadius = 16
            day.layer.cornerCurve = .continuous
            day.clipsToBounds = true
            weekStack.addArrangedSubview(day)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchOutfits()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupHeader() {
        headerContainer.backgroundColor = TFColor.Surface.canvas
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.text = "Outfits"
        titleLabel.font = TFTypography.largeTitle
        titleLabel.textColor = TFColor.Text.primary

        subtitleLabel.text = localized("내 옷으로 완성한 룩", "Looks made from what you own")
        subtitleLabel.font = TFTypography.footnote.withSize(13)
        subtitleLabel.textColor = TFColor.Text.secondary

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 1

        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = TFColor.Brand.primary
        addButton.backgroundColor = TFColor.Brand.primary.withAlphaComponent(0.12)
        addButton.layer.cornerRadius = 20
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = TFColor.Brand.primary.withAlphaComponent(0.24).cgColor
        addButton.addAction(UIAction { [weak self] _ in self?.addTapped() }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [titleStack, UIView(), addButton])
        titleRow.alignment = .center
        titleRow.spacing = TFSpacing.md
        headerContainer.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.leading.trailing.equalToSuperview().inset(TFSpacing.lg)
            make.bottom.equalToSuperview().inset(10)
        }
        addButton.snp.makeConstraints { make in
            make.size.equalTo(40)
        }
        addButton.accessibilityLabel = localized("코디 추가", "Add outfit")
    }

    private func setupFilterBar() {
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(filterScrollView)
        filterScrollView.snp.makeConstraints { make in
            make.top.equalTo(plannerCard.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }

        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterScrollView.addSubview(filterStack)
        filterStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
            make.height.equalToSuperview().offset(-16)
        }

        FilterType.allCases.forEach { filter in
            let button = TFChip(title: filter.title)
            button.setStyle(.darkFilter)
            button.tag = filterButtons.count
            button.addTarget(self, action: #selector(filterChipTapped(_:)), for: .touchUpInside)
            filterButtons.append(button)
            filterStack.addArrangedSubview(button)
        }

        updateFilterButtons()
    }

    @objc private func filterChipTapped(_ sender: TFChip) {
        guard sender.tag < FilterType.allCases.count else { return }
        selectedFilter = FilterType.allCases[sender.tag]
        updateFilterButtons()
        applySnapshot()
    }

    private func updateFilterButtons() {
        for (index, button) in filterButtons.enumerated() {
            let filter = FilterType.allCases[index]
            button.isChipSelected = (filter == selectedFilter)
        }
    }

    private var filteredOutfits: [Outfit] {
        switch selectedFilter {
        case .all:
            outfits
        case .favorites:
            outfits.filter { ($0.note?.isEmpty == false) || $0.items.count >= 4 }
        case .summer:
            outfits.filter { outfit in
                outfit.items.contains(where: { $0.season == .summer || $0.season == .all })
            }
        }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = TFSpacing.md
        layout.minimumInteritemSpacing = TFSpacing.md
        layout.sectionInset = UIEdgeInsets(top: TFSpacing.md, left: TFSpacing.md, bottom: 96, right: TFSpacing.md)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(OutfitCell.self, forCellWithReuseIdentifier: OutfitCell.reuseId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemId in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OutfitCell.reuseId, for: indexPath
            ) as! OutfitCell
            if let outfit = self?.outfits.first(where: { $0.id == itemId }) {
                cell.configure(with: outfit)
            }
            return cell
        }
    }

    private func setupEmptyView() {
        emptyView = TFEmptyStateView(
            heroImageName: "TFOutfitBoardCool",
            title: localized("아직 저장된 코디가 없어요", "No Outfits Yet"),
            subtitle: localized("내 옷으로 첫 번째 코디를 만들어보세요", "Create your first look from pieces you own"),
            buttonTitle: localized("코디 만들기", "Create Outfit")
        )
        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.actionButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    @objc private func addTapped() {
        let editVC = OutfitEditViewController(context: context)
        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func fetchOutfits() {
        let descriptor = FetchDescriptor<Outfit>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        outfits = (try? context.fetch(descriptor)) ?? []
        plannerCountLabel.text = localized("저장 \(outfits.count)", "\(outfits.count) SAVED")
        applySnapshot()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(filteredOutfits.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: true)
        emptyView.isHidden = !filteredOutfits.isEmpty
    }

    private func localized(_ korean: String, _ english: String) -> String {
        TFAppLanguage.current() == .korean ? korean : english
    }
}

extension OutfitsListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let outfit = outfits.first(where: { $0.id == itemID })
        else { return }
        let detail = OutfitDetailViewController(context: context, outfit: outfit)
        navigationController?.pushViewController(detail, animated: true)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard
            let itemID = dataSource.itemIdentifier(for: indexPath),
            let outfit = outfits.first(where: { $0.id == itemID })
        else { return nil }
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            let delete = UIAction(title: CoreStrings.Common.delete, attributes: .destructive) { _ in
                self?.context.delete(outfit)
                try? self?.context.save()
                self?.fetchOutfits()
            }
            return UIMenu(children: [delete])
        })
    }
}

extension OutfitsListViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset: CGFloat = TFSpacing.md * 2
        let spacing: CGFloat = TFSpacing.md
        let width = floor((collectionView.bounds.width - inset - spacing) / 2)
        return CGSize(width: width, height: (width * 1.08) + 58)
    }
}
