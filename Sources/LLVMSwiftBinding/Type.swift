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

    var isPacked: Bool {
        LLVMIsPackedStruct(ref) != 0
    }
}

final class ArrayType: Type {
    var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    var elementCount: UInt32 {
        LLVMGetArrayLength(ref)
    }
}

final class VectorType: Type {
    var elementType: Type {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    var elementCount: UInt32 {
        LLVMGetVectorSize(ref)
    }
}

final class LabelType: Type {}
final class TokenType: Type {}
final class MetadataType: Type {}
final class TargetExtType: Type {}
