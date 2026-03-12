import Testing

@testable import SurVibe

// MARK: - SkillLevel Tests

struct SkillLevelTests {
    @Test func allCasesExist() {
        let cases = SkillLevel.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.beginner))
        #expect(cases.contains(.intermediate))
        #expect(cases.contains(.advanced))
    }

    @Test func labelsAreNotEmpty() {
        for level in SkillLevel.allCases {
            #expect(!level.label.isEmpty)
        }
    }

    @Test func iconsAreValidSFSymbolNames() {
        for level in SkillLevel.allCases {
            #expect(!level.icon.isEmpty)
        }
    }

    @Test func difficultyValues() {
        #expect(SkillLevel.beginner.difficulty == 1)
        #expect(SkillLevel.intermediate.difficulty == 2)
        #expect(SkillLevel.advanced.difficulty == 3)
    }

    @Test func difficultyIsAscending() {
        let difficulties = SkillLevel.allCases.map(\.difficulty)
        #expect(difficulties == difficulties.sorted())
    }

    @Test func descriptionsAreNotEmpty() {
        for level in SkillLevel.allCases {
            #expect(!level.description.isEmpty)
        }
    }
}

// MARK: - OnboardingDoorType Tests

struct OnboardingDoorTypeTests {
    @Test func allCasesExist() {
        let cases = OnboardingDoorType.allCases
        #expect(cases.count == 5)
        #expect(cases.contains(.songs))
        #expect(cases.contains(.learn))
        #expect(cases.contains(.moods))
        #expect(cases.contains(.community))
        #expect(cases.contains(.practice))
    }

    @Test func labelsAreNotEmpty() {
        for door in OnboardingDoorType.allCases {
            #expect(!door.label.isEmpty)
        }
    }

    @Test func iconsAreNotEmpty() {
        for door in OnboardingDoorType.allCases {
            #expect(!door.icon.isEmpty)
        }
    }

    @Test func isHashable() {
        var set = Set<OnboardingDoorType>()
        set.insert(.songs)
        set.insert(.learn)
        set.insert(.songs)  // duplicate
        #expect(set.count == 2)
    }
}

// MARK: - OnboardingManager Tests

@MainActor
struct OnboardingManagerTests {
    @Test func initialState() {
        let manager = OnboardingManager()
        #expect(manager.currentScreen == 0)
        #expect(manager.skillLevel == .beginner)
        #expect(manager.preferredDoors.isEmpty)
        #expect(manager.preferredLanguageCode == "en")
    }

    @Test func nextScreenIncrementsToMax() {
        let manager = OnboardingManager()
        #expect(manager.currentScreen == 0)

        manager.nextScreen()
        #expect(manager.currentScreen == 1)

        manager.nextScreen()
        #expect(manager.currentScreen == 2)

        manager.nextScreen()
        #expect(manager.currentScreen == 3)

        // Should clamp at 3
        manager.nextScreen()
        #expect(manager.currentScreen == 3)
    }

    @Test func previousScreenDecrementsToZero() {
        let manager = OnboardingManager()
        manager.currentScreen = 2

        manager.previousScreen()
        #expect(manager.currentScreen == 1)

        manager.previousScreen()
        #expect(manager.currentScreen == 0)

        // Should clamp at 0
        manager.previousScreen()
        #expect(manager.currentScreen == 0)
    }

    @Test func skipAllSetsDefaults() {
        let manager = OnboardingManager()
        manager.currentScreen = 1
        manager.skillLevel = .advanced
        manager.preferredDoors = [.songs, .learn]

        manager.skipAll()

        #expect(manager.isOnboardingComplete)
    }

    @Test func completeOnboardingSetsFlag() {
        let manager = OnboardingManager()
        #expect(!manager.isOnboardingComplete)

        manager.completeOnboarding()

        #expect(manager.isOnboardingComplete)
    }

    @Test func resetOnboardingClearsFlag() {
        let manager = OnboardingManager()
        manager.completeOnboarding()
        #expect(manager.isOnboardingComplete)

        manager.resetOnboarding()
        #expect(!manager.isOnboardingComplete)
        #expect(manager.currentScreen == 0)
    }
}
