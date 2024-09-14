/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A bundle of widgets for the RecordThing app.
*/

import WidgetKit
import SwiftUI

@main
struct RecordThingWidgets: WidgetBundle {
    var body: some Widget {
        FeaturedSmoothieWidget()
        RewardsCardWidget()
    }
}
