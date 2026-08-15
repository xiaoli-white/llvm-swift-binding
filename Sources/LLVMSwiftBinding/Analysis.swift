import cLLVM

public extension Module {
    func verify(action: VerifierFailureAction = .ReturnStatus) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = LLVMVerifyModule(ref, action.llvm, &errMsg)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: "verification failed: \(msg)")
        }
    }
}

public extension Function {
    func verify(action: VerifierFailureAction = .ReturnStatus) -> Bool {
        LLVMVerifyFunction(ref, action.llvm) == 0
    }
}
