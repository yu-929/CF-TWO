import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    var onDarkModeChange: ((Bool) -> Void)?
    var onExportFile: ((String, String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.suppressesIncrementalRendering = false
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        if #available(iOS 14.0, *) {
            config.limitsNavigationsToAppBoundDomains = false
        }

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "CFDataiOS")
        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        loadURL(webView: webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != url.absoluteString {
            loadURL(webView: webView)
        }
    }

    private func loadURL(webView: WKWebView) {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        webView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.injectExportBridge(webView: webView)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               navigationAction.navigationType == .linkActivated {
                if url.host == "127.0.0.1" || url.host == "localhost" {
                    decisionHandler(.allow)
                    return
                }
                if url.scheme == "http" || url.scheme == "https" {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }

            if let action = body["action"] as? String {
                switch action {
                case "saveFile":
                    if let fileName = body["fileName"] as? String,
                       let content = body["content"] as? String {
                        parent.onExportFile?(fileName, content)
                    }
                case "darkModeChanged":
                    if let isDark = body["isDark"] as? Bool {
                        parent.onDarkModeChange?(isDark)
                    }
                default:
                    break
                }
            }
        }

        private func injectExportBridge(webView: WKWebView) {
            let script = """
            (function() {
                if (window.__cfdataiOSExport) return;
                window.__cfdataiOSExport = true;
                var oldDownload = window.downloadFile;
                window.downloadFile = function(content, nameBase, ext) {
                    var ts = new Date().toISOString().replace(/[-:T]/g, '').split('.')[0];
                    var name = (nameBase || 'cfdata-results') + '_' + ts + '.' + (ext || 'txt');
                    window.webkit.messageHandlers.CFDataiOS.postMessage({
                        action: 'saveFile',
                        fileName: name,
                        content: String(content || '')
                    });
                };
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}