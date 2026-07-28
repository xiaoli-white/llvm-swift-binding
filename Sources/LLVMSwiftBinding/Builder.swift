import cLLVM

final class Builder {
    let ref: LLVMBuilderRef
    let context: Context
    private var currentModule: Module?

    init(in context: Context) {
        self.ref = LLVMCreateBuilderInContext(context.ref)!
        self.context = context
    }

    deinit {
        LLVMDisposeBuilder(ref)
    }

    func positionAtEnd(of block: BasicBlock) {
        currentModule = block.module
        LLVMPositionBuilderAtEnd(ref, block.ref)
    }

    @discardableResult
    func buildRet(_ value: Value) -> ReturnInst {
        let inst = LLVMBuildRet(ref, value.ref)!
        return ReturnInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildRetVoid() -> ReturnInst {
        let inst = LLVMBuildRetVoid(ref)!
        return ReturnInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildAdd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildSub(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildMul(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildUDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildUDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildSDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildURem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildURem(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSRem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildSRem(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFAdd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFSub(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFMul(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFDiv(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFRem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildFRem(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildShl(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildShl(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildLShr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildLShr(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildAShr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildAShr(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildAnd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildAnd(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildOr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildOr(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildXor(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator {
        let inst = LLVMBuildXor(ref, lhs.ref, rhs.ref, name)!
        return BinaryOperator(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildAlloca(_ type: Type, name: String = "") -> AllocaInst {
        let inst = LLVMBuildAlloca(ref, type.ref, name)!
        return AllocaInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildLoad(_ type: Type, _ ptr: Value, name: String = "") -> LoadInst {
        let inst = LLVMBuildLoad2(ref, type.ref, ptr.ref, name)!
        return LoadInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildStore(_ value: Value, to ptr: Value) -> StoreInst {
        let inst = LLVMBuildStore(ref, value.ref, ptr.ref)!
        return StoreInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildBr(_ dest: BasicBlock) -> BranchInst {
        let inst = LLVMBuildBr(ref, dest.ref)!
        return BranchInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildCondBr(_ cond: Value, then: BasicBlock, `else` elseBlock: BasicBlock) -> BranchInst {
        let inst = LLVMBuildCondBr(ref, cond.ref, then.ref, elseBlock.ref)!
        return BranchInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildICmp(_ predicate: LLVMIntPredicate, _ lhs: Value, _ rhs: Value, name: String = "") -> ICmpInst {
        let inst = LLVMBuildICmp(ref, predicate, lhs.ref, rhs.ref, name)!
        return ICmpInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFCmp(_ predicate: LLVMRealPredicate, _ lhs: Value, _ rhs: Value, name: String = "") -> FCmpInst {
        let inst = LLVMBuildFCmp(ref, predicate, lhs.ref, rhs.ref, name)!
        return FCmpInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildCall(_ function: Function, _ args: [Value], name: String = "") -> CallInst {
        let funcTypeRef = LLVMGlobalGetValueType(function.ref)!
        var argRefs: [LLVMValueRef?] = args.map { $0.ref }
        let inst = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildCall2(ref, funcTypeRef, function.ref, buffer.baseAddress, UInt32(args.count), name)
        }
        return CallInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    func buildPhi(_ type: Type, name: String = "") -> PHINode {
        let inst = LLVMBuildPhi(ref, type.ref, name)!
        return PHINode(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSelect(_ cond: Value, then: Value, `else`: Value, name: String = "") -> SelectInst {
        let inst = LLVMBuildSelect(ref, cond.ref, then.ref, `else`.ref, name)!
        return SelectInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildGEP(_ elementType: Type, _ ptr: Value, indices: [Value], name: String = "") -> GetElementPtrInst {
        var idxRefs: [LLVMValueRef?] = indices.map { $0.ref }
        let inst = idxRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMBuildGEP2(ref, elementType.ref, ptr.ref, buffer.baseAddress, UInt32(indices.count), name)
        }
        return GetElementPtrInst(ref: inst!, context: context, module: currentModule)
    }

    @discardableResult
    func buildTrunc(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildTrunc(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildZExt(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildZExt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSExt(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildSExt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildBitCast(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildBitCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildPtrToInt(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildPtrToInt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildIntToPtr(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildIntToPtr(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFPToUI(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildFPToUI(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFPToSI(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildFPToSI(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildUIToFP(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildUIToFP(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSIToFP(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildSIToFP(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFPTrunc(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildFPTrunc(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildFPExt(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildFPExt(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildAddrSpaceCast(_ value: Value, to type: Type, name: String = "") -> CastInst {
        let inst = LLVMBuildAddrSpaceCast(ref, value.ref, type.ref, name)!
        return CastInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildSwitch(_ value: Value, default dest: BasicBlock, numCases: UInt32 = 0) -> SwitchInst {
        let inst = LLVMBuildSwitch(ref, value.ref, dest.ref, numCases)!
        return SwitchInst(ref: inst, context: context, module: currentModule)
    }
}
