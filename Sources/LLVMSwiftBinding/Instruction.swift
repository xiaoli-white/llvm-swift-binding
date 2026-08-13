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
        let inst: Instruction = switch LLVMGetInstructionOpcode(ref) {
        case LLVMRet:
            ReturnInst(ref: ref, context: context, module: module)
        case LLVMBr:
            BranchInst(ref: ref, context: context, module: module)
        case LLVMSwitch:
            SwitchInst(ref: ref, context: context, module: module)
        case LLVMIndirectBr:
            IndirectBrInst(ref: ref, context: context, module: module)
        case LLVMInvoke:
            InvokeInst(ref: ref, context: context, module: module)
        case LLVMUnreachable:
            UnreachableInst(ref: ref, context: context, module: module)
        case LLVMAlloca:
            AllocaInst(ref: ref, context: context, module: module)
        case LLVMLoad:
            LoadInst(ref: ref, context: context, module: module)
        case LLVMStore:
            StoreInst(ref: ref, context: context, module: module)
        case LLVMGetElementPtr:
            GetElementPtrInst(ref: ref, context: context, module: module)
        case LLVMICmp:
            ICmpInst(ref: ref, context: context, module: module)
        case LLVMFCmp:
            FCmpInst(ref: ref, context: context, module: module)
        case LLVMCall:
            CallInst(ref: ref, context: context, module: module)
        case LLVMCallBr:
            CallBrInst(ref: ref, context: context, module: module)
        case LLVMPHI:
            PHINode(ref: ref, context: context, module: module)
        case LLVMSelect:
            SelectInst(ref: ref, context: context, module: module)
        case LLVMVAArg:
            VAArgInst(ref: ref, context: context, module: module)
        case LLVMExtractElement:
            ExtractElementInst(ref: ref, context: context, module: module)
        case LLVMInsertElement:
            InsertElementInst(ref: ref, context: context, module: module)
        case LLVMShuffleVector:
            ShuffleVectorInst(ref: ref, context: context, module: module)
        case LLVMExtractValue:
            ExtractValueInst(ref: ref, context: context, module: module)
        case LLVMInsertValue:
            InsertValueInst(ref: ref, context: context, module: module)
        case LLVMFreeze:
            FreezeInst(ref: ref, context: context, module: module)
        case LLVMFence:
            FenceInst(ref: ref, context: context, module: module)
        case LLVMAtomicCmpXchg:
            AtomicCmpXchgInst(ref: ref, context: context, module: module)
        case LLVMAtomicRMW:
            AtomicRMWInst(ref: ref, context: context, module: module)
        case LLVMResume:
            ResumeInst(ref: ref, context: context, module: module)
        case LLVMLandingPad:
            LandingPadInst(ref: ref, context: context, module: module)
        case LLVMCleanupRet:
            CleanupRetInst(ref: ref, context: context, module: module)
        case LLVMCatchRet:
            CatchRetInst(ref: ref, context: context, module: module)
        case LLVMCatchPad:
            CatchPadInst(ref: ref, context: context, module: module)
        case LLVMCleanupPad:
            CleanupPadInst(ref: ref, context: context, module: module)
        case LLVMCatchSwitch:
            CatchSwitchInst(ref: ref, context: context, module: module)
        default:
            BinaryOperator(ref: ref, context: context, module: module)
        }
        return inst
    }

    public var opcode: LLVMOpcode {
        LLVMGetInstructionOpcode(ref)
    }

    public var opcodeName: String {
        switch opcode {
        case LLVMRet: "ret"
        case LLVMBr: "br"
        case LLVMSwitch: "switch"
        case LLVMIndirectBr: "indirectbr"
        case LLVMInvoke: "invoke"
        case LLVMUnreachable: "unreachable"
        case LLVMAlloca: "alloca"
        case LLVMLoad: "load"
        case LLVMStore: "store"
        case LLVMGetElementPtr: "getelementptr"
        case LLVMICmp: "icmp"
        case LLVMFCmp: "fcmp"
        case LLVMCall: "call"
        case LLVMCallBr: "callbr"
        case LLVMPHI: "phi"
        case LLVMSelect: "select"
        case LLVMAdd: "add"
        case LLVMSub: "sub"
        case LLVMMul: "mul"
        case LLVMUDiv: "udiv"
        case LLVMSDiv: "sdiv"
        case LLVMURem: "urem"
        case LLVMSRem: "srem"
        case LLVMShl: "shl"
        case LLVMLShr: "lshr"
        case LLVMAShr: "ashr"
        case LLVMAnd: "and"
        case LLVMOr: "or"
        case LLVMXor: "xor"
        case LLVMFAdd: "fadd"
        case LLVMFSub: "fsub"
        case LLVMFMul: "fmul"
        case LLVMFDiv: "fdiv"
        case LLVMFRem: "frem"
        case LLVMFNeg: "fneg"
        case LLVMTrunc: "trunc"
        case LLVMZExt: "zext"
        case LLVMSExt: "sext"
        case LLVMFPToUI: "fptoui"
        case LLVMFPToSI: "fptosi"
        case LLVMUIToFP: "uitofp"
        case LLVMSIToFP: "sitofp"
        case LLVMFPTrunc: "fptrunc"
        case LLVMFPExt: "fpext"
        case LLVMPtrToInt: "ptrtoint"
        case LLVMIntToPtr: "inttoptr"
        case LLVMBitCast: "bitcast"
        case LLVMAddrSpaceCast: "addrspacecast"
        case LLVMExtractElement: "extractelement"
        case LLVMInsertElement: "insertelement"
        case LLVMShuffleVector: "shufflevector"
        case LLVMExtractValue: "extractvalue"
        case LLVMInsertValue: "insertvalue"
        case LLVMFreeze: "freeze"
        case LLVMLandingPad: "landingpad"
        default: "unknown"
        }
    }

    public var operandBundles: [OperandBundle] {
        let opcode = LLVMGetInstructionOpcode(ref)
        guard opcode == LLVMCall || opcode == LLVMInvoke || opcode == LLVMCallBr else { return [] }
        let count = LLVMGetNumOperandBundles(ref)
        guard count > 0 else { return [] }
        var result: [OperandBundle] = []
        for i in 0 ..< count {
            let bundleRef = LLVMGetOperandBundleAtIndex(ref, i)
            defer { LLVMDisposeOperandBundle(bundleRef) }
            var tagLength = 0
            let tag = String(cString: LLVMGetOperandBundleTag(bundleRef, &tagLength))
            let argCount = LLVMGetNumOperandBundleArgs(bundleRef)
            var args: [Value] = []
            for j in 0 ..< argCount {
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

public final class ICmpInst: Instruction {
    public var predicate: LLVMIntPredicate {
        LLVMGetICmpPredicate(ref)
    }
}

public final class FCmpInst: Instruction {
    public var predicate: LLVMRealPredicate {
        LLVMGetFCmpPredicate(ref)
    }
}

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

    public var calledFunctionType: LLVMType? {
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
        var vals: [LLVMValueRef?] = values.map(\.value.ref)
        var blks: [LLVMBasicBlockRef?] = values.map(\.block.ref)
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

    public var destinationType: LLVMType {
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
