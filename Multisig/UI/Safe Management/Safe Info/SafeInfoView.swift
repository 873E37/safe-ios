//
//  SafeInfoView.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// Info view split into two objects so that the content view would track
// changes to the safe, but the parent view tracks changes to the selection.
struct SafeInfoView: View {

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    var body: some View {
        ZStack {
            if selectedSafe.first == nil {
                BodyText("No Safe is selected")
            } else {
                SafeInfoContentView(safe: selectedSafe.first!)
            }
        }
    }
}

struct SafeInfoContentView: View {

    @ObservedObject var safe: Safe

    var body: some View {
        VStack (alignment: .center) {
            Identicon(safe.address).frame(width: 56, height: 56)
            BoldText(safe.displayName).padding(.top, 6)

            if safe.hasAddress {
                CenteredAddressWithLink(safe: safe).padding(.top, 3)
            }

            LoadableENSNameText(safe: safe, placeholder: "ENS name is not set")
            QRView(value: safe.address)
                .padding(.top, 12)
        }
        .multilineTextAlignment(.center)
    }

}

struct SafeInfoContentView_Previews: PreviewProvider {
    static var previews: some View {
        SafeInfoContentView(safe: Safe())
        .padding()
    }
}