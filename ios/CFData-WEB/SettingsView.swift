import SwiftUI
import WebKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var backendManager: BackendManager

    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("remoteServerURL") private var remoteServerURL: String = ""
    @State private var connectionMode: BackendMode = .local
    @State private var remoteURLInput: String = ""
    @State private var showClearCacheAlert = false

    var body: some View {
        NavigationStack {
            Form {
                connectionSection
                appearanceSection
                aboutSection
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                connectionMode = backendManager.mode
                remoteURLInput = remoteServerURL
            }
            .alert("清除缓存", isPresented: $showClearCacheAlert) {
                Button("清除", role: .destructive) { clearCache() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将清除 WebView 缓存和本地存储数据？")
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section("连接设置") {
            Picker("连接模式", selection: $connectionMode) {
                Text("本地模式（内置后端）").tag(BackendMode.local)
                Text("远程模式（外部服务器）").tag(BackendMode.remote)
            }
            .onChange(of: connectionMode) { _, newMode in
                backendManager.switchMode(to: newMode)
            }

            if connectionMode == .remote {
                TextField("服务器地址", text: $remoteURLInput)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        remoteServerURL = remoteURLInput
                        backendManager.updateRemoteURL(remoteURLInput)
                    }

                Text("输入远程 CFData 服务器的完整地址，例如 http://192.168.1.100:13335")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("状态")
                Spacer()
                if backendManager.isRunning {
                    Label("已连接", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("未连接", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }

            if !backendManager.isRunning {
                Button("重新连接") {
                    backendManager.retry()
                }
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("外观") {
            Toggle("深色模式", isOn: $useDarkMode)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("应用名称")
                Spacer()
                Text("CFData-WEB")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("版本")
                Spacer()
                Text("1.0")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("后端版本")
                Spacer()
                Text(backendManager.isRunning ? "运行中" : "未运行")
                    .foregroundColor(.secondary)
            }

            Button("清除缓存", role: .destructive) {
                showClearCacheAlert = true
            }
        }
    }

    private func clearCache() {
        let dataTypes = Set([
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage
        ])
        let date = Date.distantPast
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: date) {}
    }
}