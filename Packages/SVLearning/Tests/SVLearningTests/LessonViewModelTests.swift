import Testing
@testable import SVLearning

@Suite("LessonViewModel Tests")
struct LessonViewModelTests {
    @Test("Initial state is not playing")
    @MainActor
    func testInitialState() {
        let vm = LessonViewModel()
        #expect(vm.isPlaying == false)
        #expect(vm.progress == 0.0)
    }

    @Test("Play sets isPlaying to true")
    @MainActor
    func testPlay() {
        let vm = LessonViewModel()
        vm.play()
        #expect(vm.isPlaying == true)
    }

    @Test("Pause sets isPlaying to false")
    @MainActor
    func testPause() {
        let vm = LessonViewModel()
        vm.play()
        vm.pause()
        #expect(vm.isPlaying == false)
    }
}
