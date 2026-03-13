//
//  ContentView.swift
//  CtrlS
//
//  Created by Дима on 13.03.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager.shared)
}
