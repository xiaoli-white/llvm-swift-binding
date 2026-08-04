import cLLVM

enum VerifierFailureAction {
    static let abortProcess = LLVMAbortProcessAction
    static let printMessage = LLVMPrintMessageAction
    static let returnStatus = LLVMReturnStatusAction
}

extension Module {
    func verify(action: LLVMVerifierFailureAction = LLVMReturnStatusAction) throws {
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = LLVMVerifyModule(ref, action, &errMsg)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: "verification failed: \(msg)")
        }
    }
}

extension Function {
    func verify(action: LLVMVerifierFailureAction = LLVMReturnStatusAction) -> Bool {
        LLVMVerifyFunction(ref, action) == 0
    }
}
