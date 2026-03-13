import SwiftUI

struct MainTabView: View {
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
        .tint(DS.ColorToken.accent)
    }
}

#Preview {
    MainTabView()
}
