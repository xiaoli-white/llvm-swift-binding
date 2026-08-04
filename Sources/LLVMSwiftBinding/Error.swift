enum LLVMError: Error {
    case targetNotFound(triple: String)
    case emitFailed(message: String)
    case parseFailed(message: String)
    case passRunFailed(message: String)
}
