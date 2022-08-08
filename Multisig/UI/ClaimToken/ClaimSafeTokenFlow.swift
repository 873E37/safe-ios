//
//  ClaimSafeTokenFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class ClaimSafeTokenFlow: UIFlow {
    var factory: ClaimSafeTokenFlowFactory!
    var safe: Safe
    var transaction: SCGModels.TransactionDetails?

    init(safe: Safe,
         factory: ClaimSafeTokenFlowFactory = ClaimSafeTokenFlowFactory(),
         completion: @escaping (_ success: Bool) -> Void) {
        self.safe = safe
        self.factory = factory
        super.init(completion: completion)
    }

    override func start() {
        //TODO remove workaround and check claim availability
        if safe.addressValue == Address(exactly: "0xfF501B324DC6d78dC9F983f140B9211c3EdB4dc7") {
            // if not available show not available
            showNotAvailable()
        } else {
            // if available show intro
           showIntro()
        }

    }

    func showIntro() {
        let vc = factory.claimGetStarted { [unowned self] in
            chooseDelegateIntro()
        }
        show(vc)
    }

    func showNotAvailable() {
        let vc = factory.claimNotAvailable()
        show(vc)
    }

    func chooseDelegateIntro() {
        let vc = factory.chooseDelegateIntro { [unowned self] in
            chooseGuardian()
        } onCustomAddress: { [unowned self] in
            enterCustomAddress()
        }
        show(vc)
    }

    func chooseGuardian() {
        let vc = factory.chooseGuardian() { [unowned self] guardian in
            selectAmount(guardian: guardian)
        }
        show(vc)
    }

    func enterCustomAddress() {
        let vc = factory.enterCustomAddress(mainnet: self.safe.chain?.id == Chain.ChainID.ethereumMainnet) { [unowned self] address in
            let guardian = Guardian(
                name: nil,
                reason: nil,
                previousContribution: nil,
                address: address,
                ensName: nil,
                imageURLString: nil
            )
            selectAmount(guardian: guardian)
        }
        show(vc)
    }

    func selectAmount(guardian: Guardian) {
        let vc = factory.selectAmount(guardian: guardian) { [unowned self] in
            success()
        }
        show(vc)
    }

    func success() {
        assert(transaction != nil)
        //TODO: pass amount
        let successVC = factory.success (amount: "10") { [unowned self] in

            //                NotificationCenter.default.post(
            //                    name: .initiateTxNotificationReceived,
            //                    object: self,
            //                    userInfo: ["transactionDetails": transaction!])

            stop(success: true)
        }
        show(successVC)
    }
}

class ClaimSafeTokenFlowFactory {

    func claimGetStarted(onStartClaim: @escaping () -> ()) -> ClaimGetStartedViewController {
        let vc = ClaimGetStartedViewController()
        vc.onStartClaim = onStartClaim
        return vc
    }

    func claimNotAvailable() -> ClaimNotAvailableViewController {
        let vc = ClaimNotAvailableViewController()
        return vc
    }

    func chooseDelegateIntro(onChooseGuardian: @escaping () -> (),
                             onCustomAddress: @escaping () -> ()) -> ChooseDelegateIntroViewController{
        let vc = ChooseDelegateIntroViewController(stepNumber: 1,
                                                   maxSteps: 3,
                                                   onChooseGuardian: onChooseGuardian,
                                                   onCustomAddress: onCustomAddress)
        return vc
    }

    func chooseGuardian(_ onSelected: @escaping (Guardian) -> ()) -> SelectGuardianViewController {
        let vc = SelectGuardianViewController()
        vc.onSelected = onSelected
        return vc
    }

    func enterCustomAddress(mainnet: Bool, _ onContinue: @escaping (Address) -> ()) -> EnterCustomAddressViewController {
        let vc = EnterCustomAddressViewController()
        vc.mainnet = mainnet
        vc.onContinue = onContinue
        return vc
    }

    func selectAmount(guardian: Guardian, onClaim: @escaping () -> ()) -> ClaimingAmountViewController {
        let vc = ClaimingAmountViewController(guardian: guardian, onClaim: onClaim)
        return vc
    }

    func success(amount: String,
                 completion: @escaping () -> Void) -> ClaimSuccessViewController {
        let successVC = ClaimSuccessViewController()
        successVC.amount = amount
        successVC.onOk = completion
        return successVC
    }
}