import SwiftUI
import AppKit

struct SearchView: View {
    @ObservedObject var state: SearchState
    let onLaunch: (LaunchItem) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 20))
                TextField("Search...", text: $state.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22))
                    .onSubmit {
                        if let item = state.selectedItem {
                            onLaunch(item)
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // Results list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(state.filteredItems.prefix(50).enumerated()), id: \.element.id) { index, item in
                            ResultRow(item: item, isSelected: index == state.selectedIndex, shortcutNumber: index < 9 ? index + 1 : nil)
                                .id(item.id)
                                .contentShape(Rectangle())
                                .onTapGesture { onLaunch(item) }
                        }
                    }
                }
                .onChange(of: state.selectedIndex) { _ in
                    if let item = state.filteredItems[safe: state.selectedIndex] {
                        withAnimation(.linear(duration: 0.05)) {
                            proxy.scrollTo(item.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 680, height: 420)
        .background(VisualEffectBlur())
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let item: LaunchItem
    let isSelected: Bool
    let shortcutNumber: Int?

    var body: some View {
        HStack(spacing: 10) {
            itemIcon
                .frame(width: 28, height: 28)
            Text(item.name)
                .font(.system(size: 15))
                .lineLimit(1)
            Spacer()
            if isSelected {
                KeyCap("return")
            } else if let n = shortcutNumber {
                KeyCap("\u{2318}\(n)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
    }

    @ViewBuilder
    private var itemIcon: some View {
        switch item.kind {
        case .application:
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .systemSetting:
            Image(systemName: "gear")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        case .action:
            Image(systemName: "terminal")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Key Cap

struct KeyCap: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.system(size: 11, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.15))
            )
    }
}

// MARK: - Visual Effect

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Safe Collection Subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
