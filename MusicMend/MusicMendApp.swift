import SwiftUI

@main
struct MusicMendApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @AppStorage("defaultScanPath") private var defaultScanPath = ""
    @AppStorage("cleanURLs") private var cleanURLs = true
    @AppStorage("cleanSpam") private var cleanSpam = true
    @AppStorage("fixEncoding") private var fixEncoding = true

    var body: some View {
        TabView {
            Form {
                Section("Default Scan Location") {
                    TextField("Path", text: $defaultScanPath)
                    Text("Leave empty to use ~/Music/Music/Media.localized/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Metadata Cleaning") {
                    Toggle("Remove URLs from metadata fields", isOn: $cleanURLs)
                    Toggle("Remove spam text from metadata fields", isOn: $cleanSpam)
                    Toggle("Fix encoding artifacts", isOn: $fixEncoding)
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .formStyle(.grouped)
            .frame(width: 450, height: 300)
        }
        .padding()
    }
}
