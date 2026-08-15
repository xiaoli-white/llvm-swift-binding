import cLLVM

public final class Context {
    public let ref: LLVMContextRef
    public var ownsRef: Bool = true
    private var typeCache: [OpaquePointer: LLVMType] = [:]
    private var constantCache: [OpaquePointer: Constant] = [:]

    public init() {
        ref = LLVMContextCreate()
    }

    deinit {
        if ownsRef {
            LLVMContextDispose(ref)
        }
    }

    public var int1: IntegerType { intType(width: 1) }
    public var int8: IntegerType { intType(width: 8) }
    public var int16: IntegerType { intType(width: 16) }
    public var int32: IntegerType { intType(width: 32) }
    public var int64: IntegerType { intType(width: 64) }
    public var int128: IntegerType { intType(width: 128) }

    public func intType(width: UInt32) -> IntegerType {
        wrapType(LLVMIntTypeInContext(ref, width)!) as! IntegerType
    }

    public var void: VoidType {
        wrapType(LLVMVoidTypeInContext(ref)!) as! VoidType
    }

    public var float: FloatType {
        wrapType(LLVMFloatTypeInContext(ref)!) as! FloatType
    }

    public var double: FloatType {
        wrapType(LLVMDoubleTypeInContext(ref)!) as! FloatType
    }

    public var half: FloatType {
        wrapType(LLVMHalfTypeInContext(ref)!) as! FloatType
    }

    public var bfloat: FloatType {
        wrapType(LLVMBFloatTypeInContext(ref)!) as! FloatType
    }

    public var fp128: FloatType {
        wrapType(LLVMFP128TypeInContext(ref)!) as! FloatType
    }

    public var x86FP80: FloatType {
        wrapType(LLVMX86FP80TypeInContext(ref)!) as! FloatType
    }

    public var ppcFP128: FloatType {
        wrapType(LLVMPPCFP128TypeInContext(ref)!) as! FloatType
    }

    public var x86AMX: LLVMType {
        wrapType(LLVMX86AMXTypeInContext(ref)!)
    }

    public var label: LLVMType {
        wrapType(LLVMLabelTypeInContext(ref)!)
    }

    public var token: LLVMType {
        wrapType(LLVMTokenTypeInContext(ref)!)
    }

    public func mdKindID(_ name: String) -> UInt32 {
        name.withCString { ptr in
            LLVMGetMDKindIDInContext(ref, ptr, UInt32(name.utf8.count))
        }
    }

    public func syncScopeID(_ name: String) -> UInt32 {
        name.withCString { ptr in
            UInt32(LLVMGetSyncScopeID(ref, ptr, name.utf8.count))
        }
    }

    public var discardValueNames: Bool {
        get { LLVMContextShouldDiscardValueNames(ref) != 0 }
        set { LLVMContextSetDiscardValueNames(ref, newValue ? 1 : 0) }
    }

    public static var version: (major: UInt32, minor: UInt32, patch: UInt32) {
        var major: UInt32 = 0
        var minor: UInt32 = 0
        var patch: UInt32 = 0
        LLVMGetVersion(&major, &minor, &patch)
        return (major, minor, patch)
    }

    public func functionType(returnType: LLVMType, parameterTypes: [LLVMType] = [],
                             isVariadic: Bool = false) -> FunctionType
    {
        var params: [LLVMTypeRef?] = parameterTypes.map(\.ref)
        let ref = params.withUnsafeMutableBufferPointer { buffer in
            LLVMFunctionType(returnType.ref, buffer.baseAddress, UInt32(parameterTypes.count), isVariadic ? 1 : 0)
        }
        return wrapType(ref!) as! FunctionType
    }

    public func constantInt(_ value: UInt64, type: IntegerType) -> ConstantInt {
        let ref = LLVMConstInt(type.ref, value, 0)!
        return wrapConstant(ref) as! ConstantInt
    }

    public func constantInt(signed value: Int64, type: IntegerType) -> ConstantInt {
        let ref = LLVMConstInt(type.ref, UInt64(bitPattern: value), 1)!
        return wrapConstant(ref) as! ConstantInt
    }

    public func constantFP(_ value: Double, type: FloatType) -> ConstantFP {
        let ref = LLVMConstReal(type.ref, value)!
        return wrapConstant(ref) as! ConstantFP
    }

    public func pointerType(addressSpace: UInt32 = 0) -> PointerType {
        let ref = LLVMPointerTypeInContext(ref, addressSpace)
        return wrapType(ref!) as! PointerType
    }

    public func constantNull(_ type: LLVMType) -> Constant {
        let ref = LLVMConstNull(type.ref)!
        return wrapConstant(ref)
    }

    public func undef(_ type: LLVMType) -> UndefValue {
        let ref = LLVMGetUndef(type.ref)!
        return UndefValue(ref: ref, context: self)
    }

    public func poison(_ type: LLVMType) -> PoisonValue {
        let ref = LLVMGetPoison(type.ref)!
        return PoisonValue(ref: ref, context: self)
    }

    public func constantFP(ofString str: String, type: FloatType) -> ConstantFP {
        let ref = str.withCString { strPtr in
            LLVMConstRealOfStringAndSize(type.ref, strPtr, UInt32(str.utf8.count))
        }
        return wrapConstant(ref!) as! ConstantFP
    }

    public func constantString(_ str: String, dontNullTerminate: Bool = false) -> Constant {
        let ref = str.withCString { strPtr in
            LLVMConstStringInContext2(self.ref, strPtr, str.utf8.count, dontNullTerminate ? 1 : 0)
        }
        return wrapConstant(ref!)
    }

    public func constantReal(ofString str: String, type: FloatType) -> ConstantFP {
        let ref = str.withCString { strPtr in
            LLVMConstRealOfStringAndSize(type.ref, strPtr, UInt32(str.utf8.count))
        }
        return wrapConstant(ref!) as! ConstantFP
    }

    public func constantNeg(_ value: Constant) -> Constant {
        wrapConstant(LLVMConstNeg(value.ref)!)
    }

    public func constantNSWNeg(_ value: Constant) -> Constant {
        wrapConstant(LLVMConstNSWNeg(value.ref)!)
    }

    public func constantAdd(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstAdd(lhs.ref, rhs.ref)!)
    }

    public func constantNSWAdd(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstNSWAdd(lhs.ref, rhs.ref)!)
    }

    public func constantNUWAdd(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstNUWAdd(lhs.ref, rhs.ref)!)
    }

    public func constantSub(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstSub(lhs.ref, rhs.ref)!)
    }

    public func constantNSWSub(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstNSWSub(lhs.ref, rhs.ref)!)
    }

    public func constantNUWSub(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstNUWSub(lhs.ref, rhs.ref)!)
    }

    public func constantTrunc(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstTrunc(value.ref, type.ref)!)
    }

    public func constantPtrToInt(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstPtrToInt(value.ref, type.ref)!)
    }

    public func constantIntToPtr(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstIntToPtr(value.ref, type.ref)!)
    }

    public func constantBitCast(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstBitCast(value.ref, type.ref)!)
    }

    public func constantArray(_ values: [Constant], elementType: LLVMType) -> ConstantArray {
        var valRefs: [LLVMValueRef?] = values.map(\.ref)
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstArray2(elementType.ref, buffer.baseAddress, UInt64(values.count))
        }
        return ConstantArray(ref: ref!, context: self)
    }

    public func constantDataArray(bytes: [UInt8], type: LLVMType) -> ConstantDataArray {
        let chars = bytes.map { CChar(bitPattern: $0) }
        let ref = chars.withUnsafeBufferPointer { buffer in
            LLVMConstDataArray(type.ref, buffer.baseAddress, buffer.count)
        }
        return ConstantDataArray(ref: ref!, context: self)
    }

    public func constantVector(_ values: [Constant]) -> ConstantVector {
        var valRefs: [LLVMValueRef?] = values.map(\.ref)
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstVector(buffer.baseAddress, UInt32(values.count))
        }
        return ConstantVector(ref: ref!, context: self)
    }

    public func constantInt(ofString str: String, type: IntegerType, radix: UInt8 = 0) -> ConstantInt {
        let (clean, effectiveRadix) = Self.resolveRadix(str, radix: radix)
        let ref = clean.withCString { strPtr in
            LLVMConstIntOfStringAndSize(type.ref, strPtr, UInt32(clean.utf8.count), effectiveRadix)
        }
        return wrapConstant(ref!) as! ConstantInt
    }

    private static func resolveRadix(_ str: String, radix: UInt8) -> (String, UInt8) {
        let lower = str.lowercased()
        if radix != 0 {
            switch radix {
            case 16:
                if lower.hasPrefix("0x") { return (String(str.dropFirst(2)), 16) }
            case 2:
                if lower.hasPrefix("0b") { return (String(str.dropFirst(2)), 2) }
            case 8:
                if lower.hasPrefix("0o") { return (String(str.dropFirst(2)), 8) }
            default:
                break
            }
            return (str, radix)
        }
        if lower.hasPrefix("0x") { return (String(str.dropFirst(2)), 16) }
        if lower.hasPrefix("0b") { return (String(str.dropFirst(2)), 2) }
        if lower.hasPrefix("0o") { return (String(str.dropFirst(2)), 8) }
        return (str, 10)
    }

    public func constantAllOnes(_ type: LLVMType) -> Constant {
        wrapConstant(LLVMConstAllOnes(type.ref)!)
    }

    public func constantPointerNull(_ type: LLVMType) -> Constant {
        wrapConstant(LLVMConstPointerNull(type.ref)!)
    }

    public func constantNot(_ value: Constant) -> Constant {
        wrapConstant(LLVMConstNot(value.ref)!)
    }

    public func constantXor(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstXor(lhs.ref, rhs.ref)!)
    }

    public func constantGEP(_ elementType: LLVMType, _ value: Constant, indices: [Constant]) -> Constant {
        var idxRefs: [LLVMValueRef?] = indices.map(\.ref)
        let ref = idxRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstGEP2(elementType.ref, value.ref, buffer.baseAddress, UInt32(indices.count))
        }
        return wrapConstant(ref!)
    }

    public func constantTruncOrBitCast(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstTruncOrBitCast(value.ref, type.ref)!)
    }

    public func constantPointerCast(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstPointerCast(value.ref, type.ref)!)
    }

    public func constantAddrSpaceCast(_ value: Constant, to type: LLVMType) -> Constant {
        wrapConstant(LLVMConstAddrSpaceCast(value.ref, type.ref)!)
    }

    public func constantExtractElement(_ vector: Constant, _ index: Constant) -> Constant {
        wrapConstant(LLVMConstExtractElement(vector.ref, index.ref)!)
    }

    public func constantInsertElement(_ vector: Constant, _ element: Constant, _ index: Constant) -> Constant {
        wrapConstant(LLVMConstInsertElement(vector.ref, element.ref, index.ref)!)
    }

    public func constantShuffleVector(_ v1: Constant, _ v2: Constant, mask: Constant) -> Constant {
        wrapConstant(LLVMConstShuffleVector(v1.ref, v2.ref, mask.ref)!)
    }

    public func constantInt(arbitraryPrecision words: [UInt64], type: IntegerType) -> ConstantInt {
        let ref = words.withUnsafeBufferPointer { buffer in
            LLVMConstIntOfArbitraryPrecision(type.ref, UInt32(words.count), buffer.baseAddress)
        }
        return ConstantInt(ref: ref!, context: self)
    }

    public func constantFP(fromBits bits: [UInt64], type: LLVMType) -> ConstantFP {
        let ref = bits.withUnsafeBufferPointer { buffer in
            LLVMConstFPFromBits(type.ref, buffer.baseAddress)
        }
        return ConstantFP(ref: ref!, context: self)
    }

    public func constantNamedStruct(_ type: LLVMType, values: [Constant]) -> ConstantStruct {
        var valRefs: [LLVMValueRef?] = values.map(\.ref)
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstNamedStruct(type.ref, buffer.baseAddress, UInt32(values.count))
        }
        return ConstantStruct(ref: ref!, context: self)
    }

    public func constantInBoundsGEP(_ elementType: LLVMType, _ value: Constant, indices: [Constant]) -> Constant {
        var indexRefs: [LLVMValueRef?] = indices.map(\.ref)
        let ref = indexRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstInBoundsGEP2(elementType.ref, value.ref, buffer.baseAddress, UInt32(indices.count))
        }
        return wrapConstant(ref!)
    }

    public func constantGEPWithNoWrapFlags(
        _ elementType: LLVMType,
        _ value: Constant,
        indices: [Constant],
        flags: GEPNoWrapFlags
    ) -> Constant {
        var indexRefs: [LLVMValueRef?] = indices.map(\.ref)
        let ref = indexRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstGEPWithNoWrapFlags(
                elementType.ref,
                value.ref,
                buffer.baseAddress,
                UInt32(indices.count),
                flags.rawValue
            )
        }
        return wrapConstant(ref!)
    }

    public func sizeOf(_ type: LLVMType) -> Constant {
        wrapConstant(LLVMSizeOf(type.ref)!)
    }

    public func alignOf(_ type: LLVMType) -> Constant {
        wrapConstant(LLVMAlignOf(type.ref)!)
    }

    public func constantPtrAuth(
        pointer: Constant,
        key: Constant,
        discriminator: Constant,
        addrDiscriminator: Constant
    ) -> Constant {
        wrapConstant(LLVMConstantPtrAuth(pointer.ref, key.ref, discriminator.ref, addrDiscriminator.ref)!)
    }

    public func constantInlineAsm(
        _ type: LLVMType,
        asmString: String,
        constraints: String,
        hasSideEffects: Bool,
        isAlignStack: Bool,
        dialect: InlineAsmDialect = .ATT,
        canThrow: Bool = false
    ) -> InlineAsm {
        let ref = asmString.withCString { asmPtr in
            constraints.withCString { cPtr in
                LLVMGetInlineAsm(
                    type.ref,
                    asmPtr,
                    asmString.utf8.count,
                    cPtr,
                    constraints.utf8.count,
                    hasSideEffects ? 1 : 0,
                    isAlignStack ? 1 : 0,
                    dialect.llvm,
                    canThrow ? 1 : 0
                )
            }
        }
        return InlineAsm(ref: ref!, context: self)
    }

    public func blockAddress(function: Function, block: BasicBlock) -> BlockAddress {
        let ref = LLVMBlockAddress(function.ref, block.ref)
        return BlockAddress(ref: ref!, context: self)
    }

    public func lookupIntrinsicID(_ name: String) -> UInt32 {
        name.withCString { ptr in
            LLVMLookupIntrinsicID(ptr, name.utf8.count)
        }
    }

    public func intrinsicName(_ id: UInt32) -> String? {
        var length = 0
        guard let ptr = LLVMIntrinsicGetName(id, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public func intrinsicType(_ id: UInt32, paramTypes: [LLVMType] = []) -> LLVMType? {
        var refs: [LLVMTypeRef?] = paramTypes.map(\.ref)
        let ref = refs.withUnsafeMutableBufferPointer { buffer in
            LLVMIntrinsicGetType(self.ref, id, buffer.baseAddress, paramTypes.count)
        }
        guard let ref else { return nil }
        return wrapType(ref)
    }

    public func intrinsicDeclaration(_ id: UInt32, paramTypes: [LLVMType] = [], in module: Module) -> Function? {
        var refs: [LLVMTypeRef?] = paramTypes.map(\.ref)
        let ref = refs.withUnsafeMutableBufferPointer { buffer in
            LLVMGetIntrinsicDeclaration(module.ref, id, buffer.baseAddress, paramTypes.count)
        }
        guard let ref else { return nil }
        return Function(ref: ref, module: module)
    }

    public func intrinsicOverloadedName(_ id: UInt32, paramTypes: [LLVMType], in module: Module) -> String? {
        var refs: [LLVMTypeRef?] = paramTypes.map(\.ref)
        var nameLength = 0
        guard let ptr = refs.withUnsafeMutableBufferPointer({ buffer in
            LLVMIntrinsicCopyOverloadedName2(module.ref, id, buffer.baseAddress, paramTypes.count, &nameLength)
        }) else { return nil }
        defer { LLVMDisposeMessage(ptr) }
        let bytes = UnsafeBufferPointer(start: ptr, count: nameLength).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public func constantStruct(_ values: [Constant], isPacked: Bool = false) -> ConstantStruct {
        var valRefs: [LLVMValueRef?] = values.map(\.ref)
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstStructInContext(self.ref, buffer.baseAddress, UInt32(values.count), isPacked ? 1 : 0)
        }
        return ConstantStruct(ref: ref!, context: self)
    }

    public func structType(elementTypes: [LLVMType], isPacked: Bool = false) -> StructType {
        var members: [LLVMTypeRef?] = elementTypes.map(\.ref)
        let ref = members.withUnsafeMutableBufferPointer { buffer in
            LLVMStructTypeInContext(self.ref, buffer.baseAddress, UInt32(elementTypes.count), isPacked ? 1 : 0)
        }
        return wrapType(ref!) as! StructType
    }

    public func namedStructType(name: String, elementTypes: [LLVMType]? = nil, isPacked: Bool = false) -> StructType {
        let ref = LLVMStructCreateNamed(ref, name)
        let type = wrapType(ref!) as! StructType
        if let elementTypes {
            type.setElementTypes(elementTypes, isPacked: isPacked)
        }
        return type
    }

    public func arrayType(elementType: LLVMType, count: UInt32) -> ArrayType {
        let ref = LLVMArrayType(elementType.ref, count)
        return wrapType(ref!) as! ArrayType
    }

    public func vectorType(elementType: LLVMType, count: UInt32) -> VectorType {
        let ref = LLVMVectorType(elementType.ref, count)
        return wrapType(ref!) as! VectorType
    }

    public func scalableVectorType(elementType: LLVMType, count: UInt32) -> VectorType {
        let ref = LLVMScalableVectorType(elementType.ref, count)
        return wrapType(ref!) as! VectorType
    }

    public func targetExtType(name: String, typeParams: [LLVMType] = [], intParams: [UInt32] = []) -> TargetExtType {
        var typeRefs: [LLVMTypeRef?] = typeParams.map(\.ref)
        let ref = typeRefs.withUnsafeMutableBufferPointer { typeBuf in
            intParams.withUnsafeBufferPointer { intBuf in
                LLVMTargetExtTypeInContext(
                    self.ref,
                    name,
                    typeBuf.baseAddress,
                    UInt32(typeParams.count),
                    UnsafeMutablePointer(mutating: intBuf.baseAddress),
                    UInt32(intParams.count)
                )
            }
        }
        return wrapType(ref!) as! TargetExtType
    }

    public func mdNode(_ elements: [Metadata]) -> Metadata {
        var elems: [LLVMMetadataRef?] = elements.map(\.ref)
        let ref = elems.withUnsafeMutableBufferPointer { buffer in
            LLVMMDNodeInContext2(self.ref, buffer.baseAddress, buffer.count)
        }
        return Metadata(ref: ref!)
    }

    public func mdString(_ str: String) -> Metadata {
        let ref = str.withCString { strPtr in
            LLVMMDStringInContext2(self.ref, strPtr, str.utf8.count)
        }
        return Metadata(ref: ref!)
    }

    public func metadataAsValue(_ metadata: Metadata) -> Value {
        Value(ref: LLVMMetadataAsValue(ref, metadata.ref), context: self)
    }

    public func wrapType(_ ref: LLVMTypeRef) -> LLVMType {
        if let cached = typeCache[ref] {
            return cached
        }
        let kind = LLVMGetTypeKind(ref)
        let type: LLVMType = switch kind {
        case LLVMVoidTypeKind:
            VoidType(ref: ref, context: self)
        case LLVMHalfTypeKind, LLVMFloatTypeKind, LLVMDoubleTypeKind,
             LLVMX86_FP80TypeKind, LLVMFP128TypeKind, LLVMPPC_FP128TypeKind,
             LLVMBFloatTypeKind:
            FloatType(ref: ref, context: self)
        case LLVMIntegerTypeKind:
            IntegerType(ref: ref, context: self)
        case LLVMFunctionTypeKind:
            FunctionType(ref: ref, context: self)
        case LLVMStructTypeKind:
            StructType(ref: ref, context: self)
        case LLVMArrayTypeKind:
            ArrayType(ref: ref, context: self)
        case LLVMPointerTypeKind:
            PointerType(ref: ref, context: self)
        case LLVMVectorTypeKind, LLVMScalableVectorTypeKind:
            VectorType(ref: ref, context: self)
        case LLVMLabelTypeKind:
            LabelType(ref: ref, context: self)
        case LLVMTokenTypeKind:
            TokenType(ref: ref, context: self)
        case LLVMMetadataTypeKind:
            MetadataType(ref: ref, context: self)
        case LLVMTargetExtTypeKind:
            TargetExtType(ref: ref, context: self)
        default:
            LLVMType(ref: ref, context: self)
        }
        typeCache[ref] = type
        return type
    }

    public func wrapConstant(_ ref: LLVMValueRef) -> Constant {
        if let cached = constantCache[ref] {
            return cached
        }
        let constant: Constant = if LLVMIsAConstantInt(ref) != nil {
            ConstantInt(ref: ref, context: self)
        } else if LLVMIsAConstantFP(ref) != nil {
            ConstantFP(ref: ref, context: self)
        } else if LLVMIsAUndefValue(ref) != nil {
            UndefValue(ref: ref, context: self)
        } else if LLVMIsAPoisonValue(ref) != nil {
            PoisonValue(ref: ref, context: self)
        } else if LLVMIsAConstantTokenNone(ref) != nil {
            ConstantTokenNone(ref: ref, context: self)
        } else if LLVMIsAConstantAggregateZero(ref) != nil {
            ConstantAggregateZero(ref: ref, context: self)
        } else if LLVMIsAConstantDataArray(ref) != nil {
            ConstantDataArray(ref: ref, context: self)
        } else if LLVMIsAConstantExpr(ref) != nil {
            ConstantExpr(ref: ref, context: self)
        } else if LLVMIsAConstantVector(ref) != nil {
            ConstantVector(ref: ref, context: self)
        } else if LLVMIsABlockAddress(ref) != nil {
            BlockAddress(ref: ref, context: self)
        } else {
            Constant(ref: ref, context: self)
        }
        constantCache[ref] = constant
        return constant
    }
}
