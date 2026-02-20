//
//  ItemSwipeOrPressTip.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 20/02/26.
//

import TipKit

struct ItemSwipeOrPressTip: Tip {
    @Parameter
    static var atLeastOneUncompletedItem: Bool = false
    
    var rules: [Rule] {
        #Rule(Self.$atLeastOneUncompletedItem) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }
    
    var title: Text {
        Text("Swipe an Item!")
    }


    var message: Text? {
        Text("Swipe or press an item for some quick actions.")
    }


    var image: Image? {
        Image(systemName: "hand.point.up.left.and.text")
    }
}
