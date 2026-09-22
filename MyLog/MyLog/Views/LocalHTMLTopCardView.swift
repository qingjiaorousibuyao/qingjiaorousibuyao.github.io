import SwiftUI
import WebKit

struct LocalHTMLTopCardView: View {
    let resourceName: String
    @State private var contentHeight: CGFloat = 1

    var body: some View {
        LocalHTMLWebView(resourceName: resourceName, contentHeight: $contentHeight)
            .frame(maxWidth: .infinity)
            .frame(height: contentHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct LocalHTMLWebView: UIViewRepresentable {
    let resourceName: String
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: Coordinator.heightMessageName)
        controller.addUserScript(WKUserScript(
            source: Coordinator.heightObserverScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false

        if let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "html") {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.heightMessageName)
        webView.navigationDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let heightMessageName = "contentHeight"
        static let heightObserverScript = """
        (() => {
          const reportHeight = () => {
            const body = document.body;
            const root = document.documentElement;
            const height = Math.max(
              body ? body.scrollHeight : 0,
              body ? body.offsetHeight : 0,
              root ? root.scrollHeight : 0,
              root ? root.offsetHeight : 0
            );
            window.webkit.messageHandlers.contentHeight.postMessage(height);
          };
          new ResizeObserver(reportHeight).observe(document.documentElement);
          window.addEventListener('load', reportHeight);
          requestAnimationFrame(reportHeight);
        })();
        """

        private var contentHeight: Binding<CGFloat>

        init(contentHeight: Binding<CGFloat>) {
            self.contentHeight = contentHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { [weak self] value, _ in
                self?.updateHeight(value)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            updateHeight(message.body)
        }

        private func updateHeight(_ value: Any?) {
            let height: CGFloat?
            if let number = value as? NSNumber {
                height = CGFloat(truncating: number)
            } else if let number = value as? Double {
                height = CGFloat(number)
            } else {
                height = nil
            }

            guard let height, height.isFinite, height > 0 else { return }
            Task { @MainActor [weak self] in
                guard let self, abs(contentHeight.wrappedValue - height) > 0.5 else { return }
                contentHeight.wrappedValue = height
            }
        }
    }
}
