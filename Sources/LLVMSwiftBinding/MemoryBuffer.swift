import cLLVM

final class MemoryBuffer {
    let ref: LLVMMemoryBufferRef
    private var owns: Bool

    init(ref: LLVMMemoryBufferRef, owns: Bool = true) {
        self.ref = ref
        self.owns = owns
    }

    deinit {
        if owns {
            LLVMDisposeMemoryBuffer(ref)
        }
    }

    var bytes: [UInt8] {
        let size = LLVMGetBufferSize(ref)
        guard size > 0, let ptr = LLVMGetBufferStart(ref) else { return [] }
        return UnsafeBufferPointer(start: ptr, count: size).map { UInt8(bitPattern: $0) }
    }

    var string: String? {
        let size = LLVMGetBufferSize(ref)
        guard size > 0, let ptr = LLVMGetBufferStart(ref) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: size).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    static func fromString(_ str: String, bufferName: String = "") -> MemoryBuffer {
        let ref = str.withCString { ptr in
            LLVMCreateMemoryBufferWithMemoryRangeCopy(ptr, str.utf8.count, bufferName)
        }
        return MemoryBuffer(ref: ref!)
    }

    static func fromBytes(_ bytes: [UInt8], bufferName: String = "") -> MemoryBuffer {
        let ref = bytes.withUnsafeBufferPointer { buffer in
            LLVMCreateMemoryBufferWithMemoryRangeCopy(
                UnsafeRawPointer(buffer.baseAddress!).assumingMemoryBound(to: CChar.self),
                bytes.count, bufferName
            )
        }
        return MemoryBuffer(ref: ref!)
    }

    static func fromFile(_ path: String) throws -> MemoryBuffer {
        var ref: LLVMMemoryBufferRef? = nil
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = path.withCString { pathPtr -> Int32 in
            LLVMCreateMemoryBufferWithContentsOfFile(pathPtr, &ref, &errMsg)
        }
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: msg)
        }
        return MemoryBuffer(ref: ref!)
    }
}
