import cLLVM

public struct OperandBundle {
    public let tag: String
    public let args: [Value]

    public init(tag: String, args: [Value]) {
        self.tag = tag
        self.args = args
    }
}

public class Instruction: Value {
    public static func wrap(_ ref: LLVMValueRef, context: Context, module: Module?) -> Instruction {
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

    public var operandBundles: [OperandBundle] {
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

    public var debugLocLine: UInt32 {
        LLVMGetDebugLocLine(ref)
    }

    public var debugLocColumn: UInt32 {
        LLVMGetDebugLocColumn(ref)
    }

    public var debugLocFilename: String? {
        var length: UInt32 = 0
        guard let ptr = LLVMGetDebugLocFilename(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: Int(length)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var debugLocDirectory: String? {
        var length: UInt32 = 0
        guard let ptr = LLVMGetDebugLocDirectory(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: Int(length)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var parentBlock: BasicBlock? {
        guard let blockRef = LLVMGetInstructionParent(ref) else { return nil }
        return basicBlock(from: blockRef)
    }

    fileprivate func basicBlock(from blockRef: LLVMBasicBlockRef) -> BasicBlock? {
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

    public func clone() -> Instruction? {
        guard let ref = LLVMInstructionClone(ref) else { return nil }
        return Instruction.wrap(ref, context: context, module: module)
    }

    public func removeFromParent() {
        LLVMInstructionRemoveFromParent(ref)
    }

    public func eraseFromParent() {
        LLVMInstructionEraseFromParent(ref)
    }
}

public final class ReturnInst: Instruction {}

public final class BinaryOperator: Instruction {}

public final class AllocaInst: Instruction {}

public final class LoadInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }

    public var ordering: LLVMAtomicOrdering {
        get { LLVMGetOrdering(ref) }
        set { LLVMSetOrdering(ref, newValue) }
    }
}

public final class StoreInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }

    public var ordering: LLVMAtomicOrdering {
        get { LLVMGetOrdering(ref) }
        set { LLVMSetOrdering(ref, newValue) }
    }
}

public final class BranchInst: Instruction {}

public final class SwitchInst: Instruction {
    public func addCase(_ on: Value, _ dest: BasicBlock) {
        LLVMAddCase(ref, on.ref, dest.ref)
    }

    public var condition: Value? {
        operand(at: 0)
    }

    public var defaultDestination: BasicBlock? {
        guard let block = LLVMGetSwitchDefaultDest(ref) else { return nil }
        return basicBlock(from: block)
    }

    public var caseCount: UInt32 {
        let successors = LLVMGetNumSuccessors(ref)
        return successors > 0 ? successors - 1 : 0
    }

    public func caseDestination(at index: UInt32) -> BasicBlock? {
        guard let block = LLVMGetSuccessor(ref, index + 1) else { return nil }
        return basicBlock(from: block)
    }
}

public final class ICmpInst: Instruction {}

public final class FCmpInst: Instruction {}

public final class CallInst: Instruction {
    public var isTailCall: Bool {
        get { LLVMIsTailCall(ref) != 0 }
        set { LLVMSetTailCall(ref, newValue ? 1 : 0) }
    }

    public var tailCallKind: LLVMTailCallKind {
        get { LLVMGetTailCallKind(ref) }
        set { LLVMSetTailCallKind(ref, newValue) }
    }

    public var callConvention: LLVMCallConv {
        get { LLVMCallConv(rawValue: LLVMGetInstructionCallConv(ref)) }
        set { LLVMSetInstructionCallConv(ref, newValue.rawValue) }
    }

    public var calledValue: Value? {
        guard let ref = LLVMGetCalledValue(ref) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }

    public var calledFunctionType: Type? {
        guard let ref = LLVMGetCalledFunctionType(ref) else { return nil }
        return context.wrapType(ref)
    }
}

public final class CallBrInst: Instruction {}

public final class PHINode: Instruction {
    public func addIncoming(_ value: Value, from block: BasicBlock) {
        var val: LLVMValueRef? = value.ref
        var blk: LLVMBasicBlockRef? = block.ref
        LLVMAddIncoming(ref, &val, &blk, 1)
    }

    public func addIncoming(_ values: [(value: Value, block: BasicBlock)]) {
        let count = UInt32(values.count)
        var vals: [LLVMValueRef?] = values.map { $0.value.ref }
        var blks: [LLVMBasicBlockRef?] = values.map { $0.block.ref }
        vals.withUnsafeMutableBufferPointer { valBuf in
            blks.withUnsafeMutableBufferPointer { blkBuf in
                LLVMAddIncoming(ref, valBuf.baseAddress, blkBuf.baseAddress, count)
            }
        }
    }

    public var incomingCount: UInt32 {
        LLVMCountIncoming(ref)
    }

    public func incomingValue(at index: UInt32) -> Value {
        Value(ref: LLVMGetIncomingValue(ref, index)!, context: context, module: module)
    }

    public func incomingBlock(at index: UInt32) -> BasicBlock? {
        guard let block = LLVMGetIncomingBlock(ref, index) else { return nil }
        return basicBlock(from: block)
    }
}

public final class SelectInst: Instruction {}

public final class GetElementPtrInst: Instruction {}

public final class CastInst: Instruction {
    public var value: Value? {
        operand(at: 0)
    }

    public var destinationType: Type {
        type
    }
}

public final class UnreachableInst: Instruction {}

public final class FenceInst: Instruction {}

public final class AtomicRMWInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }

    public var ordering: LLVMAtomicOrdering {
        get { LLVMGetOrdering(ref) }
        set { LLVMSetOrdering(ref, newValue) }
    }

    public var binOp: LLVMAtomicRMWBinOp {
        get { LLVMGetAtomicRMWBinOp(ref) }
        set { LLVMSetAtomicRMWBinOp(ref, newValue) }
    }
}

public final class AtomicCmpXchgInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }
}

public final class ExtractValueInst: Instruction {}

public final class InsertValueInst: Instruction {}

public final class ExtractElementInst: Instruction {}

public final class InsertElementInst: Instruction {}

public final class ShuffleVectorInst: Instruction {}

public final class FreezeInst: Instruction {}

public final class VAArgInst: Instruction {}

public final class ResumeInst: Instruction {}

public final class InvokeInst: Instruction {
    public func addClause(_ clause: Value) {
        LLVMAddClause(ref, clause.ref)
    }
}

public final class LandingPadInst: Instruction {
    public var isCleanup: Bool {
        get { LLVMIsCleanup(ref) != 0 }
        set { LLVMSetCleanup(ref, newValue ? 1 : 0) }
    }

    public var clauseCount: UInt32 {
        LLVMGetNumClauses(ref)
    }

    public func clause(at index: UInt32) -> Value {
        Value(ref: LLVMGetClause(ref, index)!, context: context, module: module)
    }

    public func addClause(_ clause: Value) {
        LLVMAddClause(ref, clause.ref)
    }
}

public final class CatchPadInst: Instruction {}

public final class CleanupPadInst: Instruction {}

public final class IndirectBrInst: Instruction {
    public func addDestination(_ dest: BasicBlock) {
        LLVMAddDestination(ref, dest.ref)
    }
}

public final class CleanupRetInst: Instruction {}

public final class CatchRetInst: Instruction {}

public final class CatchSwitchInst: Instruction {
    public func addHandler(_ handler: BasicBlock) {
        LLVMAddHandler(ref, handler.ref)
    }
}
