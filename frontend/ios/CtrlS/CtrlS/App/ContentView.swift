//
//  ContentView.swift
//  CtrlS
//
//  Created by Дима on 13.03.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house")
                }

            SubscriptionsView()
                .tabItem {
                    Label("Подписки", systemImage: "rectangle.stack")
                }

            CalendarView()
                .tabItem {
                    Label("Календарь", systemImage: "calendar")
                }

            AnalyticsView()
                .tabItem {
                    Label("Аналитика", systemImage: "chart.bar")
                }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
        .tint(Color.purple)
    }
}

#Preview {
    ContentView()
}
