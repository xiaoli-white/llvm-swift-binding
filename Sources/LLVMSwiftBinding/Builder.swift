import cLLVM

public struct GEPNoWrapFlags: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let InBounds = GEPNoWrapFlags(rawValue: 1 | 2)
    public static let NUSW = GEPNoWrapFlags(rawValue: 2)
    public static let NUW = GEPNoWrapFlags(rawValue: 4)
}

public enum BinaryOpcode {
    case Add, FAdd, Sub, FSub, Mul, FMul, UDiv, SDiv, FDiv, URem, SRem, FRem, Shl, LShr, AShr, And, Or, Xor

    var llvm: LLVMOpcode {
        switch self {
        case .Add: LLVMAdd
        case .FAdd: LLVMFAdd
        case .Sub: LLVMSub
        case .FSub: LLVMFSub
        case .Mul: LLVMMul
        case .FMul: LLVMFMul
        case .UDiv: LLVMUDiv
        case .SDiv: LLVMSDiv
        case .FDiv: LLVMFDiv
        case .URem: LLVMURem
        case .SRem: LLVMSRem
        case .FRem: LLVMFRem
        case .Shl: LLVMShl
        case .LShr: LLVMLShr
        case .AShr: LLVMAShr
        case .And: LLVMAnd
        case .Or: LLVMOr
        case .Xor: LLVMXor
        }
    }
}

public enum CastOpcode {
    case Trunc, ZExt, SExt, FPToUI, FPToSI, UIToFP, SIToFP, FPTrunc, FPExt, PtrToInt, IntToPtr, BitCast, AddrSpaceCast

    var llvm: LLVMOpcode {
        switch self {
        case .Trunc: LLVMTrunc
        case .ZExt: LLVMZExt
        case .SExt: LLVMSExt
        case .FPToUI: LLVMFPToUI
        case .FPToSI: LLVMFPToSI
        case .UIToFP: LLVMUIToFP
        case .SIToFP: LLVMSIToFP
        case .FPTrunc: LLVMFPTrunc
        case .FPExt: LLVMFPExt
        case .PtrToInt: LLVMPtrToInt
        case .IntToPtr: LLVMIntToPtr
        case .BitCast: LLVMBitCast
        case .AddrSpaceCast: LLVMAddrSpaceCast
        }
    }
}

public final class Builder {
    public let ref: LLVMBuilderRef
    public let context: Context
    private var currentModule: Module?

    public init(in context: Context) {
        ref = LLVMCreateBuilderInContext(context.ref)!
        self.context = context
    }

    deinit {
        LLVMDisposeBuilder(ref)
    }

    public func positionAtEnd(of block: BasicBlock) {
        currentModule = block.module
        LLVMPositionBuilderAtEnd(ref, block.ref)
    }

    public func positionBefore(_ inst: Instruction) {
        currentModule = inst.module
        LLVMPositionBuilderBefore(ref, inst.ref)
    }

    public func positionBeforeDbgRecords(in block: BasicBlock, before inst: Instruction) {
        currentModule = block.module
        LLVMPositionBuilderBeforeDbgRecords(ref, block.ref, inst.ref)
    }

    public func positionBeforeInstrAndDbgRecords(_ inst: Instruction) {
        currentModule = inst.module
        LLVMPositionBuilderBeforeInstrAndDbgRecords(ref, inst.ref)
    }

    public func setCurrentDebugLocation(_ location: Metadata?) {
        LLVMSetCurrentDebugLocation2(ref, location?.ref)
    }

    public var currentDebugLocation: Metadata? {
        guard let ref = LLVMGetCurrentDebugLocation2(ref) else { return nil }
        return Metadata(ref: ref)
    }

    public func setInstDebugLocation(_ inst: Instruction) {
        LLVMSetInstDebugLocation(ref, inst.ref)
    }

    public var defaultFPMathTag: Metadata? {
        get {
            guard let ref = LLVMBuilderGetDefaultFPMathTag(ref) else { return nil }
            return Metadata(ref: ref)
        }
        set {
            LLVMBuilderSetDefaultFPMathTag(ref, newValue?.ref)
        }
    }

    @discardableResult
    public func buildRet(_ value: Value) -> ReturnInst {
        let inst = LLVMBuildRet(ref, value.ref)!
        return ReturnInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildRetVoid() -> ReturnInst {
        let inst = LLVMBuildRetVoid(ref)!
        return ReturnInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAggregateRet(_ values: [Value]) -> ReturnInst {
        var valRefs: [LLVMValueRef?] = values.map(\.ref)
        let inst = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildAggregateRet(ref, buffer.baseAddress, UInt32(values.count))
        }
        return ReturnInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildAdd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildSub(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildBinOp(_ op: BinaryOpcode, _ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildBinOp(ref, op.llvm, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildMul(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildUDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildUDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildSDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNSWAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNSWAdd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNUWAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNUWAdd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNSWSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNSWSub(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNUWSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNUWSub(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNSWMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNSWMul(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNUWMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNUWMul(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildExactUDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildExactUDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildExactSDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildExactSDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNSWNeg(_ value: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNSWNeg(ref, value.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNeg(_ value: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNeg(ref, value.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNUWNeg(_ value: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNeg(ref, value.ref, name)!
        LLVMSetNUW(inst, 1)
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildNot(_ value: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildNot(ref, value.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFNeg(_ value: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFNeg(ref, value.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildURem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildURem(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSRem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildSRem(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFAdd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFSub(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFMul(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFRem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFRem(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildShl(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildShl(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildLShr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildLShr(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAShr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildAShr(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAnd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildAnd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildOr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildOr(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildXor(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildXor(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAlloca(_ type: LLVMType, name: String = "") -> AllocaInst {
        let inst = LLVMBuildAlloca(ref, type.ref, name)!
        return AllocaInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildArrayAlloca(_ type: LLVMType, size: Value, name: String = "") -> AllocaInst {
        let inst = LLVMBuildArrayAlloca(ref, type.ref, size.ref, name)!
        return AllocaInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildLoad(_ type: LLVMType, _ ptr: Value, name: String = "") -> LoadInst {
        let inst = LLVMBuildLoad2(ref, type.ref, ptr.ref, name)!
        return LoadInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildStore(_ value: Value, to ptr: Value) -> StoreInst {
        let inst = LLVMBuildStore(ref, value.ref, ptr.ref)!
        return StoreInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildBr(_ dest: BasicBlock) -> BranchInst {
        let inst = LLVMBuildBr(ref, dest.ref)!
        return BranchInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCondBr(_ cond: Value, then: BasicBlock, else elseBlock: BasicBlock) -> BranchInst {
        let inst = LLVMBuildCondBr(ref, cond.ref, then.ref, elseBlock.ref)!
        return BranchInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildICmp(_ predicate: IntPredicate, _ lhs: Value, _ rhs: Value, name: String = "") -> ICmpInst {
        let inst = LLVMBuildICmp(ref, predicate.llvm, lhs.ref, rhs.ref, name)!
        return ICmpInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildIsNull(_ value: Value, name: String = "") -> ICmpInst {
        let inst = LLVMBuildIsNull(ref, value.ref, name)!
        return ICmpInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildIsNotNull(_ value: Value, name: String = "") -> ICmpInst {
        let inst = LLVMBuildIsNotNull(ref, value.ref, name)!
        return ICmpInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFCmp(_ predicate: RealPredicate, _ lhs: Value, _ rhs: Value, name: String = "") -> FCmpInst {
        let inst = LLVMBuildFCmp(ref, predicate.llvm, lhs.ref, rhs.ref, name)!
        return FCmpInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCall(_ function: Function, _ args: [Value], name: String = "") -> CallInst {
        let funcTypeRef = LLVMGlobalGetValueType(function.ref)!
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildCall2(ref, funcTypeRef, function.ref, buffer.baseAddress, UInt32(args.count), name)
        }
        return CallInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCall(_ callee: Value, type: FunctionType, _ args: [Value], name: String = "") -> CallInst {
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildCall2(ref, type.ref, callee.ref, buffer.baseAddress, UInt32(args.count), name)
        }
        return CallInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCallWithOperandBundles(
        _ callee: Value,
        type: FunctionType,
        _ args: [Value],
        bundles: [OperandBundle],
        name: String = ""
    ) -> CallInst {
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        var bundleRefs: [LLVMOperandBundleRef?] = bundles.map { bundle in
            var bundleArgs: [LLVMValueRef?] = bundle.args.map(\.ref)
            return bundleArgs.withUnsafeMutableBufferPointer { buffer in
                bundle.tag.withCString { tagPtr in
                    LLVMCreateOperandBundle(
                        tagPtr,
                        bundle.tag.utf8.count,
                        buffer.baseAddress,
                        UInt32(bundle.args.count)
                    )
                }
            }
        }
        defer {
            for bundle in bundleRefs {
                LLVMDisposeOperandBundle(bundle)
            }
        }
        let inst = argRefs.withUnsafeMutableBufferPointer { argBuf in
            bundleRefs.withUnsafeMutableBufferPointer { bundleBuf in
                LLVMBuildCallWithOperandBundles(
                    ref, type.ref, callee.ref, argBuf.baseAddress, UInt32(args.count),
                    bundleBuf.baseAddress, UInt32(bundles.count), name
                )
            }
        }
        return CallInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildPhi(_ type: LLVMType, name: String = "") -> PHINode {
        let inst = LLVMBuildPhi(ref, type.ref, name)!
        return PHINode(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSelect(_ cond: Value, then: Value, else: Value, name: String = "") -> SelectInst {
        let inst = LLVMBuildSelect(ref, cond.ref, then.ref, `else`.ref, name)!
        return SelectInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildGEP(_ elementType: LLVMType, _ ptr: Value, indices: [Value],
                         name: String = "") -> GetElementPtrInst
    {
        var idxRefs: [LLVMValueRef?] = indices.map(\.ref)
        let inst = idxRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildGEP2(ref, elementType.ref, ptr.ref, buffer.baseAddress, UInt32(indices.count), name)
        }
        return GetElementPtrInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildInBoundsGEP(_ elementType: LLVMType, _ ptr: Value, indices: [Value],
                                 name: String = "") -> GetElementPtrInst
    {
        var idxRefs: [LLVMValueRef?] = indices.map(\.ref)
        let inst = idxRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildInBoundsGEP2(ref, elementType.ref, ptr.ref, buffer.baseAddress, UInt32(indices.count), name)
        }
        return GetElementPtrInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildStructGEP(_ structType: LLVMType, _ ptr: Value, index: UInt32,
                               name: String = "") -> GetElementPtrInst
    {
        let inst = LLVMBuildStructGEP2(ref, structType.ref, ptr.ref, index, name)!
        return GetElementPtrInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildGEPWithNoWrapFlags(
        _ elementType: LLVMType,
        _ ptr: Value,
        indices: [Value],
        noWrapFlags: GEPNoWrapFlags,
        name: String = ""
    ) -> GetElementPtrInst {
        var idxRefs: [LLVMValueRef?] = indices.map(\.ref)
        let inst = idxRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildGEPWithNoWrapFlags(
                ref, elementType.ref, ptr.ref, buffer.baseAddress, UInt32(indices.count), name, noWrapFlags.rawValue
            )
        }
        return GetElementPtrInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildPtrDiff(_ elementType: LLVMType, _ lhs: Value, _ rhs: Value,
                             name: String = "") -> Value
    {
        let inst = LLVMBuildPtrDiff2(ref, elementType.ref, lhs.ref, rhs.ref, name)!
        return Value(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildGlobalString(_ string: String, name: String = "") -> Value {
        let inst = string.withCString { strPtr in
            LLVMBuildGlobalString(ref, strPtr, name)
        }
        return Value(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildGlobalStringPtr(_ string: String, name: String = "") -> Value {
        let inst = string.withCString { strPtr in
            LLVMBuildGlobalStringPtr(ref, strPtr, name)
        }
        return Value(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCast(_ op: CastOpcode, _ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildCast(ref, op.llvm, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildTrunc(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildTrunc(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildZExt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildZExt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSExt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildSExt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildBitCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildPtrToInt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildPtrToInt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildIntToPtr(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildIntToPtr(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFPToUI(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildFPToUI(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFPToSI(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildFPToSI(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildUIToFP(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildUIToFP(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSIToFP(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildSIToFP(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFPTrunc(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildFPTrunc(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFPExt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildFPExt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAddrSpaceCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildAddrSpaceCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildZExtOrBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildZExtOrBitCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSExtOrBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildSExtOrBitCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildTruncOrBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildTruncOrBitCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildPointerCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildPointerCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildIntCast(_ value: Value, to type: LLVMType, isSigned: Bool, name: String = "") -> CastInst {
        let inst = LLVMBuildIntCast2(ref, value.ref, type.ref, isSigned ? 1 : 0, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFPCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst {
        let inst = LLVMBuildFPCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildSwitch(_ value: Value, default dest: BasicBlock, numCases: UInt32 = 0) -> SwitchInst {
        let inst = LLVMBuildSwitch(ref, value.ref, dest.ref, numCases)!
        return SwitchInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildUnreachable() -> UnreachableInst {
        let inst = LLVMBuildUnreachable(ref)!
        return UnreachableInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFence(ordering: AtomicOrdering, singleThread: Bool = false, name: String = "") -> FenceInst {
        let inst = LLVMBuildFence(ref, ordering.llvm, singleThread ? 1 : 0, name)!
        return FenceInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFenceSyncScope(ordering: AtomicOrdering, scope: UInt32, name: String = "") -> FenceInst {
        let inst = LLVMBuildFenceSyncScope(ref, ordering.llvm, scope, name)!
        return FenceInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAtomicRMW(
        _ op: AtomicRMWBinOp,
        _ ptr: Value,
        _ value: Value,
        ordering: AtomicOrdering,
        singleThread: Bool = false
    ) -> AtomicRMWInst {
        let inst = LLVMBuildAtomicRMW(ref, op.llvm, ptr.ref, value.ref, ordering.llvm, singleThread ? 1 : 0)!
        return AtomicRMWInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAtomicRMWSyncScope(
        _ op: AtomicRMWBinOp,
        _ ptr: Value,
        _ value: Value,
        ordering: AtomicOrdering,
        scope: UInt32
    ) -> AtomicRMWInst {
        let inst = LLVMBuildAtomicRMWSyncScope(ref, op.llvm, ptr.ref, value.ref, ordering.llvm, scope)!
        return AtomicRMWInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildAtomicCmpXchg(
        _ ptr: Value,
        _ cmp: Value,
        _ new: Value,
        successOrdering: AtomicOrdering,
        failureOrdering: AtomicOrdering,
        singleThread: Bool = false
    ) -> AtomicCmpXchgInst {
        let inst = LLVMBuildAtomicCmpXchg(
            ref,
            ptr.ref,
            cmp.ref,
            new.ref,
            successOrdering.llvm,
            failureOrdering.llvm,
            singleThread ? 1 : 0
        )!
        return AtomicCmpXchgInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildExtractValue(_ aggregate: Value, index: UInt32, name: String = "") -> ExtractValueInst {
        let inst = LLVMBuildExtractValue(ref, aggregate.ref, index, name)!
        return ExtractValueInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildInsertValue(_ aggregate: Value, _ element: Value, index: UInt32,
                                 name: String = "") -> InsertValueInst
    {
        let inst = LLVMBuildInsertValue(ref, aggregate.ref, element.ref, index, name)!
        return InsertValueInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildExtractElement(_ vector: Value, _ index: Value, name: String = "") -> ExtractElementInst {
        let inst = LLVMBuildExtractElement(ref, vector.ref, index.ref, name)!
        return ExtractElementInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildInsertElement(_ vector: Value, _ element: Value, _ index: Value,
                                   name: String = "") -> InsertElementInst
    {
        let inst = LLVMBuildInsertElement(ref, vector.ref, element.ref, index.ref, name)!
        return InsertElementInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildShuffleVector(_ v1: Value, _ v2: Value, mask: Value, name: String = "") -> ShuffleVectorInst {
        let inst = LLVMBuildShuffleVector(ref, v1.ref, v2.ref, mask.ref, name)!
        return ShuffleVectorInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildFreeze(_ value: Value, name: String = "") -> FreezeInst {
        let inst = LLVMBuildFreeze(ref, value.ref, name)!
        return FreezeInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildVAArg(_ list: Value, type: LLVMType, name: String = "") -> VAArgInst {
        let inst = LLVMBuildVAArg(ref, list.ref, type.ref, name)!
        return VAArgInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildResume(_ exn: Value) -> ResumeInst {
        let inst = LLVMBuildResume(ref, exn.ref)!
        return ResumeInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildLandingPad(_ type: LLVMType, personality: Value? = nil, numClauses: UInt32 = 0,
                                name: String = "") -> LandingPadInst
    {
        let inst = LLVMBuildLandingPad(ref, type.ref, personality?.ref, numClauses, name)!
        return LandingPadInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildInvoke(
        _ function: Function,
        _ args: [Value],
        then: BasicBlock,
        catch: BasicBlock,
        name: String = ""
    ) -> InvokeInst {
        let funcTypeRef = LLVMGlobalGetValueType(function.ref)!
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildInvoke2(
                ref,
                funcTypeRef,
                function.ref,
                buffer.baseAddress,
                UInt32(args.count),
                then.ref,
                `catch`.ref,
                name
            )
        }
        return InvokeInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildInvoke(
        _ callee: Value,
        type: FunctionType,
        _ args: [Value],
        then: BasicBlock,
        catch: BasicBlock,
        name: String = ""
    ) -> InvokeInst {
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildInvoke2(
                ref,
                type.ref,
                callee.ref,
                buffer.baseAddress,
                UInt32(args.count),
                then.ref,
                `catch`.ref,
                name
            )
        }
        return InvokeInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildInvokeWithOperandBundles(
        _ callee: Value,
        type: FunctionType,
        _ args: [Value],
        bundles: [OperandBundle],
        then: BasicBlock,
        catch: BasicBlock,
        name: String = ""
    ) -> InvokeInst {
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        var bundleRefs: [LLVMOperandBundleRef?] = bundles.map { bundle in
            var bundleArgs: [LLVMValueRef?] = bundle.args.map(\.ref)
            return bundleArgs.withUnsafeMutableBufferPointer { buffer in
                bundle.tag.withCString { tagPtr in
                    LLVMCreateOperandBundle(
                        tagPtr,
                        bundle.tag.utf8.count,
                        buffer.baseAddress,
                        UInt32(bundle.args.count)
                    )
                }
            }
        }
        defer {
            for bundle in bundleRefs {
                LLVMDisposeOperandBundle(bundle)
            }
        }
        let inst = argRefs.withUnsafeMutableBufferPointer { argBuf in
            bundleRefs.withUnsafeMutableBufferPointer { bundleBuf in
                LLVMBuildInvokeWithOperandBundles(
                    ref, type.ref, callee.ref, argBuf.baseAddress, UInt32(args.count),
                    then.ref, `catch`.ref, bundleBuf.baseAddress, UInt32(bundles.count), name
                )
            }
        }
        return InvokeInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildIndirectBr(_ addr: Value, numDests: UInt32 = 0) -> IndirectBrInst {
        let inst = LLVMBuildIndirectBr(ref, addr.ref, numDests)!
        return IndirectBrInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildMemSet(_ ptr: Value, _ value: Value, _ len: Value, alignment: UInt32 = 0) -> CallInst {
        let inst = LLVMBuildMemSet(ref, ptr.ref, value.ref, len.ref, alignment)!
        return CallInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildMemCpy(_ dest: Value, destAlign: UInt32 = 0, _ source: Value, sourceAlign: UInt32 = 0,
                            _ len: Value) -> CallInst
    {
        let inst = LLVMBuildMemCpy(ref, dest.ref, destAlign, source.ref, sourceAlign, len.ref)!
        return CallInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildMemMove(
        _ dest: Value,
        destAlign: UInt32 = 0,
        _ source: Value,
        sourceAlign: UInt32 = 0,
        _ len: Value
    ) -> CallInst {
        let inst = LLVMBuildMemMove(ref, dest.ref, destAlign, source.ref, sourceAlign, len.ref)!
        return CallInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCallBr(
        _ callee: Value,
        args: [Value],
        default dest: BasicBlock,
        indirectDests: [BasicBlock],
        bundles: [OperandBundle] = [],
        name: String = ""
    ) -> CallBrInst {
        let calleeType: LLVMType = if LLVMGetValueKind(callee.ref) == LLVMInlineAsmValueKind {
            LLVMType(ref: LLVMGetInlineAsmFunctionType(callee.ref)!, context: context)
        } else if let fn = callee as? Function {
            LLVMType(ref: LLVMGlobalGetValueType(fn.ref)!, context: context)
        } else {
            callee.type
        }
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        var destRefs: [LLVMBasicBlockRef?] = indirectDests.map(\.ref)
        var bundleRefs: [LLVMOperandBundleRef?] = []
        for bundle in bundles {
            var bundleArgs: [LLVMValueRef?] = bundle.args.map(\.ref)
            let bundleRef = bundleArgs.withUnsafeMutableBufferPointer { buffer in
                LLVMCreateOperandBundle(
                    bundle.tag,
                    bundle.tag.utf8.count,
                    buffer.baseAddress,
                    UInt32(bundle.args.count)
                )
            }
            bundleRefs.append(bundleRef)
        }
        defer {
            for bundleRef in bundleRefs {
                LLVMDisposeOperandBundle(bundleRef)
            }
        }
        let inst = argRefs.withUnsafeMutableBufferPointer { argBuf in
            destRefs.withUnsafeMutableBufferPointer { destBuf in
                bundleRefs.withUnsafeMutableBufferPointer { bundleBuf in
                    LLVMBuildCallBr(
                        ref,
                        calleeType.ref,
                        callee.ref,
                        dest.ref,
                        destBuf.baseAddress,
                        UInt32(indirectDests.count),
                        argBuf.baseAddress,
                        UInt32(args.count),
                        bundleBuf.baseAddress,
                        UInt32(bundles.count),
                        name
                    )
                }
            }
        }
        return CallBrInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCleanupRet(_ cleanupPad: CleanupPadInst, to block: BasicBlock?) -> CleanupRetInst {
        let inst = LLVMBuildCleanupRet(ref, cleanupPad.ref, block?.ref)!
        return CleanupRetInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCatchRet(_ catchPad: CatchPadInst, to block: BasicBlock) -> CatchRetInst {
        let inst = LLVMBuildCatchRet(ref, catchPad.ref, block.ref)!
        return CatchRetInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCatchPad(parentPad: Value?, args: [Value] = [], name: String = "") -> CatchPadInst {
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildCatchPad(ref, parentPad?.ref, buffer.baseAddress, UInt32(args.count), name)
        }
        return CatchPadInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCleanupPad(parentPad: Value?, args: [Value] = [], name: String = "") -> CleanupPadInst {
        var argRefs: [LLVMValueRef?] = args.map(\.ref)
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildCleanupPad(ref, parentPad?.ref, buffer.baseAddress, UInt32(args.count), name)
        }
        return CleanupPadInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    public func buildCatchSwitch(parentPad: Value?, unwind: BasicBlock?, numHandlers: UInt32 = 0,
                                 name: String = "") -> CatchSwitchInst
    {
        let inst = LLVMBuildCatchSwitch(ref, parentPad?.ref, unwind?.ref, numHandlers, name)!
        return CatchSwitchInst(ref: inst, context: context, module: currentModule)
    }
}
