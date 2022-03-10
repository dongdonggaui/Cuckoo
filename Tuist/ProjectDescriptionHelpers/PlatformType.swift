import ProjectDescription

public enum PlatformType: String {
    case iOS
    case macOS
    case tvOS

    public var platform: Platform {
        switch self {
        case .iOS:
            return .iOS
        case .macOS:
            return .macOS
        case .tvOS:
            return .tvOS
        }
    }
}
