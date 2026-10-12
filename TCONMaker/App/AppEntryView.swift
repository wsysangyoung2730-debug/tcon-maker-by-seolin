import SwiftUI

/// Keeps first-launch guidance independent from photo processing and permissions.
struct AppEntryView: View {
  @AppStorage("hasCompletedOnboarding", store: onboardingDefaults)
  private var hasCompletedOnboarding = false
  @State private var showingTutorial = false

  init() {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--ui-reset-onboarding") {
        onboardingDefaults.removeObject(forKey: "hasCompletedOnboarding")
      }
    #endif
  }

  private var shouldShowWelcome: Bool {
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
        !ProcessInfo.processInfo.arguments.contains("--ui-onboarding")
      {
        return false
      }
    #endif
    return !hasCompletedOnboarding
  }

  var body: some View {
    Group {
      if shouldShowWelcome {
        WelcomeView(
          onStart: { hasCompletedOnboarding = true },
          onTutorial: { showingTutorial = true })
      } else {
        RootView()
      }
    }.tint(.seolin)
      .fullScreenCover(isPresented: $showingTutorial) {
        TutorialView(
          isOnboarding: true,
          onClose: { showingTutorial = false },
          onComplete: {
            showingTutorial = false
            hasCompletedOnboarding = true
          })
      }
  }
}

private var onboardingDefaults: UserDefaults {
  #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      return UserDefaults(suiteName: "com.seolin.tconmaker.onboarding-tests")!
    }
  #endif
  return .standard
}
