import cLLVM

func disposeMessage(_ message: UnsafeMutablePointer<CChar>?) {
    if let msg = message {
        LLVMDisposeMessage(msg)
    }
}

func errorMessage(from pointer: UnsafeMutablePointer<CChar>?) -> String {
    guard let ptr = pointer else { return "unknown error" }
    let str = String(cString: ptr)
    LLVMDisposeMessage(ptr)
    return str
}

func errorMessage(from error: LLVMErrorRef) -> String {
    let ptr = LLVMGetErrorMessage(error)
    let str = String(cString: ptr!)
    LLVMDisposeErrorMessage(ptr)
    return str
}

func cString(_ str: String) -> UnsafeMutablePointer<CChar> {
    let count = str.utf8.count + 1
    let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: count)
    str.withCString { src in
        ptr.initialize(from: src, count: count)
    }
    return ptr
}

public enum LLVMSupport {
    @discardableResult
    public static func loadLibraryPermanently(_ filename: String) -> Bool {
        filename.withCString { LLVMLoadLibraryPermanently($0) == 0 }
    }

    public static func parseCommandLineOptions(_ args: [String], overview: String = "") {
        var argv: [UnsafePointer<CChar>?] = args.map { arg in
            arg.withCString { ptr in
                let copy = UnsafeMutablePointer<CChar>.allocate(capacity: arg.utf8.count + 1)
                copy.initialize(from: ptr, count: arg.utf8.count + 1)
                return UnsafePointer(copy)
            }
        }
        defer {
            for ptr in argv {
                ptr.map { UnsafeMutablePointer(mutating: $0) }?.deallocate()
            }
        }
        overview.withCString { overviewPtr in
            argv.withUnsafeBufferPointer { buffer in
                LLVMParseCommandLineOptions(Int32(args.count), buffer.baseAddress, overviewPtr)
            }
        }
    }

    public static func searchForAddressOfSymbol(_ name: String) -> UnsafeMutableRawPointer? {
        name.withCString { LLVMSearchForAddressOfSymbol($0) }
    }

    public static func addSymbol(_ name: String, value: UnsafeMutableRawPointer) {
        name.withCString { LLVMAddSymbol($0, value) }
    }
}
