//
//  CtrlSApp.swift
//  CtrlS
//
//  Created by Дима on 13.03.2026.
//

import SwiftUI

@main
struct CtrlSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SessionManager.shared)
        }
    }
}
