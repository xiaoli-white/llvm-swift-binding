public enum LLVMError: Error {
    case targetNotFound(triple: String)
    case emitFailed(message: String)
    case parseFailed(message: String)
    case passRunFailed(message: String)
}

public extension LLVMError {
    static func isStringError(_ error: LLVMErrorRef) -> Bool {
        LLVMGetErrorTypeId(error) == LLVMGetStringErrorTypeId()
    }

    static func createStringError(_ message: String) -> LLVMErrorRef {
        message.withCString { LLVMCreateStringError($0) }
    }
}

public typealias FatalErrorHandler = @convention(c) (UnsafePointer<CChar>?) -> Void

public func enablePrettyStackTrace() {
    LLVMEnablePrettyStackTrace()
}

public func installFatalErrorHandler(_ handler: @escaping FatalErrorHandler) {
    LLVMInstallFatalErrorHandler(handler)
}

public func resetFatalErrorHandler() {
    LLVMResetFatalErrorHandler()
}
