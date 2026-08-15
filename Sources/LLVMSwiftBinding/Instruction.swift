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
        let inst: Instruction = switch Opcode(llvm: LLVMGetInstructionOpcode(ref))! {
        case .Ret:
            ReturnInst(ref: ref, context: context, module: module)
        case .Br:
            BranchInst(ref: ref, context: context, module: module)
        case .Switch:
            SwitchInst(ref: ref, context: context, module: module)
        case .IndirectBr:
            IndirectBrInst(ref: ref, context: context, module: module)
        case .Invoke:
            InvokeInst(ref: ref, context: context, module: module)
        case .Unreachable:
            UnreachableInst(ref: ref, context: context, module: module)
        case .Alloca:
            AllocaInst(ref: ref, context: context, module: module)
        case .Load:
            LoadInst(ref: ref, context: context, module: module)
        case .Store:
            StoreInst(ref: ref, context: context, module: module)
        case .GetElementPtr:
            GetElementPtrInst(ref: ref, context: context, module: module)
        case .ICmp:
            ICmpInst(ref: ref, context: context, module: module)
        case .FCmp:
            FCmpInst(ref: ref, context: context, module: module)
        case .Call:
            CallInst(ref: ref, context: context, module: module)
        case .CallBr:
            CallBrInst(ref: ref, context: context, module: module)
        case .PHI:
            PHINode(ref: ref, context: context, module: module)
        case .Select:
            SelectInst(ref: ref, context: context, module: module)
        case .VAArg:
            VAArgInst(ref: ref, context: context, module: module)
        case .ExtractElement:
            ExtractElementInst(ref: ref, context: context, module: module)
        case .InsertElement:
            InsertElementInst(ref: ref, context: context, module: module)
        case .ShuffleVector:
            ShuffleVectorInst(ref: ref, context: context, module: module)
        case .ExtractValue:
            ExtractValueInst(ref: ref, context: context, module: module)
        case .InsertValue:
            InsertValueInst(ref: ref, context: context, module: module)
        case .Freeze:
            FreezeInst(ref: ref, context: context, module: module)
        case .Fence:
            FenceInst(ref: ref, context: context, module: module)
        case .AtomicCmpXchg:
            AtomicCmpXchgInst(ref: ref, context: context, module: module)
        case .AtomicRMW:
            AtomicRMWInst(ref: ref, context: context, module: module)
        case .Resume:
            ResumeInst(ref: ref, context: context, module: module)
        case .LandingPad:
            LandingPadInst(ref: ref, context: context, module: module)
        case .CleanupRet:
            CleanupRetInst(ref: ref, context: context, module: module)
        case .CatchRet:
            CatchRetInst(ref: ref, context: context, module: module)
        case .CatchPad:
            CatchPadInst(ref: ref, context: context, module: module)
        case .CleanupPad:
            CleanupPadInst(ref: ref, context: context, module: module)
        case .CatchSwitch:
            CatchSwitchInst(ref: ref, context: context, module: module)
        default:
            BinaryOperator(ref: ref, context: context, module: module)
        }
        return inst
    }

    public var isTerminator: Bool {
        LLVMIsATerminatorInst(ref) != nil
    }

    public var isAtomic: Bool {
        LLVMIsAtomic(ref) != 0
    }

    public var isAtomicSingleThread: Bool {
        get { LLVMIsAtomicSingleThread(ref) != 0 }
        set { LLVMSetAtomicSingleThread(ref, newValue ? 1 : 0) }
    }

    public var syncScopeID: UInt32 {
        get { LLVMGetAtomicSyncScopeID(ref) }
        set { LLVMSetAtomicSyncScopeID(ref, newValue) }
    }

    public var previousInstruction: Instruction? {
        guard let prev = LLVMGetPreviousInstruction(ref) else { return nil }
        return Instruction.wrap(prev, context: context, module: module)
    }

    public var nextInstruction: Instruction? {
        guard let next = LLVMGetNextInstruction(ref) else { return nil }
        return Instruction.wrap(next, context: context, module: module)
    }

    public var firstDbgRecord: DbgRecord? {
        guard let rec = LLVMGetFirstDbgRecord(ref) else { return nil }
        return DbgRecord(ref: rec, context: context, module: module)
    }

    public var lastDbgRecord: DbgRecord? {
        guard let rec = LLVMGetLastDbgRecord(ref) else { return nil }
        return DbgRecord(ref: rec, context: context, module: module)
    }

    public var dbgRecords: [DbgRecord] {
        var result: [DbgRecord] = []
        guard let first = LLVMGetFirstDbgRecord(ref) else { return [] }
        var current: LLVMDbgRecordRef? = first
        while let rec = current {
            result.append(DbgRecord(ref: rec, context: context, module: module))
            current = LLVMGetNextDbgRecord(rec)
        }
        return result
    }

    public var successorCount: UInt32 {
        LLVMGetNumSuccessors(ref)
    }

    public func successor(at index: UInt32) -> BasicBlock? {
        guard let block = LLVMGetSuccessor(ref, index) else { return nil }
        return basicBlock(from: block)
    }

    public func setSuccessor(at index: UInt32, _ block: BasicBlock) {
        LLVMSetSuccessor(ref, index, block.ref)
    }

    public var numArgOperands: UInt32 {
        LLVMGetNumArgOperands(ref)
    }

    public func argOperand(at index: UInt32) -> Value? {
        guard let operand = LLVMGetArgOperand(ref, index) else { return nil }
        return Value(ref: operand, context: context, module: module)
    }

    public func setArgOperand(at index: UInt32, _ value: Value) {
        LLVMSetArgOperand(ref, index, value.ref)
    }

    public var fastMathFlags: UInt32 {
        get { LLVMGetFastMathFlags(ref) }
        set { LLVMSetFastMathFlags(ref, newValue) }
    }

    public var canUseFastMathFlags: Bool {
        LLVMCanValueUseFastMathFlags(ref) != 0
    }

    public func setParamAlignment(at index: UInt32, _ alignment: UInt32) {
        LLVMSetInstrParamAlignment(ref, index, alignment)
    }

    public var opcode: Opcode {
        Opcode(llvm: LLVMGetInstructionOpcode(ref))!
    }

    public var opcodeName: String {
        switch opcode {
        case .Ret: "ret"
        case .Br: "br"
        case .Switch: "switch"
        case .IndirectBr: "indirectbr"
        case .Invoke: "invoke"
        case .Unreachable: "unreachable"
        case .CallBr: "callbr"
        case .FNeg: "fneg"
        case .Add: "add"
        case .FAdd: "fadd"
        case .Sub: "sub"
        case .FSub: "fsub"
        case .Mul: "mul"
        case .FMul: "fmul"
        case .UDiv: "udiv"
        case .SDiv: "sdiv"
        case .FDiv: "fdiv"
        case .URem: "urem"
        case .SRem: "srem"
        case .FRem: "frem"
        case .Shl: "shl"
        case .LShr: "lshr"
        case .AShr: "ashr"
        case .And: "and"
        case .Or: "or"
        case .Xor: "xor"
        case .Alloca: "alloca"
        case .Load: "load"
        case .Store: "store"
        case .GetElementPtr: "getelementptr"
        case .Trunc: "trunc"
        case .ZExt: "zext"
        case .SExt: "sext"
        case .FPToUI: "fptoui"
        case .FPToSI: "fptosi"
        case .UIToFP: "uitofp"
        case .SIToFP: "sitofp"
        case .FPTrunc: "fptrunc"
        case .FPExt: "fpext"
        case .PtrToInt: "ptrtoint"
        case .PtrToAddr: "ptrtoaddr"
        case .IntToPtr: "inttoptr"
        case .BitCast: "bitcast"
        case .AddrSpaceCast: "addrspacecast"
        case .ICmp: "icmp"
        case .FCmp: "fcmp"
        case .PHI: "phi"
        case .Call: "call"
        case .Select: "select"
        case .UserOp1: "userop1"
        case .UserOp2: "userop2"
        case .VAArg: "va_arg"
        case .ExtractElement: "extractelement"
        case .InsertElement: "insertelement"
        case .ShuffleVector: "shufflevector"
        case .ExtractValue: "extractvalue"
        case .InsertValue: "insertvalue"
        case .Freeze: "freeze"
        case .Fence: "fence"
        case .AtomicCmpXchg: "cmpxchg"
        case .AtomicRMW: "atomicrmw"
        case .Resume: "resume"
        case .LandingPad: "landingpad"
        case .CleanupRet: "cleanupret"
        case .CatchRet: "catchret"
        case .CatchPad: "catchpad"
        case .CleanupPad: "cleanuppad"
        case .CatchSwitch: "catchswitch"
        }
    }

    public var operandBundles: [OperandBundle] {
        let opcode = Opcode(llvm: LLVMGetInstructionOpcode(ref))!
        guard opcode == .Call || opcode == .Invoke || opcode == .CallBr else { return [] }
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

public final class BinaryOperator: Instruction {
    public var isNSW: Bool {
        get { LLVMGetNSW(ref) != 0 }
        set { LLVMSetNSW(ref, newValue ? 1 : 0) }
    }

    public var isNUW: Bool {
        get { LLVMGetNUW(ref) != 0 }
        set { LLVMSetNUW(ref, newValue ? 1 : 0) }
    }

    public var isExact: Bool {
        get { LLVMGetExact(ref) != 0 }
        set { LLVMSetExact(ref, newValue ? 1 : 0) }
    }

    public var isDisjoint: Bool {
        get { LLVMGetIsDisjoint(ref) != 0 }
        set { LLVMSetIsDisjoint(ref, newValue ? 1 : 0) }
    }

    public var isNNeg: Bool {
        get { LLVMGetNNeg(ref) != 0 }
        set { LLVMSetNNeg(ref, newValue ? 1 : 0) }
    }
}

public final class AllocaInst: Instruction {
    public var allocatedType: LLVMType {
        context.wrapType(LLVMGetAllocatedType(ref)!)
    }
}

public final class LoadInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }

    public var ordering: AtomicOrdering {
        get { AtomicOrdering(llvm: LLVMGetOrdering(ref))! }
        set { LLVMSetOrdering(ref, newValue.llvm) }
    }
}

public final class StoreInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }

    public var ordering: AtomicOrdering {
        get { AtomicOrdering(llvm: LLVMGetOrdering(ref))! }
        set { LLVMSetOrdering(ref, newValue.llvm) }
    }
}

public final class BranchInst: Instruction {
    public var isConditional: Bool {
        LLVMIsConditional(ref) != 0
    }

    public var condition: Value? {
        get {
            guard let cond = LLVMGetCondition(ref) else { return nil }
            return Value(ref: cond, context: context, module: module)
        }
        set {
            LLVMSetCondition(ref, newValue!.ref)
        }
    }
}

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
    public var predicate: IntPredicate {
        IntPredicate(llvm: LLVMGetICmpPredicate(ref))!
    }

    public var isSameSign: Bool {
        get { LLVMGetICmpSameSign(ref) != 0 }
        set { LLVMSetICmpSameSign(ref, newValue ? 1 : 0) }
    }
}

public final class FCmpInst: Instruction {
    public var predicate: RealPredicate {
        RealPredicate(llvm: LLVMGetFCmpPredicate(ref))!
    }
}

public final class CallInst: Instruction {
    public var isTailCall: Bool {
        get { LLVMIsTailCall(ref) != 0 }
        set { LLVMSetTailCall(ref, newValue ? 1 : 0) }
    }

    public var tailCallKind: TailCallKind {
        get { TailCallKind(llvm: LLVMGetTailCallKind(ref))! }
        set { LLVMSetTailCallKind(ref, newValue.llvm) }
    }

    public var callConvention: CallConv {
        get { CallConv(llvm: LLVMGetInstructionCallConv(ref)) }
        set { LLVMSetInstructionCallConv(ref, newValue.llvm) }
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

public final class CallBrInst: Instruction {
    public var defaultDest: BasicBlock? {
        guard let block = LLVMGetCallBrDefaultDest(ref) else { return nil }
        return basicBlock(from: block)
    }

    public var numIndirectDests: UInt32 {
        LLVMGetCallBrNumIndirectDests(ref)
    }

    public func indirectDest(at index: UInt32) -> BasicBlock? {
        guard let block = LLVMGetCallBrIndirectDest(ref, index) else { return nil }
        return basicBlock(from: block)
    }
}

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

public final class GetElementPtrInst: Instruction {
    public var sourceElementType: LLVMType {
        context.wrapType(LLVMGetGEPSourceElementType(ref)!)
    }

    public var noWrapFlags: GEPNoWrapFlags {
        get { GEPNoWrapFlags(rawValue: LLVMGEPGetNoWrapFlags(ref)) }
        set { LLVMGEPSetNoWrapFlags(ref, newValue.rawValue) }
    }
}

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

    public var ordering: AtomicOrdering {
        get { AtomicOrdering(llvm: LLVMGetOrdering(ref))! }
        set { LLVMSetOrdering(ref, newValue.llvm) }
    }

    public var binOp: AtomicRMWBinOp {
        get { AtomicRMWBinOp(llvm: LLVMGetAtomicRMWBinOp(ref))! }
        set { LLVMSetAtomicRMWBinOp(ref, newValue.llvm) }
    }
}

public final class AtomicCmpXchgInst: Instruction {
    public var isVolatile: Bool {
        get { LLVMGetVolatile(ref) != 0 }
        set { LLVMSetVolatile(ref, newValue ? 1 : 0) }
    }

    public var successOrdering: AtomicOrdering {
        get { AtomicOrdering(llvm: LLVMGetCmpXchgSuccessOrdering(ref))! }
        set { LLVMSetCmpXchgSuccessOrdering(ref, newValue.llvm) }
    }

    public var failureOrdering: AtomicOrdering {
        get { AtomicOrdering(llvm: LLVMGetCmpXchgFailureOrdering(ref))! }
        set { LLVMSetCmpXchgFailureOrdering(ref, newValue.llvm) }
    }

    public var isWeak: Bool {
        get { LLVMGetWeak(ref) != 0 }
        set { LLVMSetWeak(ref, newValue ? 1 : 0) }
    }
}

public final class ExtractValueInst: Instruction {}

public final class InsertValueInst: Instruction {}

public final class ExtractElementInst: Instruction {}

public final class InsertElementInst: Instruction {}

public final class ShuffleVectorInst: Instruction {
    public var numMaskElements: UInt32 {
        LLVMGetNumMaskElements(ref)
    }

    public func maskValue(at index: UInt32) -> Int32 {
        LLVMGetMaskValue(ref, index)
    }
}

public final class FreezeInst: Instruction {}

public final class VAArgInst: Instruction {}

public final class ResumeInst: Instruction {}

public final class InvokeInst: Instruction {
    public func addClause(_ clause: Value) {
        LLVMAddClause(ref, clause.ref)
    }

    public var normalDest: BasicBlock? {
        get {
            guard let block = LLVMGetNormalDest(ref) else { return nil }
            return basicBlock(from: block)
        }
        set {
            LLVMSetNormalDest(ref, newValue!.ref)
        }
    }

    public var unwindDest: BasicBlock? {
        get {
            guard let block = LLVMGetUnwindDest(ref) else { return nil }
            return basicBlock(from: block)
        }
        set {
            LLVMSetUnwindDest(ref, newValue!.ref)
        }
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
