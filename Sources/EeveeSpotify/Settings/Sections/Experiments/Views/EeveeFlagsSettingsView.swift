import SwiftUI
import UIKit

// Flags explorer: every remote-config flag the current Spotify binary ships
// (seeded from our own symbol dump), searchable, with a tri-state control per
// flag. Auto leaves Spotify's value; On/Off force the bool in the patched
// bootstrap/customize config. Takes effect on next launch.
struct EeveeFlagsSettingsView: View {
    @State private var searchText = ""
    @State private var overrides: [String: Bool] = EeveeFlagOverrides.active

    private var filteredFlags: [String] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return EeveeFlagCatalog.all }
        return EeveeFlagCatalog.all.filter { $0.lowercased().contains(query) }
    }

    private var overriddenCount: Int { overrides.count }

    var body: some View {
        List {
            Section(
                footer: Text("flags_explorer_footer".localized)
            ) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("flags_search_placeholder".localized, text: $searchText)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disableAutocorrection(true)

                if overriddenCount > 0 {
                    // Plain button with red tint: Button(role:) is iOS 15+ and
                    // Eevee still supports iOS 14.
                    Button {
                        EeveeFlagOverrides.removeAll()
                        overrides = [:]
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("flags_reset_all".localized)
                        }
                        .foregroundColor(.red)
                    }
                }
            }

            Section(
                header: Text("flags_count_header"
                    .localizeWithFormat("\(filteredFlags.count)")),
                footer: overriddenCount > 0
                    ? Text("flags_restart_footer".localized) : nil
            ) {
                ForEach(filteredFlags, id: \.self) { flag in
                    flagRow(flag)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("flags_explorer".localized)
    }

    @ViewBuilder
    private func flagRow(_ flag: String) -> some View {
        HStack {
            Text(flag)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Menu {
                Button {
                    setOverride(nil, for: flag)
                } label: {
                    if overrides[flag] == nil {
                        Label("flag_auto".localized, systemImage: "checkmark")
                    } else {
                        Text("flag_auto".localized)
                    }
                }
                Button {
                    setOverride(true, for: flag)
                } label: {
                    if overrides[flag] == true {
                        Label("flag_on".localized, systemImage: "checkmark")
                    } else {
                        Text("flag_on".localized)
                    }
                }
                Button {
                    setOverride(false, for: flag)
                } label: {
                    if overrides[flag] == false {
                        Label("flag_off".localized, systemImage: "checkmark")
                    } else {
                        Text("flag_off".localized)
                    }
                }
            } label: {
                Text(stateLabel(for: flag))
                    .font(.footnote.weight(.medium))
                    .foregroundColor(
                        overrides[flag] == nil
                            ? .secondary : EeveeSettingsView.spotifyAccentColor
                    )
            }
        }
    }

    private func stateLabel(for flag: String) -> String {
        switch overrides[flag] {
        case .some(true): return "flag_on".localized
        case .some(false): return "flag_off".localized
        case nil: return "flag_auto".localized
        }
    }

    private func setOverride(_ value: Bool?, for flag: String) {
        EeveeFlagOverrides.set(value, for: flag)
        overrides = EeveeFlagOverrides.active
        writeDebugLog("[Flags] \(flag) -> \(value.map { $0 ? "on" : "off" } ?? "auto")")
    }
}
