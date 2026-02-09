public enum IxValidations {
    public enum List {
        public static let minNameLength = 1
        public static let maxNameLength = 100
    }

    public enum ListInvite {
        public static let minDescriptionLength = 1
        public static let maxDescriptionLength = 100

        public static let minMaxUsages = 1
        public static let maxMaxUsages = 10000
    }

    public enum Category {
        public static let minNameLength = 1
        public static let maxNameLength = 100
    }

    public enum Item {
        public static let minNameLength = 1
        public static let maxNameLength = 200

        public static let maxLinkLength = 500
        public static let maxNoteLength = 3000
    }

    public enum Task {
        public static let minNameLength = 1
        public static let maxNameLength = 200

        public static let minDescriptionLength = 1
        public static let maxDescriptionLength = 500

        public static let maxSubtaskCount = 50
        public static let maxSubtaskNameLength = 200
        public static let maxRemindersCount = 10

        public static let minimumPriority = 0
        public static let maximumPriority = 4
    }
}
