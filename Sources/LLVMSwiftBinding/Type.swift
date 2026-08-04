import cLLVM

class Type {
    let ref: LLVMTypeRef
    let context: Context

    init(ref: LLVMTypeRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    var kind: LLVMTypeKind {
        LLVMGetTypeKind(ref)
    }

    var isVoid: Bool {
        kind == LLVMVoidTypeKind
    }

    var isInteger: Bool {
        kind == LLVMIntegerTypeKind
    }

    var isFloat: Bool {
        switch kind {
        case LLVMHalfTypeKind, LLVMFloatTypeKind, LLVMDoubleTypeKind,
             LLVMX86_FP80TypeKind, LLVMFP128TypeKind, LLVMPPC_FP128TypeKind,
             LLVMBFloatTypeKind:
            return true
        default:
            return false
        }
    }

    var isFunction: Bool {
        kind == LLVMFunctionTypeKind
    }

    var isStruct: Bool {
        kind == LLVMStructTypeKind
    }

    var isArray: Bool {
        kind == LLVMArrayTypeKind
    }

    var isPointer: Bool {
        kind == LLVMPointerTypeKind
    }

    var isVector: Bool {
        kind == LLVMVectorTypeKind || kind == LLVMScalableVectorTypeKind
    }

    var isTargetExt: Bool {
        kind == LLVMTargetExtTypeKind
    }

    var description: String {
        let ptr = LLVMPrintTypeToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }
}

final class VoidType: Type {}

final class IntegerType: Type {
    var width: UInt32 {
        LLVMGetIntTypeWidth(ref)
    }
}

final class FloatType: Type {}

final class FunctionType: Type {
    var returnType: Type {
        context.wrapType(LLVMGetReturnType(ref)!)
    }

    var parameterCount: UInt32 {
        LLVMCountParamTypes(ref)
    }

    var parameterTypes: [Type] {
        let count = Int(parameterCount)
        guard count > 0 else { return [] }
        var types = [LLVMTypeRef?](repeating: nil, count: count)
        types.withUnsafeMutableBufferPointer { buffer in
            LLVMGetParamTypes(ref, buffer.baseAddress)
        }
        return types.map { context.wrapType($0!) }
    }

    var isVariadic: Bool {
        LLVMIsFunctionVarArg(ref) != 0
    }
}

final class PointerType: Type {
    var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    var addressSpace: UInt32 {
        LLVMGetPointerAddressSpace(ref)
    }
}

final class StructType: Type {
    var elementCount: UInt32 {
        LLVMCountStructElementTypes(ref)
    }

    var elementTypes: [Type] {
        let count = Int(elementCount)
        guard count > 0 else { return [] }
        var types = [LLVMTypeRef?](repeating: nil, count: count)
        types.withUnsafeMutableBufferPointer { buffer in
            LLVMGetStructElementTypes(ref, buffer.baseAddress)
        }
        return types.map { context.wrapType($0!) }
    }

    func elementType(at index: UInt32) -> Type {
        context.wrapType(LLVMStructGetTypeAtIndex(ref, index)!)
    }

    var isPacked: Bool {
        LLVMIsPackedStruct(ref) != 0
    }

    var isOpaque: Bool {
        LLVMIsOpaqueStruct(ref) != 0
    }

    var isLiteral: Bool {
        LLVMIsLiteralStruct(ref) != 0
    }

    var name: String? {
        guard let ptr = LLVMGetStructName(ref) else { return nil }
        return String(cString: ptr)
    }
}

final class ArrayType: Type {
    var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    var elementCount: UInt64 {
        LLVMGetArrayLength2(ref)
    }
}

final class VectorType: Type {
    var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    var elementCount: UInt32 {
        LLVMGetVectorSize(ref)
    }

    var isScalable: Bool {
        kind == LLVMScalableVectorTypeKind
    }
}

final class LabelType: Type {}
final class TokenType: Type {}
final class MetadataType: Type {}

final class TargetExtType: Type {
    var name: String? {
        guard let ptr = LLVMGetTargetExtTypeName(ref) else { return nil }
        return String(cString: ptr)
    }

    var typeParameterCount: UInt32 {
        LLVMGetTargetExtTypeNumTypeParams(ref)
    }

    func typeParameter(at index: UInt32) -> Type {
        context.wrapType(LLVMGetTargetExtTypeTypeParam(ref, index)!)
    }

    var intParameterCount: UInt32 {
        LLVMGetTargetExtTypeNumIntParams(ref)
    }

    func intParameter(at index: UInt32) -> UInt32 {
        LLVMGetTargetExtTypeIntParam(ref, index)
    }
}
