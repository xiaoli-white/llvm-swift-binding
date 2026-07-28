// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "llvm-swift-binding",
    products: [
        .library(
            name: "LLVMSwiftBinding",
            targets: ["LLVMSwiftBinding"]
        ),
    ],
    targets: [
        .target(
            name: "LLVMSwiftBinding"
        ),
        .testTarget(
            name: "LLVMSwiftBindingTests",
            dependencies: ["LLVMSwiftBinding"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
