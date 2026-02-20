//
//  TaskSwipeOrLongPressTip.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 20/02/26.
//

import TipKit

struct TaskSwipeOrLongPressTip: Tip {
    @Parameter
    static var atLeastOneTodayTask: Bool = false
    
    var rules: [Rule] {
        #Rule(Self.$atLeastOneTodayTask) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }
    
    var title: Text {
        Text("Swipe a Task!")
    }


    var message: Text? {
        Text("Swipe or long press a task for some quick actions.")
    }


    var image: Image? {
        Image(systemName: "hand.point.up.left.and.text")
    }
}
