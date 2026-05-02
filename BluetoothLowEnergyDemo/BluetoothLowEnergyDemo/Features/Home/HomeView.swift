import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 新しい機能は AppFeature.all に追加するだけで自動的にカードが増える。
                ForEach(viewModel.features) { feature in
                    FeatureCard(feature: feature) {
                        // feature.id は AppRoute と一致するため、そのまま push できる。
                        router.push(feature.id)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("BLE Demo")
    }
}

/// HomeView のみで使用するため private で定義する。
private struct FeatureCard: View {
    let feature: AppFeature
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: feature.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(feature.color)
                    .frame(width: 56, height: 56)
                    .background(feature.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(feature.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppRouter())
}
