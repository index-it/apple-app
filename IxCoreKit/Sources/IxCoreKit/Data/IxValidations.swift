enum IxValidations {
    enum List {
        static let minNameLength = 1
        static let maxNameLength = 100
    }

    enum Category {
        static let minNameLength = 1
        static let maxNameLength = 100
    }

    enum Item {
        static let minNameLength = 1
        static let maxNameLength = 200

        static let maxLinkLength = 500
        static let maxNoteLength = 3000
    }

    enum Task {
        static let minNameLength = 1
        static let maxNameLength = 200

        static let minDescriptionLength = 1
        static let maxDescriptionLength = 500

        static let maxSubtaskCount = 50
        static let maxSubtaskNameLength = 200
        static let maxRemindersCount = 10

        static let minimumPriority = 0
        static let maximumPriority = 4
    }
}
