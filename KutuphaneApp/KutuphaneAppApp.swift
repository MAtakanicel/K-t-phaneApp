import SwiftUI
import FirebaseCore
#if canImport(UIKit)
import FirebaseAuth
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("[Firebase] GoogleService-Info.plist bulunamadı — Firebase başlatılmadı.")
            return true
        }
        FirebaseApp.configure()
        #if canImport(UIKit)
        Auth.auth().signInAnonymously { _, error in
            if let error {
                print("[Auth] Anonim giriş başarısız: \(error.localizedDescription)")
            }
        }
        #endif
        return true
    }
}

@main
struct KutuphaneAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
    }
}
