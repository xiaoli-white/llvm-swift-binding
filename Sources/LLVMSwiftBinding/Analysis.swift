import cLLVM

public enum VerifierFailureAction {
    public static let abortProcess = LLVMAbortProcessAction
    public static let printMessage = LLVMPrintMessageAction
    public static let returnStatus = LLVMReturnStatusAction
}

public extension Module {
    public func verify(action: LLVMVerifierFailureAction = LLVMReturnStatusAction) throws {
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = LLVMVerifyModule(ref, action, &errMsg)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: "verification failed: \(msg)")
        }
    }
}

public extension Function {
    public func verify(action: LLVMVerifierFailureAction = LLVMReturnStatusAction) -> Bool {
        LLVMVerifyFunction(ref, action) == 0
    }
}
