import Foundation
import Network

enum BackendMode: String, Codable {
    case local
    case remote
}

@MainActor
class BackendManager: ObservableObject {
    static let shared = BackendManager()

    @Published var backendURL: String = "http://127.0.0.1:13335"
    @Published var isRunning = false
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var mode: BackendMode = .local

    @AppStorage("remoteServerURL") var remoteServerURL: String = ""
    @AppStorage("connectionMode") private var storedMode: String = BackendMode.local.rawValue

    private var localProcess: Process?
    private let port: Int = 13335
    private let maxRetries = 15
    private let retryInterval: useconds_t = 500_000

    private init() {
        mode = BackendMode(rawValue: storedMode) ?? .local
        updateBackendURL()
    }

    func start() {
        isLoading = true
        errorMessage = nil

        switch mode {
        case .local:
            startLocalBackend()
        case .remote:
            startRemoteMode()
        }
    }

    func switchMode(to newMode: BackendMode) {
        stopLocalBackend()
        mode = newMode
        storedMode = newMode.rawValue
        updateBackendURL()
        start()
    }

    private func updateBackendURL() {
        switch mode {
        case .local:
            backendURL = "http://127.0.0.1:\(port)"
        case .remote:
            let url = remoteServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if url.isEmpty {
                backendURL = "http://127.0.0.1:\(port)"
            } else {
                var cleanURL = url
                if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
                    cleanURL = "http://" + cleanURL
                }
                backendURL = cleanURL.hasSuffix("/") ? String(cleanURL.dropLast()) : cleanURL
            }
        }
    }

    func updateRemoteURL(_ url: String) {
        remoteServerURL = url
        updateBackendURL()
        if mode == .remote {
            start()
        }
    }

    private func startLocalBackend() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            guard let backendPath = Bundle.main.path(forResource: "cfdata", ofType: nil) else {
                Task { @MainActor in
                    self.isLoading = false
                    self.errorMessage = "未找到内置后端文件 cfdata，请确保已通过编译脚本将 Go 后端打包到 App 中"
                }
                return
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: backendPath)
            process.arguments = ["-host", "127.0.0.1", "-port", String(self.port)]
            process.currentDirectoryURL = FileManager.default.temporaryDirectory

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                self.localProcess = process

                if self.waitForBackend() {
                    Task { @MainActor in
                        self.isRunning = true
                        self.isLoading = false
                        self.errorMessage = nil
                    }
                } else {
                    process.terminate()
                    Task { @MainActor in
                        self.isLoading = false
                        self.errorMessage = "本地后端启动超时（15秒），请检查 cfdata 二进制文件是否兼容 iOS"
                    }
                }
            } catch {
                Task { @MainActor in
                    self.isLoading = false
                    self.errorMessage = "启动本地后端失败: \(error.localizedDescription)"
                }
            }
        }
    }

    private func waitForBackend() -> Bool {
        let deadline = DispatchTime.now() + .seconds(15)
        while DispatchTime.now() < deadline {
            if checkBackendReady() {
                return true
            }
            usleep(retryInterval)
        }
        return false
    }

    private func checkBackendReady() -> Bool {
        let url = URL(string: "http://127.0.0.1:\(port)/favicon.png")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 1
        let semaphore = DispatchSemaphore(value: 0)
        var ready = false

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode < 500 {
                ready = true
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 2)
        return ready
    }

    private func startRemoteMode() {
        updateBackendURL()

        guard let url = URL(string: backendURL) else {
            isLoading = false
            errorMessage = "无效的远程服务器地址"
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            var request = URLRequest(url: url)
            request.timeoutInterval = 10

            let semaphore = DispatchSemaphore(value: 0)
            var reachable = false

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode < 500 {
                    reachable = true
                }
                semaphore.signal()
            }.resume()

            _ = semaphore.wait(timeout: .now() + 10)

            Task { @MainActor in
                self.isLoading = false
                if reachable {
                    self.isRunning = true
                    self.errorMessage = nil
                } else {
                    self.isRunning = false
                    self.errorMessage = "无法连接到远程服务器 \(self.backendURL)"
                }
            }
        }
    }

    func stopLocalBackend() {
        localProcess?.terminate()
        localProcess = nil
        isRunning = false
    }

    func retry() {
        stopLocalBackend()
        start()
    }
}