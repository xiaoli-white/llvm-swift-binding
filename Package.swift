// swift-tools-version: 6.3
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
        .systemLibrary(
            name: "cLLVM",
            path: "Sources/cLLVM",
            pkgConfig: "llvm",
            providers: [
                .brew(["llvm"]),
                .apt(["llvm-dev"]),
            ]
        ),
        .target(
            name: "LLVMSwiftBinding",
            dependencies: ["cLLVM"]
        ),
        .testTarget(
            name: "LLVMSwiftBindingTests",
            dependencies: ["LLVMSwiftBinding"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
