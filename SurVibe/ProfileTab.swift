import SwiftUI

/// Profile tab — placeholder for user profile.
struct ProfileTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Profile")
                    .font(.title)
                Text("User profile coming in Sprint 1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Profile")
        }
        .accessibilityLabel("Profile tab")
    }
}

#Preview {
    ProfileTab()
}
