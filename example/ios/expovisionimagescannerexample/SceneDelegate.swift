import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    // Get the AppDelegate
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

    // Create window for this scene
    window = UIWindow(windowScene: windowScene)
    window?.backgroundColor = UIColor.white

    // Set the AppDelegate's window to our scene window
    appDelegate.window = window

    // If React Native factory exists, use it to set up React Native
    if let factory = appDelegate.reactNativeFactory {
      factory.startReactNative(
        withModuleName: "main",
        in: window,
        launchOptions: nil
      )
    }

    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
  }
}