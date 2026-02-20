//
//  LongPressToQuickAddItemsTip.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 20/02/26.
//


import TipKit

struct LongPressToQuickAddItemsTip: Tip {
    var title: Text {
        Text("Long press")
    }


    var message: Text? {
        Text("Long press to create multiple items.")
    }


    var image: Image? {
        Image(systemName: "hand.tap")
    }
}
