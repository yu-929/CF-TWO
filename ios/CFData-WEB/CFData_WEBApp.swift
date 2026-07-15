import SwiftUI

@main
struct CFData_WEBApp: App {
    @StateObject private var backendManager = BackendManager.shared
    @AppStorage("useDarkMode") private var useDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(backendManager)
                .preferredColorScheme(useDarkMode ? .dark : nil)
                .onAppear {
                    backendManager.start()
                }
        }
    }
}