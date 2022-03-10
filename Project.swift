import ProjectDescription
import ProjectDescriptionHelpers

let commonBuildSettingsBase: [String: SettingValue] = [
    "PRODUCT_NAME": .string("Cuckoo"),
    "SYSTEM_FRAMEWORK_SEARCH_PATHS": .string("$(PLATFORM_DIR)/Developer/Library/Frameworks"),
]
let objCBuildSettingsBase: [String: SettingValue] = [
    "SWIFT_OBJC_BRIDGING_HEADER": .string("$(PROJECT_DIR)/OCMock/Cuckoo-BridgingHeader.h"),
]

let defaultBuildSettings = Settings.settings(base: commonBuildSettingsBase)
let objCBuildSettings = Settings.settings(base: commonBuildSettingsBase.merging(objCBuildSettingsBase, uniquingKeysWith: { $1 }))

func platformSet(platform: PlatformType, deploymentTarget: DeploymentTarget?) -> (targets: [Target], schemes: [Scheme]) {
    var targets: [Target] = []
    var schemes: [Scheme] = []

    // MARK: Swift targets.
    let defaultTarget = Target(
        name: "Cuckoo-\(platform)",
        platform: platform.platform,
        product: .framework,
        bundleId: "org.brightify.Cuckoo",
        deploymentTarget: deploymentTarget,
        infoPlist: .default,
        sources: "Source/**",
        dependencies: [
            .sdk(name: "XCTest", type: .framework, status: .required),
        ],
        settings: defaultBuildSettings
    )
    targets.append(defaultTarget)

    let defaultTestTarget = Target(
        name: "Cuckoo-\(platform)Tests",
        platform: platform.platform,
        product: .unitTests,
        bundleId: "org.brightify.Cuckoo",
        infoPlist: .default,
        sources: [
            "Tests/Common/**",
            "Tests/Swift/**",
        ],
        dependencies: [
            .target(name: defaultTarget.name),
        ]
    )
    targets.append(defaultTestTarget)

    // MARK: ObjC targets.
    let objCTarget = Target(
        name: "Cuckoo_OCMock-\(platform)",
        platform: platform.platform,
        product: .framework,
        bundleId: "org.brightify.Cuckoo",
        deploymentTarget: deploymentTarget,
        infoPlist: .default,
        sources: [
            "Source/**",
            "OCMock/**",
        ],
        headers: .headers(public: ["OCMock/**"]),
        dependencies: [
            .sdk(name: "XCTest", type: .framework, status: .required),
        ],
        settings: objCBuildSettings
    )
    targets.append(objCTarget)

    let objCTestTarget = Target(
        name: "Cuckoo_OCMock-\(platform)Tests",
        platform: platform.platform,
        product: .unitTests,
        bundleId: "org.brightify.Cuckoo",
        infoPlist: .default,
        sources: [
            "Tests/Common/**",
            "Tests/OCMock/**",
        ],
        dependencies: [
            .target(name: objCTarget.name),
        ]
    )
    targets.append(objCTestTarget)

    // MARK: Schemes.
    schemes.append(
        Scheme(
            name: defaultTarget.name,
            buildAction: BuildAction.buildAction(targets: [defaultTarget.reference]),
            testAction: TestAction.targets(
                [.init(target: defaultTestTarget.reference)],
                preActions: [
                    ExecutionAction(
                        title: "Generate Mocks",
                        scriptText: #"""
                            ./run generate --testable "Cuckoo" --exclude "ExcludedTestClass,ExcludedProtocol" \
                            --output "$PROJECT_DIR"/Tests/Swift/Generated/GeneratedMocks.swift
                            --glob "$PROJECT_DIR"/Tests/Swift/Source/*.swift
                        """#
                    )
                ]
            )
        )
    )

    schemes.append(
        Scheme(
            name: objCTarget.name,
            shared: false,
            buildAction: .init(targets: [.init(stringLiteral: objCTarget.name)]),
            testAction: TestAction.targets([.init(target: objCTestTarget.reference)])
        )
    )

    return (targets, schemes)
}

let (iOSTargets, iOSSchemes) = platformSet(platform: .iOS, deploymentTarget: .iOS(targetVersion: "8.0", devices: [.iphone, .ipad]))
let (macOSTargets, macOSSchemes) = platformSet(platform: .macOS, deploymentTarget: .macOS(targetVersion: "10.9"))
let (tvOSTargets, tvOSSchemes) = platformSet(platform: .tvOS, deploymentTarget: nil)

// MARK: project definition
let project = Project(
    name: "Cuckoo",
    options: .options(automaticSchemesOptions: .disabled, disableSynthesizedResourceAccessors: true),
    packages: [
        // .remote(url: "https://github.com/erikdoe/ocmock", requirement: .revision("21cce26d223d49a9ab5ae47f28864f422bfe3951")),
    ],
    targets: iOSTargets + macOSTargets + tvOSTargets,
    schemes: iOSSchemes + macOSSchemes + tvOSSchemes,
    additionalFiles: [
        "Generator/CuckooGenerator.xcodeproj",
    ]
)
