import cLLVM

public class Type {
    public let ref: LLVMTypeRef
    public let context: Context

    public init(ref: LLVMTypeRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    public var kind: LLVMTypeKind {
        LLVMGetTypeKind(ref)
    }

    public var isVoid: Bool {
        kind == LLVMVoidTypeKind
    }

    public var isInteger: Bool {
        kind == LLVMIntegerTypeKind
    }

    public var isFloat: Bool {
        switch kind {
        case LLVMHalfTypeKind, LLVMFloatTypeKind, LLVMDoubleTypeKind,
             LLVMX86_FP80TypeKind, LLVMFP128TypeKind, LLVMPPC_FP128TypeKind,
             LLVMBFloatTypeKind:
            true
        default:
            false
        }
    }

    public var isFunction: Bool {
        kind == LLVMFunctionTypeKind
    }

    public var isStruct: Bool {
        kind == LLVMStructTypeKind
    }

    public var isArray: Bool {
        kind == LLVMArrayTypeKind
    }

    public var isPointer: Bool {
        kind == LLVMPointerTypeKind
    }

    public var isVector: Bool {
        kind == LLVMVectorTypeKind || kind == LLVMScalableVectorTypeKind
    }

    public var isTargetExt: Bool {
        kind == LLVMTargetExtTypeKind
    }

    public var contextRef: LLVMContextRef {
        LLVMGetTypeContext(ref)
    }

    public var description: String {
        let ptr = LLVMPrintTypeToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }
}

public final class VoidType: Type {}

public final class IntegerType: Type {
    public var width: UInt32 {
        LLVMGetIntTypeWidth(ref)
    }
}

public final class FloatType: Type {}

public final class FunctionType: Type {
    public var returnType: Type {
        context.wrapType(LLVMGetReturnType(ref)!)
    }

    public var parameterCount: UInt32 {
        LLVMCountParamTypes(ref)
    }

    public var parameterTypes: [Type] {
        let count = Int(parameterCount)
        guard count > 0 else { return [] }
        var types = [LLVMTypeRef?](repeating: nil, count: count)
        types.withUnsafeMutableBufferPointer { buffer in
            LLVMGetParamTypes(ref, buffer.baseAddress)
        }
        return types.map { context.wrapType($0!) }
    }

    public var isVariadic: Bool {
        LLVMIsFunctionVarArg(ref) != 0
    }
}

public final class PointerType: Type {
    public var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    public var addressSpace: UInt32 {
        LLVMGetPointerAddressSpace(ref)
    }
}

public final class StructType: Type {
    public var elementCount: UInt32 {
        LLVMCountStructElementTypes(ref)
    }

    public var elementTypes: [Type] {
        let count = Int(elementCount)
        guard count > 0 else { return [] }
        var types = [LLVMTypeRef?](repeating: nil, count: count)
        types.withUnsafeMutableBufferPointer { buffer in
            LLVMGetStructElementTypes(ref, buffer.baseAddress)
        }
        return types.map { context.wrapType($0!) }
    }

    public func elementType(at index: UInt32) -> Type {
        context.wrapType(LLVMStructGetTypeAtIndex(ref, index)!)
    }

    public var isPacked: Bool {
        LLVMIsPackedStruct(ref) != 0
    }

    public var isOpaque: Bool {
        LLVMIsOpaqueStruct(ref) != 0
    }

    public var isLiteral: Bool {
        LLVMIsLiteralStruct(ref) != 0
    }

    public var name: String? {
        guard let ptr = LLVMGetStructName(ref) else { return nil }
        return String(cString: ptr)
    }
}

public final class ArrayType: Type {
    public var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    public var elementCount: UInt64 {
        LLVMGetArrayLength2(ref)
    }
}

public final class VectorType: Type {
    public var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    public var elementCount: UInt32 {
        LLVMGetVectorSize(ref)
    }

    public var isScalable: Bool {
        kind == LLVMScalableVectorTypeKind
    }
}

public final class LabelType: Type {}
public final class TokenType: Type {}
public final class MetadataType: Type {}

public final class TargetExtType: Type {
    public var name: String? {
        guard let ptr = LLVMGetTargetExtTypeName(ref) else { return nil }
        return String(cString: ptr)
    }

    public var typeParameterCount: UInt32 {
        LLVMGetTargetExtTypeNumTypeParams(ref)
    }

    public func typeParameter(at index: UInt32) -> Type {
        context.wrapType(LLVMGetTargetExtTypeTypeParam(ref, index)!)
    }

    public var intParameterCount: UInt32 {
        LLVMGetTargetExtTypeNumIntParams(ref)
    }

    public func intParameter(at index: UInt32) -> UInt32 {
        LLVMGetTargetExtTypeIntParam(ref, index)
    }
}
