//
//  DisplayPlusWidgetBundle.swift
//  DisplayPlusWidget
//
//  Created by Oliver Heisel on 9/10/25.
//

import WidgetKit
import SwiftUI

@main
struct DisplayPlusWidgetBundle: WidgetBundle {
    var body: some Widget {
        DisplayPlusWidget()
        //DisplayPlusWidgetControl()
        DisplayPlusWidgetLiveActivity()
    }
}
