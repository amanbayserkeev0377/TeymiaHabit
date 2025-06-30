//
//  LiveActivityDevBundle.swift
//  LiveActivityDev
//
//  Created by Aman on 30/6/25.
//

import WidgetKit
import SwiftUI

@main
struct LiveActivityDevBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityDev()
        LiveActivityDevControl()
        LiveActivityDevLiveActivity()
    }
}
