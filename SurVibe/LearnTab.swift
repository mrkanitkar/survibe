import SVCore
import SwiftData
import SwiftUI

/// Learn tab — browse and study lessons.
///
/// Wraps `LessonLibraryView` in a NavigationStack and creates the
/// `LessonLibraryViewModel` with the current model context.
/// Navigation to `LessonDetailView` is handled via `.navigationDestination`.
struct LearnTab: View {
    // MARK: - Properties

    @Environment(\.modelContext)
    private var modelContext
    @State
    private var viewModel: LessonLibraryViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LessonLibraryView()
                        .environment(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Learn")
            .navigationDestination(for: Lesson.self) { lesson in
                LessonDetailView(lesson: lesson)
            }
        }
        .accessibilityLabel(AccessibilityHelper.tabLabel(for: "Learn"))
        .onAppear {
            if viewModel == nil {
                viewModel = LessonLibraryViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LearnTab()
        .modelContainer(for: Lesson.self, inMemory: true)
}
