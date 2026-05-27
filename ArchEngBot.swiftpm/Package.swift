// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "ArchEngBot",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "ArchEngBot",
            targets: ["AppModule"],
            bundleIdentifier: "com.archengbot.app",
            teamIdentifier: "",
            displayVersion: "0.1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .graduationcap),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight(.when(deviceFamilies: [.pad])),
                .landscapeLeft(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .microphone(purposeString: "App cần truy cập micro để ghi âm giọng đọc của bạn và chấm điểm phát âm bằng AI.")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: [
                "Resources/Config.json.example"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
