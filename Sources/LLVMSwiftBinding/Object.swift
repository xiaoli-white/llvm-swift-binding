import cLLVM

struct SectionInfo {
    let name: String
    let size: UInt64
    let contents: [UInt8]
    let address: UInt64
}

struct SymbolInfo {
    let name: String
    let address: UInt64
    let size: UInt64
}

final class Binary {
    let ref: LLVMBinaryRef
    let buffer: MemoryBuffer

    init(buffer: MemoryBuffer, context: Context? = nil) throws {
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let ref = LLVMCreateBinary(buffer.ref, context?.ref, &errMsg)
        guard let ref else {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: "failed to create binary: \(msg)")
        }
        self.ref = ref
        self.buffer = buffer
    }

    deinit {
        LLVMDisposeBinary(ref)
    }

    var type: LLVMBinaryType {
        LLVMBinaryGetType(ref)
    }

    var typeDescription: String {
        switch type {
        case LLVMBinaryTypeArchive: "archive"
        case LLVMBinaryTypeMachOUniversalBinary: "Mach-O universal binary"
        case LLVMBinaryTypeCOFFImportFile: "COFF import file"
        case LLVMBinaryTypeIR: "LLVM IR"
        case LLVMBinaryTypeWinRes: "Windows resource"
        case LLVMBinaryTypeCOFF: "COFF"
        case LLVMBinaryTypeELF32L: "ELF32 little-endian"
        case LLVMBinaryTypeELF32B: "ELF32 big-endian"
        case LLVMBinaryTypeELF64L: "ELF64 little-endian"
        case LLVMBinaryTypeELF64B: "ELF64 big-endian"
        case LLVMBinaryTypeMachO32L: "MachO32 little-endian"
        case LLVMBinaryTypeMachO32B: "MachO32 big-endian"
        case LLVMBinaryTypeMachO64L: "MachO64 little-endian"
        case LLVMBinaryTypeMachO64B: "MachO64 big-endian"
        case LLVMBinaryTypeWasm: "WebAssembly"
        case LLVMBinaryTypeOffload: "offload"
        case LLVMBinaryTypeDXcontainer: "DX container"
        default: "unknown"
        }
    }

    func sections() -> [SectionInfo] {
        var result: [SectionInfo] = []
        guard let first = LLVMObjectFileCopySectionIterator(ref) else { return [] }
        let iterator = first
        while LLVMObjectFileIsSectionIteratorAtEnd(ref, iterator) == 0 {
            let size = LLVMGetSectionSize(iterator)
            let contents: [UInt8]
            if let ptr = LLVMGetSectionContents(iterator), size > 0 {
                contents = Array(UnsafeBufferPointer(
                    start: ptr.withMemoryRebound(to: UInt8.self, capacity: Int(size)) { $0 },
                    count: Int(size)
                ))
            } else {
                contents = []
            }
            let name = LLVMGetSectionName(iterator).map { String(cString: $0) } ?? ""
            result.append(SectionInfo(
                name: name,
                size: size,
                contents: contents,
                address: LLVMGetSectionAddress(iterator)
            ))
            LLVMMoveToNextSection(iterator)
        }
        LLVMDisposeSectionIterator(iterator)
        return result
    }

    func symbols() -> [SymbolInfo] {
        var result: [SymbolInfo] = []
        guard let first = LLVMObjectFileCopySymbolIterator(ref) else { return [] }
        let iterator = first
        while LLVMObjectFileIsSymbolIteratorAtEnd(ref, iterator) == 0 {
            let name = LLVMGetSymbolName(iterator).map { String(cString: $0) } ?? ""
            result.append(SymbolInfo(
                name: name,
                address: LLVMGetSymbolAddress(iterator),
                size: LLVMGetSymbolSize(iterator)
            ))
            LLVMMoveToNextSymbol(iterator)
        }
        LLVMDisposeSymbolIterator(iterator)
        return result
    }
}
