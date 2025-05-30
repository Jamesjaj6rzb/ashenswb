//
//  DashboardViewController.swift
//  DoT
//
//  Created by 이중엽 on 3/8/24.
//

import UIKit

final class DashboardViewController: BaseViewController<DashboardView> {
    
    var dataSource: UICollectionViewDiffableDataSource<DashboardCompositionalLayout, AnyHashable>!
    
    let dashboardVM = DashboardViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        dashboardVM.tripInfoFetchListener.data = ()
        dashboardVM.callExchangeAPIListener.data = ()
    }
    
    override func bindData() {
        
        // MARK: DashBoardVM
        // Trip Data Fetch Completion
        dashboardVM.tripInfoFetchCompleteListener.bind { [weak self] _ in
            
            guard let self else { return }
            
            update()
        }
        
        // Exchange Data Fetch Completion
        dashboardVM.exchangeFetchCompleteListener.bind { [weak self] _ in
            
            guard let self else { return }
            
            update()
        }
        
        // Add Exchange Data to Realm Completion
        dashboardVM.createExchangeCompletionListener.bind { [weak self] _ in
            
            guard let self else { return }
            
            update()
        }
        
        dashboardVM.outputLastUpdateDateListener.bind { [weak self] dateStr in
            
            guard let self else { return }
            
            update()
        }
    }
    
    override func configureCollectionView() {
        
        // plus Section Registration
        let plusSectionRegistration = UICollectionView.CellRegistration<PlusCollectionViewCell, AnyHashable> { [weak self] cell, indexPath, itemIdentifier in
            
            guard let self else { return }
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(plusTapped))
            
            cell.layoutView.addGestureRecognizer(tapGesture)
        }
        
        // EmptyOnComing Section Registration
        let emptyOnComingSectionRegistration = UICollectionView.CellRegistration<EmptyOnComingCollectionViewCell, AnyHashable> { cell, indexPath, itemIdentifier in
            
        }
        
        // tripCard Section Registration
        let tripCardSectionRegistration = UICollectionView.CellRegistration<TripCardCollectionViewCell, TripInfo> { [weak self] cell, indexPath, itemIdentifier in
            
            guard let self else { return }
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tripCardTapped))
            
            cell.layoutView.tag = indexPath.item
            cell.layoutView.addGestureRecognizer(tapGesture)
            cell.configure(data: itemIdentifier)
        }
        
        // onComing Section Registration
        let onComingSectionRegistration = UICollectionView.CellRegistration<TripCardCollectionViewCell, TripInfo> { [weak self] cell, indexPath, itemIdentifier in
            
            guard let self else { return }
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onComingCardTapped))
            
            cell.layoutView.tag = indexPath.item
            cell.layoutView.addGestureRecognizer(tapGesture)
            cell.configure(data: itemIdentifier)
        }
        
        // exchangeRate Section Registration
        let exchangeRateSectionRegistration = UICollectionView.CellRegistration<ExchangeRateCollectionViewCell, Exchange> { cell, indexPath, itemIdentifier in
            
            cell.configure(data: itemIdentifier)
        }
        
        // privacyPolicy Section Registration
        let privacyPolicySectionRegistration = UICollectionView.CellRegistration<PrivacyPolicyCollectionViewCell, AnyHashable> { [weak self] cell, indexPath, itemIdentifier in
         
            guard let self else { return }
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.policyLinkTapped))
            cell.privacyPolicyLinkLabel.isUserInteractionEnabled = true
            cell.privacyPolicyLinkLabel.addGestureRecognizer(tapGesture)
        }
        
        // Trip Card Header Registration
        let tripCardHeaderRegistration = UICollectionView.SupplementaryRegistration<TripCardCollectionReusableView>(elementKind: TripCardCollectionReusableView.identifier) { supplementaryView, elementKind, indexPath in
            
            guard let section = DashboardCompositionalLayout(rawValue: indexPath.section) else { return }
            
            switch section {
            case .tripCard:
                supplementaryView.configure("진행중인 여행")
            case .onComing:
                supplementaryView.configure("예정된 여행")
            default: break
            }
        }
        
        // exchangeRate Header Registration
        let exchangeRateHeaderRegistration = UICollectionView.SupplementaryRegistration<ExchangeRateCollectionReusableView>(elementKind: ExchangeRateCollectionReusableView.identifier) { [weak self] supplementaryView, elementKind, indexPath in
            
            guard let self else { return }
            
            let lastUpdatedDate = dashboardVM.outputLastUpdateDateListener.data
            supplementaryView.configure(lastUpdatedDate)
        }
        
        // Cell 등록
        dataSource = UICollectionViewDiffableDataSource(collectionView: layoutView.dashboardCollectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            
            guard let self, let section = DashboardCompositionalLayout(rawValue: indexPath.section) else { return nil }
            
            let tripInfoDatas = dashboardVM.tripInfoDatas
            let onComingDatas = dashboardVM.onComingDatas
            
            switch section {
            case .tripCard:
                
                if tripInfoDatas.isEmpty {
                    
                    let cell = collectionView.dequeueConfiguredReusableCell(using: plusSectionRegistration, for: indexPath, item: itemIdentifier)
                    
                    return cell
                    
                } else {
                    
                    guard let item: TripInfo = itemIdentifier as? TripInfo else { return nil }
                    
                    let cell = collectionView.dequeueConfiguredReusableCell(using: tripCardSectionRegistration, for: indexPath, item: item)
                    
                    return cell
                    
                }
                
            case .onComing:
                
                if onComingDatas.isEmpty {
                    
                    let cell = collectionView.dequeueConfiguredReusableCell(using: emptyOnComingSectionRegistration, for: indexPath, item: itemIdentifier)
                    
                    return cell
                    
                } else {
                    
                    guard let item: TripInfo = itemIdentifier as? TripInfo else { return nil }
                    
                    let cell = collectionView.dequeueConfiguredReusableCell(using: onComingSectionRegistration, for: indexPath, item: item)
                    
                    return cell
                    
                }
                
            case .exchangeRate:
                
                guard let item: Exchange = itemIdentifier as? Exchange else { return nil }
                
                let cell = collectionView.dequeueConfiguredReusableCell(using: exchangeRateSectionRegistration, for: indexPath, item: item)
                
                return cell
                
            case .privacyPolicy:
                
                let cell = collectionView.dequeueConfiguredReusableCell(using: privacyPolicySectionRegistration, for: indexPath, item: itemIdentifier)
                
                return cell
            }
        }
        
        // Header 등록
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            
            guard let self else { return nil }
            
            switch kind {
            case TripCardCollectionReusableView.identifier:
                
                return layoutView.dashboardCollectionView.dequeueConfiguredReusableSupplementary(
                    using: tripCardHeaderRegistration, for: index)
                
            case ExchangeRateCollectionReusableView.identifier:
                
                return layoutView.dashboardCollectionView.dequeueConfiguredReusableSupplementary(
                    using: exchangeRateHeaderRegistration, for: index)
                
            default: return nil
            }
            
        }
    }
    
    override func configureNavigation() {
        
        navigationItem.leftBarButtonItem = makeSymbolBarButtonItem()
        navigationItem.rightBarButtonItem = makeRightBarButtonItem(title: "새로운 여행")
    }
    
    override func rightBarButtonClicked(_ sender: UIButton) {
        
        let nextVC = CreateTripViewController()
        let naviVC = UINavigationController(rootViewController: nextVC)
        
        nextVC.createTripVM.dismissCallBack = { [weak self] in
            
            guard let self else { return }
            
            dashboardVM.tripInfoFetchListener.data = ()
        }
        
        present(naviVC, animated: true)
    }
    
    @objc func tripCardTapped(_ sender: UITapGestureRecognizer) {
        
        guard let layoutView = sender.view else { return }
        
        let tripInfoDatas = dashboardVM.tripInfoDatas
        let nextVC: TripDashboardViewController = TripDashboardViewController()
        nextVC.tripDashboardVM.tripInfo = tripInfoDatas[layoutView.tag]
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc func onComingCardTapped(_ sender: UITapGestureRecognizer) {
        
        guard let layoutView = sender.view else { return }
        
        let onComingDatas = dashboardVM.onComingDatas
        let nextVC: TripDashboardViewController = TripDashboardViewController()
        nextVC.tripDashboardVM.tripInfo = onComingDatas[layoutView.tag]
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc func plusTapped(_ sender: UITapGestureRecognizer) {
        
        let nextVC = CreateTripViewController()
        let naviVC = UINavigationController(rootViewController: nextVC)
        
        nextVC.createTripVM.dismissCallBack = { [weak self] in
            
            guard let self else { return }
            
            dashboardVM.tripInfoFetchListener.data = ()
        }
        
        present(naviVC, animated: true)
    }
    
    @objc func policyLinkTapped(_ sender: UITapGestureRecognizer) {
        
        openExternalLink(urlStr: "https://www.notion.so/DoT-efbfcc80d7a4447390ffb8777e77a387?pvs=4")
    }
}

extension DashboardViewController {
    
    private func update() {
        
        let tripInfoDatas = dashboardVM.tripInfoDatas
        let exchangeDatas = dashboardVM.exchangeDatas
        let onComingDatas = dashboardVM.onComingDatas
        
        var snapshot = NSDiffableDataSourceSnapshot<DashboardCompositionalLayout, AnyHashable>()
        snapshot.appendSections(DashboardCompositionalLayout.allCases)
        
        if tripInfoDatas.isEmpty {
            snapshot.appendItems(["TripCard"], toSection: .tripCard)
        } else {
            snapshot.deleteItems(["TripCard"])
            snapshot.appendItems(tripInfoDatas, toSection: .tripCard)
        }
        
        if onComingDatas.isEmpty {
            snapshot.appendItems(["OnComing"], toSection: .onComing)
        } else {
            snapshot.deleteItems(["OnComing"])
            snapshot.appendItems(onComingDatas, toSection: .onComing)
        }
        
        snapshot.appendItems(exchangeDatas, toSection: .exchangeRate)
        snapshot.appendItems(["privacyPolicy"], toSection: .privacyPolicy)
        
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
}
