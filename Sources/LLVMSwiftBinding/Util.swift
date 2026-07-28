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
