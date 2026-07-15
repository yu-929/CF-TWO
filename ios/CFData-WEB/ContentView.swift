import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var backendManager: BackendManager
    @State private var isLoading = true
    @State private var showSettings = false
    @State private var showFileExporter = false
    @State private var exportData: (fileName: String, content: String)?
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let errorMsg = backendManager.errorMessage, !backendManager.isRunning {
                    errorView(errorMsg)
                } else if let url = URL(string: backendManager.backendURL) {
                    WebView(
                        url: url,
                        isLoading: $isLoading,
                        onDarkModeChange: { isDark in
                            DispatchQueue.main.async {
                                UIApplication.shared.connectedScenes
                                    .compactMap { $0 as? UIWindowScene }
                                    .first?.keyWindow?.overrideUserInterfaceStyle = isDark ? .dark : .light
                            }
                        },
                        onExportFile: { fileName, content in
                            DispatchQueue.main.async {
                                exportData = (fileName, content)
                                showFileExporter = true
                            }
                        }
                    )
                    .ignoresSafeArea()
                }

                if isLoading || backendManager.isLoading {
                    loadingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if backendManager.isRunning {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text(backendManager.mode == .local ? "本地" : "远程")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fileExporter(
                isPresented: $showFileExporter,
                document: exportData.map { TextFileDocument(text: $0.content) },
                contentType: .plainText,
                defaultFilename: exportData?.fileName ?? "cfdata-results.txt"
            ) { result in
                if case .failure(let error) = result {
                    print("导出失败: \(error.localizedDescription)")
                }
            }
            .alert("连接错误", isPresented: $showErrorAlert) {
                Button("重试") { backendManager.retry() }
                Button("设置") { showSettings = true }
                Button("取消", role: .cancel) {}
            } message: {
                Text(backendManager.errorMessage ?? "未知错误")
            }
            .onChange(of: backendManager.errorMessage) { newValue in
                if newValue != nil && !backendManager.isRunning {
                    showErrorAlert = true
                }
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("CFData")
                    .font(.title)
                    .fontWeight(.bold)

                Text(backendManager.isLoading ? "正在连接后端服务..." : "正在加载页面...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("连接失败")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { backendManager.retry() }) {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)

            Button(action: { showSettings = true }) {
                Label("设置", systemImage: "gear")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct TextFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}