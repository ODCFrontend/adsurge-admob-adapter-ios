// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AdSurgeADNAdapterForAdMob",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(
      name: "AdSurgeADNAdapterForAdMob",
      targets: ["AdSurgeADNAdapterForAdMobTarget"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/ODCFrontend/adsurge-adn-ios.git", exact: "2.0.2"),
    .package(
      url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
      "12.0.0"..<"99.0.0"),
  ],
  targets: [
    .target(
      name: "AdSurgeADNAdapterForAdMobTarget",
      dependencies: [
        .target(name: "AdSurgeADNAdapterForAdMob"),
        .product(name: "AdSurgeSDK", package: "adsurge-adn-ios"),
        .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
      ],
      path: "AdSurgeADNAdapterForAdMobTarget"
    ),
    .binaryTarget(
      name: "AdSurgeADNAdapterForAdMob",
      url:
        "https://github.com/ODCFrontend/adsurge-admob-adapter-ios/releases/download/2.0.200/AdSurgeADNAdapterForAdMob.zip",
      checksum: "cdf8882bed38ecec6374accd0d2005899a2e621575459aee71515d2cd62459a9"
    ),
  ]
)
