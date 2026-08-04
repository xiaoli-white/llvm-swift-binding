import cLLVM

extension Module {
    func link(_ source: Module) throws {
        let result = LLVMLinkModules2(ref, source.ref)
        if result != 0 {
            throw LLVMError.emitFailed(message: "failed to link module")
        }
        source.ownsRef = false
    }
}
