//
//  OnboardingViewController.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import SnapKit
import UIKit

public final class OnboardingViewController: UIViewController {
    public var onComplete: (() -> Void)?

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()

    private let pageControl = UIPageControl()
    private let nextButton = TFPrimaryButton(title: "Next")

    private let pages: [(icon: String, title: String, subtitle: String, bgColor: UIColor)] = [
        ("tshirt.fill", "Organize Your Wardrobe",
         "Keep all your clothes in one place.\nCategorize and search easily.",
         UIColor(hex: 0xFFF0F5)),
        ("person.crop.rectangle.stack.fill", "Save Your Outfits",
         "Create and save outfit combinations\nfor any occasion.",
         UIColor(hex: 0xF0F8FF)),
        ("suitcase.fill", "Pack Smart for Trips",
         "Create packing lists quickly.\nNever forget essentials again.",
         UIColor(hex: 0xF5F0FF)),
    ]

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = pages[0].bgColor

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: OnboardingCell.reuseId)

        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-20)
        }

        pageControl.numberOfPages = pages.count
        pageControl.currentPageIndicatorTintColor = TFColor.pink
        pageControl.pageIndicatorTintColor = TFColor.pink.withAlphaComponent(0.3)
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-24)
        }

        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
        }
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    @objc private func nextTapped() {
        let current = pageControl.currentPage
        if current < pages.count - 1 {
            let indexPath = IndexPath(item: current + 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            pageControl.currentPage = current + 1
            updateButtonTitle()
        } else {
            onComplete?()
        }
    }

    private func updateButtonTitle() {
        let isLast = pageControl.currentPage == pages.count - 1
        nextButton.setTitle(isLast ? "Get Started" : "Next", for: .normal)
    }
}

extension OnboardingViewController: UICollectionViewDataSource {
    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        pages.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnboardingCell.reuseId, for: indexPath
        ) as! OnboardingCell
        let page = pages[indexPath.item]
        cell.configure(icon: page.icon, title: page.title, subtitle: page.subtitle, bgColor: page.bgColor)
        return cell
    }
}

extension OnboardingViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = page
        updateButtonTitle()
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = self.pages[page].bgColor
        }
    }
}

private final class OnboardingCell: UICollectionViewCell {
    static let reuseId = "OnboardingCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 80, weight: .light)

        titleLabel.font = TFTypography.title
        titleLabel.textAlignment = .center
        titleLabel.textColor = TFColor.textPrimary

        subtitleLabel.font = TFTypography.bodyRegular
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = TFColor.textSecondary
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center

        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        iconView.snp.makeConstraints { $0.height.equalTo(120) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(icon: String, title: String, subtitle: String, bgColor: UIColor) {
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = TFColor.pink
        titleLabel.text = title
        subtitleLabel.text = subtitle
        contentView.backgroundColor = bgColor
    }
}
