import cLLVM

struct OperandBundle {
    let tag: String
    let args: [Value]
}

class Instruction: Value {
    static func wrap(_ ref: LLVMValueRef, context: Context, module: Module?) -> Instruction {
        let inst: Instruction
        switch LLVMGetInstructionOpcode(ref) {
        case LLVMRet:
            inst = ReturnInst(ref: ref, context: context, module: module)
        case LLVMBr:
            inst = BranchInst(ref: ref, context: context, module: module)
        case LLVMSwitch:
            inst = SwitchInst(ref: ref, context: context, module: module)
        case LLVMIndirectBr:
            inst = IndirectBrInst(ref: ref, context: context, module: module)
        case LLVMInvoke:
            inst = InvokeInst(ref: ref, context: context, module: module)
        case LLVMUnreachable:
            inst = UnreachableInst(ref: ref, context: context, module: module)
        case LLVMAlloca:
            inst = AllocaInst(ref: ref, context: context, module: module)
        case LLVMLoad:
            inst = LoadInst(ref: ref, context: context, module: module)
        case LLVMStore:
            inst = StoreInst(ref: ref, context: context, module: module)
        case LLVMGetElementPtr:
            inst = GetElementPtrInst(ref: ref, context: context, module: module)
        case LLVMICmp:
            inst = ICmpInst(ref: ref, context: context, module: module)
        case LLVMFCmp:
            inst = FCmpInst(ref: ref, context: context, module: module)
        case LLVMCall:
            inst = CallInst(ref: ref, context: context, module: module)
        case LLVMCallBr:
            inst = CallBrInst(ref: ref, context: context, module: module)
        case LLVMPHI:
            inst = PHINode(ref: ref, context: context, module: module)
        case LLVMSelect:
            inst = SelectInst(ref: ref, context: context, module: module)
        case LLVMVAArg:
            inst = VAArgInst(ref: ref, context: context, module: module)
        case LLVMExtractElement:
            inst = ExtractElementInst(ref: ref, context: context, module: module)
        case LLVMInsertElement:
            inst = InsertElementInst(ref: ref, context: context, module: module)
        case LLVMShuffleVector:
            inst = ShuffleVectorInst(ref: ref, context: context, module: module)
        case LLVMExtractValue:
            inst = ExtractValueInst(ref: ref, context: context, module: module)
        case LLVMInsertValue:
            inst = InsertValueInst(ref: ref, context: context, module: module)
        case LLVMFreeze:
            inst = FreezeInst(ref: ref, context: context, module: module)
        case LLVMFence:
            inst = FenceInst(ref: ref, context: context, module: module)
        case LLVMAtomicCmpXchg:
            inst = AtomicCmpXchgInst(ref: ref, context: context, module: module)
        case LLVMAtomicRMW:
            inst = AtomicRMWInst(ref: ref, context: context, module: module)
        case LLVMResume:
            inst = ResumeInst(ref: ref, context: context, module: module)
        case LLVMLandingPad:
            inst = LandingPadInst(ref: ref, context: context, module: module)
        case LLVMCleanupRet:
            inst = CleanupRetInst(ref: ref, context: context, module: module)
        case LLVMCatchRet:
            inst = CatchRetInst(ref: ref, context: context, module: module)
        case LLVMCatchPad:
            inst = CatchPadInst(ref: ref, context: context, module: module)
        case LLVMCleanupPad:
            inst = CleanupPadInst(ref: ref, context: context, module: module)
        case LLVMCatchSwitch:
            inst = CatchSwitchInst(ref: ref, context: context, module: module)
        default:
            inst = BinaryOperator(ref: ref, context: context, module: module)
        }
        return inst
    }

    var operandBundles: [OperandBundle] {
        let opcode = LLVMGetInstructionOpcode(ref)
        guard opcode == LLVMCall || opcode == LLVMInvoke || opcode == LLVMCallBr else { return [] }
        let count = LLVMGetNumOperandBundles(ref)
        guard count > 0 else { return [] }
        var result: [OperandBundle] = []
        for i in 0..<count {
            let bundleRef = LLVMGetOperandBundleAtIndex(ref, i)
            defer { LLVMDisposeOperandBundle(bundleRef) }
            var tagLength: Int = 0
            let tag = String(cString: LLVMGetOperandBundleTag(bundleRef, &tagLength))
            let argCount = LLVMGetNumOperandBundleArgs(bundleRef)
            var args: [Value] = []
            for j in 0..<argCount {
                args.append(Value(ref: LLVMGetOperandBundleArgAtIndex(bundleRef, j)!, context: context, module: module))
            }
            result.append(OperandBundle(tag: tag, args: args))
        }
        return result
    }

    var debugLocLine: UInt32 {
        LLVMGetDebugLocLine(ref)
    }

    var debugLocColumn: UInt32 {
        LLVMGetDebugLocColumn(ref)
    }

    var debugLocFilename: String? {
        var length: UInt32 = 0
        guard let ptr = LLVMGetDebugLocFilename(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: Int(length)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    var debugLocDirectory: String? {
        var length: UInt32 = 0
        guard let ptr = LLVMGetDebugLocDirectory(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: Int(length)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    var parentBlock: BasicBlock? {
        guard let blockRef = LLVMGetInstructionParent(ref) else { return nil }
        guard let fnRef = LLVMGetBasicBlockParent(blockRef) else { return nil }
        let fnModule: Module
        if let module {
            fnModule = module
        } else {
            fnModule = Module(ref: LLVMGetGlobalParent(fnRef)!, context: context)
            fnModule.ownsRef = false
        }
        return BasicBlock(ref: blockRef, function: Function(ref: fnRef, module: fnModule), module: fnModule)
    }

    func clone() -> Instruction? {
        guard let ref = LLVMInstructionClone(ref) else { return nil }
        return Instruction.wrap(ref, context: context, module: module)
    }
}

final class ReturnInst: Instruction {}

final class BinaryOperator: Instruction {}

final class AllocaInst: Instruction {}

final class LoadInst: Instruction {}

final class StoreInst: Instruction {}

final class BranchInst: Instruction {}

final class SwitchInst: Instruction {
    func addCase(_ on: Value, _ dest: BasicBlock) {
        LLVMAddCase(ref, on.ref, dest.ref)
    }
}

final class ICmpInst: Instruction {}

final class FCmpInst: Instruction {}

final class CallInst: Instruction {
    var isTailCall: Bool {
        get { LLVMIsTailCall(ref) != 0 }
        set { LLVMSetTailCall(ref, newValue ? 1 : 0) }
    }

    var tailCallKind: LLVMTailCallKind {
        get { LLVMGetTailCallKind(ref) }
        set { LLVMSetTailCallKind(ref, newValue) }
    }

    var callConvention: LLVMCallConv {
        get { LLVMCallConv(rawValue: LLVMGetInstructionCallConv(ref)) }
        set { LLVMSetInstructionCallConv(ref, newValue.rawValue) }
    }

    var calledValue: Value? {
        guard let ref = LLVMGetCalledValue(ref) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }

    var calledFunctionType: Type? {
        guard let ref = LLVMGetCalledFunctionType(ref) else { return nil }
        return context.wrapType(ref)
    }
}

final class CallBrInst: Instruction {}

final class PHINode: Instruction {
    func addIncoming(_ value: Value, from block: BasicBlock) {
        var val: LLVMValueRef? = value.ref
        var blk: LLVMBasicBlockRef? = block.ref
        LLVMAddIncoming(ref, &val, &blk, 1)
    }

    func addIncoming(_ values: [(value: Value, block: BasicBlock)]) {
        let count = UInt32(values.count)
        var vals: [LLVMValueRef?] = values.map { $0.value.ref }
        var blks: [LLVMBasicBlockRef?] = values.map { $0.block.ref }
        vals.withUnsafeMutableBufferPointer { valBuf in
            blks.withUnsafeMutableBufferPointer { blkBuf in
                LLVMAddIncoming(ref, valBuf.baseAddress, blkBuf.baseAddress, count)
            }
        }
    }
}

final class SelectInst: Instruction {}

final class GetElementPtrInst: Instruction {}

final class CastInst: Instruction {}

final class UnreachableInst: Instruction {}

final class FenceInst: Instruction {}

final class AtomicRMWInst: Instruction {}

final class AtomicCmpXchgInst: Instruction {}

final class ExtractValueInst: Instruction {}

final class InsertValueInst: Instruction {}

final class ExtractElementInst: Instruction {}

final class InsertElementInst: Instruction {}

final class ShuffleVectorInst: Instruction {}

final class FreezeInst: Instruction {}

final class VAArgInst: Instruction {}

final class ResumeInst: Instruction {}

final class InvokeInst: Instruction {
    func addClause(_ clause: Value) {
        LLVMAddClause(ref, clause.ref)
    }
}

final class LandingPadInst: Instruction {
    var isCleanup: Bool {
        get { LLVMIsCleanup(ref) != 0 }
        set { LLVMSetCleanup(ref, newValue ? 1 : 0) }
    }

    var clauseCount: UInt32 {
        LLVMGetNumClauses(ref)
    }

    func clause(at index: UInt32) -> Value {
        Value(ref: LLVMGetClause(ref, index)!, context: context, module: module)
    }

    func addClause(_ clause: Value) {
        LLVMAddClause(ref, clause.ref)
    }
}

final class CatchPadInst: Instruction {}

final class CleanupPadInst: Instruction {}

final class IndirectBrInst: Instruction {
    func addDestination(_ dest: BasicBlock) {
        LLVMAddDestination(ref, dest.ref)
    }
}

final class CleanupRetInst: Instruction {}

final class CatchRetInst: Instruction {}

final class CatchSwitchInst: Instruction {
    func addHandler(_ handler: BasicBlock) {
        LLVMAddHandler(ref, handler.ref)
    }
}
