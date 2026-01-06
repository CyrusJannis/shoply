//
//  ShoplyWidgetLiveActivity.swift
//  ShoplyWidget
//
//  Created by Jannis Dietrich on 12/7/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ShoplyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ShoplyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShoplyWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ShoplyWidgetAttributes {
    fileprivate static var preview: ShoplyWidgetAttributes {
        ShoplyWidgetAttributes(name: "World")
    }
}

extension ShoplyWidgetAttributes.ContentState {
    fileprivate static var smiley: ShoplyWidgetAttributes.ContentState {
        ShoplyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ShoplyWidgetAttributes.ContentState {
         ShoplyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ShoplyWidgetAttributes.preview) {
   ShoplyWidgetLiveActivity()
} contentStates: {
    ShoplyWidgetAttributes.ContentState.smiley
    ShoplyWidgetAttributes.ContentState.starEyes
}
