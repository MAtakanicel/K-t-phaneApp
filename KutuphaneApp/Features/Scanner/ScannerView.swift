import SwiftUI
import AVFoundation
#if canImport(VisionKit)
import VisionKit
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif

// §6.9 — Barkod tarayıcı (full-screen).
// Koyu kamera zemini, 236px hedef çerçevesi, accent tarama çizgisi,
// bağlama göre başlık. İki kullanım: ISBN ve üye kartı.

enum ScannerMode {
    case isbn
    case memberCard

    var title: String {
        switch self {
        case .isbn:       return "ISBN okutun"
        case .memberCard: return "Üye kartı okutun"
        }
    }

    var hint: String {
        switch self {
        case .isbn:       return "Kitabın barkodunu çerçeveye yerleştir."
        case .memberCard: return "Üye kartının barkodunu çerçeveye yerleştir."
        }
    }
}

// MARK: - Sheet ana görünümü

@MainActor
struct ScannerView: View {
    let mode: ScannerMode
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var permission: PermissionState = .unknown
    @State private var deviceError: String? = nil

    enum PermissionState { case unknown, denied, granted }

    var body: some View {
        ZStack {
            Color(red: 0.043, green: 0.043, blue: 0.047) // #0B0B0C
                .ignoresSafeArea()

            content

            VStack {
                header
                Spacer()
                if permission == .granted, deviceError == nil {
                    Text(mode.hint)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 48)
                }
            }
        }
        .task {
            ScannerDiagnostics.logEnvironment(mode: mode)
            await requestPermission()
        }
    }

    // MARK: İçerik (izin/cihaz durumuna göre)

    @ViewBuilder
    private var content: some View {
        if let deviceError {
            errorState(message: deviceError)
        } else {
            switch permission {
            case .unknown:
                ProgressView().tint(.white)
            case .denied:
                permissionDeniedState
            case .granted:
                scannerWithOverlay
            }
        }
    }

    private var scannerWithOverlay: some View {
        ZStack {
            #if canImport(VisionKit)
            DataScannerRepresentable(
                mode: mode,
                onScan: { code in
                    onScan(code)
                    dismiss()
                },
                onError: { msg in deviceError = msg }
            )
            .ignoresSafeArea()
            #endif
            ScannerOverlay()
        }
    }

    private var header: some View {
        HStack {
            Text(mode.title)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .accessibilityLabel("Kapat")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: D4 — hata state'leri

    private var permissionDeniedState: some View {
        ScannerMessageView(
            icon: "camera.fill",
            title: "Kamera izni gerekli",
            description: "Barkod okumak için Ayarlar'dan kamera iznini aç.",
            actionTitle: "Ayarları Aç"
        ) {
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            #endif
        }
    }

    private func errorState(message: String) -> some View {
        ScannerMessageView(
            icon: "exclamationmark.triangle.fill",
            title: "Tarayıcı kullanılamıyor",
            description: message,
            actionTitle: "Kapat",
            destructive: true,
            action: { dismiss() }
        )
    }

    // MARK: İzin

    private func requestPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("[Scanner] camera authorization status=\(status.rawValue) (\(String(describing: status)))")
        switch status {
        case .authorized:
            permission = .granted
        case .notDetermined:
            let ok = await AVCaptureDevice.requestAccess(for: .video)
            print("[Scanner] requestAccess result=\(ok)")
            permission = ok ? .granted : .denied
        case .denied, .restricted:
            permission = .denied
        @unknown default:
            permission = .denied
        }
        print("[Scanner] permission state=\(permission)")
    }
}

// MARK: - Diagnostics

enum ScannerDiagnostics {
    static func logEnvironment(mode: ScannerMode) {
        let plist = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String
        print("[Scanner] opening mode=\(mode) NSCameraUsageDescription=\(plist ?? "<MISSING — Info.plist anahtarı yok>")")
        #if canImport(VisionKit)
        print("[Scanner] DataScannerViewController.isSupported=\(DataScannerViewController.isSupported) isAvailable=\(DataScannerViewController.isAvailable)")
        #else
        print("[Scanner] VisionKit not importable on this platform")
        #endif
    }
}

// MARK: - Overlay (hedef çerçevesi + tarama çizgisi)

private struct ScannerOverlay: View {
    private let frameSize: CGFloat = 236
    @State private var lineOffset: CGFloat = -106

    var body: some View {
        ZStack {
            ScannerFrameShape()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: frameSize, height: frameSize)

            Rectangle()
                .fill(Color.appAccent)
                .frame(width: frameSize - 24, height: 2)
                .offset(y: lineOffset)
        }
        .frame(width: frameSize, height: frameSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                lineOffset = 106
            }
        }
    }
}

private struct ScannerFrameShape: Shape {
    let bracketLength: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let L = bracketLength

        // Sol-üst
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + L))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + L, y: rect.minY))

        // Sağ-üst
        p.move(to: CGPoint(x: rect.maxX - L, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + L))

        // Sol-alt
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - L))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + L, y: rect.maxY))

        // Sağ-alt
        p.move(to: CGPoint(x: rect.maxX - L, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - L))

        return p
    }
}

// MARK: - Mesaj görünümü (izin/hata)

private struct ScannerMessageView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(destructive ? Color.appWarnText : Color.white.opacity(0.9))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: action) {
                Text(actionTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(32)
    }
}

// MARK: - VisionKit wrapper

#if canImport(VisionKit)
struct DataScannerRepresentable: UIViewControllerRepresentable {
    let mode: ScannerMode
    let onScan: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        guard DataScannerViewController.isSupported else {
            DispatchQueue.main.async {
                onError("Bu cihaz barkod tarayıcıyı desteklemiyor. Gerçek cihazda dene.")
            }
            return UIViewController()
        }
        guard DataScannerViewController.isAvailable else {
            DispatchQueue.main.async {
                onError("Kamera şu an kullanılamıyor.")
            }
            return UIViewController()
        }

        let symbologies: Set<DataScannerViewController.RecognizedDataType>
        switch mode {
        case .isbn:
            symbologies = [.barcode(symbologies: [.ean13, .ean8])]
        case .memberCard:
            symbologies = [.barcode(symbologies: [.ean13, .ean8, .code128, .code39, .qr])]
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: symbologies,
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator

        do {
            try scanner.startScanning()
        } catch {
            DispatchQueue.main.async {
                onError("Tarayıcı başlatılamadı: \(error.localizedDescription)")
            }
        }
        return scanner
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var fired = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            if let first = addedItems.first { handle(first) }
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) {
            handle(item)
        }

        private func handle(_ item: RecognizedItem) {
            guard !fired else { return }
            if case .barcode(let barcode) = item,
               let value = barcode.payloadStringValue,
               !value.isEmpty {
                fired = true
                onScan(value)
            }
        }
    }
}
#endif

// MARK: - Preview

#Preview("ISBN — izin yok") {
    ScannerPreviewWrapper(mode: .isbn, simulate: .denied)
}

#Preview("Üye kartı — hata") {
    ScannerPreviewWrapper(mode: .memberCard, simulate: .deviceError)
}

#Preview("ISBN — overlay") {
    ScannerPreviewWrapper(mode: .isbn, simulate: .overlay)
}

// Preview yardımcı görünümü — gerçek kamera olmadan UI state'leri sergiler.
private struct ScannerPreviewWrapper: View {
    enum Sim { case denied, deviceError, overlay }
    let mode: ScannerMode
    let simulate: Sim

    var body: some View {
        ZStack {
            Color(red: 0.043, green: 0.043, blue: 0.047).ignoresSafeArea()

            switch simulate {
            case .denied:
                ScannerMessagePreview(
                    icon: "camera.fill",
                    title: "Kamera izni gerekli",
                    description: "Barkod okumak için Ayarlar'dan kamera iznini aç.",
                    actionTitle: "Ayarları Aç"
                )
            case .deviceError:
                ScannerMessagePreview(
                    icon: "exclamationmark.triangle.fill",
                    title: "Tarayıcı kullanılamıyor",
                    description: "Bu cihaz barkod tarayıcıyı desteklemiyor.",
                    actionTitle: "Kapat",
                    destructive: true
                )
            case .overlay:
                ScannerOverlay()
            }

            VStack {
                HStack {
                    Text(mode.title).font(.headline).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2).foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.horizontal, 20).padding(.top, 16)
                Spacer()
                if simulate == .overlay {
                    Text(mode.hint)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .padding(.bottom, 48)
                }
            }
        }
    }
}

private struct ScannerMessagePreview: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String
    var destructive: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(destructive ? Color.appWarnText : Color.white.opacity(0.9))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text(actionTitle)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(32)
    }
}
