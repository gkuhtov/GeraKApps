import SwiftUI

public struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var selectedTab: TabItem = .home
    @State private var showRandomChaos: Bool = false
    @State private var activeChaosExperiment: ExperimentItem?

    public init() {}

    public var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
            } else {
                mainLabInterface
            }
        }
    }

    private var mainLabInterface: some View {
        ZStack {
            LabBackgroundView()
                .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .lab:
                    LabView()
                case .random:
                    Color.clear
                case .favorites:
                    FavoritesView()
                case .history:
                    HistoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                Spacer()
                CustomLiquidTabBar(
                    selectedTab: $selectedTab,
                    onDiceTriggered: {
                        showRandomChaos = true
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showRandomChaos) {
            RandomChaosView(isPresented: $showRandomChaos) { exp in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activeChaosExperiment = exp
                }
            }
        }
        .fullScreenCover(item: $activeChaosExperiment) { exp in
            ExperimentExecutionView(experiment: exp)
        }
    }
}

private struct LabBackgroundView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LabTheme.backgroundDark

            Circle()
                .fill(LabTheme.cyanBeam.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: animate ? -90 : 70, y: animate ? -220 : -140)

            Circle()
                .fill(LabTheme.hazardOrange.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: animate ? 100 : -50, y: animate ? 250 : 180)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
