import Foundation

// User-forced remote-config flags, edited in Settings > Flags explorer.
//
// Tri-state per flag: auto (Spotify's value), on, off. Auto flags are absent
// from the store. Values ride the existing bootstrap/customize patching path
// (modifyAssignedValues), so they apply before Spotify parses the config and
// survive 304 replays via cachedCustomizeData. They do NOT require the
// overwrite-configuration switch and work alongside propertyReplacements —
// a user override always wins because it is applied last.
enum EeveeFlagOverrides {
    private static let defaultsKey = "EeveeFlagOverrides.v1"

    // Applied after the hardcoded propertyReplacements. Appends flags the
    // account's config omits (same pattern as forceBool there), so an override
    // works even when Spotify never assigned the property for this account.
    static var active: [String: Bool] {
        guard let raw = UserDefaults.standard.dictionary(forKey: defaultsKey)
                as? [String: Bool] else { return [:] }
        return raw
    }

    static func set(_ value: Bool?, for flag: String) {
        var current = active
        if let value { current[flag] = value } else { current.removeValue(forKey: flag) }
        if current.isEmpty {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        } else {
            UserDefaults.standard.set(current, forKey: defaultsKey)
        }
    }

    static func value(for flag: String) -> Bool? { active[flag] }

    static func removeAll() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    // Count of non-auto overrides, for the settings entry badge/footers.
    static var count: Int { active.count }

    // Bridge for modifyAssignedValues. Scoped lookup matches how Spotify
    // assigns flags: a flag may appear under several scopes, so a bare-name
    // override forces every occurrence (the catalog only stores bare names).
    static func forcedValue(forName name: String, scope: String?) -> Bool? {
        guard let forced = active[name] else { return nil }
        // Reserved for future scoped overrides ("scope/name" keys); bare
        // names apply globally and skip scoped keys.
        if let scope, active["\(scope)/\(name)"] != nil { return nil }
        return forced
    }
}
