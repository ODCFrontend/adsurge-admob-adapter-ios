// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdSurgeADNAdapterForAdMob",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AdSurgeADNAdapterForAdMob",
            targets: ["AdSurgeADNAdapterForAdMob"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ODCFrontend/adsurge-adn-ios.git", exact: "0.0.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "12.0.0"),
    ],
    targets: [
        .target(
            name: "AdSurgeADNAdapterForAdMob",
            dependencies: [
                .product(name: "AdSurgeSDK", package: "adsurge-adn-ios"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "AdSurgeADNAdapterForAdMob",
            publicHeadersPath: "."
        ),
    ]
)
