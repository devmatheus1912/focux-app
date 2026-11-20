import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Aviso local do fim do descanso aparece também com o app aberto ou fechado.
    UNUserNotificationCenter.current().delegate = self
    if let controller = window?.rootViewController as? FlutterViewController {
      canalNotificacoes = FlutterMethodChannel(
        name: "focux/notificacoes", binaryMessenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private var canalNotificacoes: FlutterMethodChannel?

  /// Ajustes do iPhone > Focux > Notificações > "Ajustes de notificação do
  /// Focux": abre Perfil > Notificações (providesAppNotificationSettings).
  /// O FlutterAppDelegate do Flutter atual já implementa o método (repassa aos
  /// plugins): override e super, senão o Xcode recusa o build.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    openSettingsFor notification: UNNotification?
  ) {
    super.userNotificationCenter(center, openSettingsFor: notification)
    canalNotificacoes?.invokeMethod("abrirAjustesDoApp", arguments: nil)
  }

  /// Entrega o redirect OAuth do Google Sign-In aos plugins registrados.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
