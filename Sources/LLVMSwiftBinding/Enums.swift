import cLLVM

public enum Linkage: UInt32 {
    case External = 0
    case AvailableExternally = 1
    case LinkOnceAny = 2
    case LinkOnceODR = 3
    @available(*, deprecated)
    case LinkOnceODRAutoHide = 4
    case WeakAny = 5
    case WeakODR = 6
    case Appending = 7
    case Internal = 8
    case Private = 9
    @available(*, deprecated)
    case DLLImport = 10
    @available(*, deprecated)
    case DLLExport = 11
    @available(*, deprecated)
    case ExternalWeak = 12
    @available(*, deprecated)
    case Ghost = 13
    case Common = 14
    @available(*, deprecated)
    case LinkerPrivate = 15
    @available(*, deprecated)
    case LinkerPrivateWeak = 16

    var llvm: LLVMLinkage {
        switch self {
        case .External: LLVMExternalLinkage
        case .AvailableExternally: LLVMAvailableExternallyLinkage
        case .LinkOnceAny: LLVMLinkOnceAnyLinkage
        case .LinkOnceODR: LLVMLinkOnceODRLinkage
        case .LinkOnceODRAutoHide: LLVMLinkOnceODRAutoHideLinkage
        case .WeakAny: LLVMWeakAnyLinkage
        case .WeakODR: LLVMWeakODRLinkage
        case .Appending: LLVMAppendingLinkage
        case .Internal: LLVMInternalLinkage
        case .Private: LLVMPrivateLinkage
        case .DLLImport: LLVMDLLImportLinkage
        case .DLLExport: LLVMDLLExportLinkage
        case .ExternalWeak: LLVMExternalWeakLinkage
        case .Ghost: LLVMGhostLinkage
        case .Common: LLVMCommonLinkage
        case .LinkerPrivate: LLVMLinkerPrivateLinkage
        case .LinkerPrivateWeak: LLVMLinkerPrivateWeakLinkage
        }
    }

    init?(llvm: LLVMLinkage) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum Visibility: UInt32 {
    case Default = 0
    case Hidden = 1
    case Protected = 2

    var llvm: LLVMVisibility {
        switch self {
        case .Default: LLVMDefaultVisibility
        case .Hidden: LLVMHiddenVisibility
        case .Protected: LLVMProtectedVisibility
        }
    }

    init?(llvm: LLVMVisibility) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum UnnamedAddr: UInt32 {
    case None = 0
    case Local = 1
    case Global = 2

    var llvm: LLVMUnnamedAddr {
        switch self {
        case .None: LLVMNoUnnamedAddr
        case .Local: LLVMLocalUnnamedAddr
        case .Global: LLVMGlobalUnnamedAddr
        }
    }

    init?(llvm: LLVMUnnamedAddr) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum ThreadLocalMode: UInt32 {
    case NotThreadLocal = 0
    case GeneralDynamic = 1
    case LocalDynamic = 2
    case InitialExec = 3
    case LocalExec = 4

    var llvm: LLVMThreadLocalMode {
        switch self {
        case .NotThreadLocal: LLVMNotThreadLocal
        case .GeneralDynamic: LLVMGeneralDynamicTLSModel
        case .LocalDynamic: LLVMLocalDynamicTLSModel
        case .InitialExec: LLVMInitialExecTLSModel
        case .LocalExec: LLVMLocalExecTLSModel
        }
    }

    init?(llvm: LLVMThreadLocalMode) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum DLLStorageClass: UInt32 {
    case Default = 0
    case DLLImport = 1
    case DLLExport = 2

    var llvm: LLVMDLLStorageClass {
        switch self {
        case .Default: LLVMDefaultStorageClass
        case .DLLImport: LLVMDLLImportStorageClass
        case .DLLExport: LLVMDLLExportStorageClass
        }
    }

    init?(llvm: LLVMDLLStorageClass) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum CallConv {
    case C
    case Fast
    case Cold
    case GHC
    case HiPE
    case AnyReg
    case PreserveMost
    case PreserveAll
    case Swift
    case CXXFASTTLS
    case X86Stdcall
    case X86Fastcall
    case ARMAPCS
    case ARMAAPCS
    case ARMAAPCSVFP
    case MSP430INTR
    case X86ThisCall
    case PTXKernel
    case PTXDevice
    case SPIRFUNC
    case SPIRKERNEL
    case IntelOCLBI
    case X8664SysV
    case Win64
    case X86VectorCall
    case HHVM
    case HHVMC
    case X86INTR
    case AVRINTR
    case AVRSIGNAL
    case AVRBUILTIN
    case AMDGPUVS
    case AMDGPUGS
    case AMDGPUPS
    case AMDGPUC
    case AMDGPUKERNEL
    case X86RegCall
    case AMDGPUHS
    case MSP430BUILTIN
    case AMDGPULS
    case AMDGPUES
    case Custom(UInt32)

    var llvm: UInt32 {
        switch self {
        case .C: 0
        case .Fast: 8
        case .Cold: 9
        case .GHC: 10
        case .HiPE: 11
        case .AnyReg: 13
        case .PreserveMost: 14
        case .PreserveAll: 15
        case .Swift: 16
        case .CXXFASTTLS: 17
        case .X86Stdcall: 64
        case .X86Fastcall: 65
        case .ARMAPCS: 66
        case .ARMAAPCS: 67
        case .ARMAAPCSVFP: 68
        case .MSP430INTR: 69
        case .X86ThisCall: 70
        case .PTXKernel: 71
        case .PTXDevice: 72
        case .SPIRFUNC: 75
        case .SPIRKERNEL: 76
        case .IntelOCLBI: 77
        case .X8664SysV: 78
        case .Win64: 79
        case .X86VectorCall: 80
        case .HHVM: 81
        case .HHVMC: 82
        case .X86INTR: 83
        case .AVRINTR: 84
        case .AVRSIGNAL: 85
        case .AVRBUILTIN: 86
        case .AMDGPUVS: 87
        case .AMDGPUGS: 88
        case .AMDGPUPS: 89
        case .AMDGPUC: 90
        case .AMDGPUKERNEL: 91
        case .X86RegCall: 92
        case .AMDGPUHS: 93
        case .MSP430BUILTIN: 94
        case .AMDGPULS: 95
        case .AMDGPUES: 96
        case let .Custom(value): value
        }
    }

    init(llvm: UInt32) {
        switch llvm {
        case 0: self = .C
        case 8: self = .Fast
        case 9: self = .Cold
        case 10: self = .GHC
        case 11: self = .HiPE
        case 13: self = .AnyReg
        case 14: self = .PreserveMost
        case 15: self = .PreserveAll
        case 16: self = .Swift
        case 17: self = .CXXFASTTLS
        case 64: self = .X86Stdcall
        case 65: self = .X86Fastcall
        case 66: self = .ARMAPCS
        case 67: self = .ARMAAPCS
        case 68: self = .ARMAAPCSVFP
        case 69: self = .MSP430INTR
        case 70: self = .X86ThisCall
        case 71: self = .PTXKernel
        case 72: self = .PTXDevice
        case 75: self = .SPIRFUNC
        case 76: self = .SPIRKERNEL
        case 77: self = .IntelOCLBI
        case 78: self = .X8664SysV
        case 79: self = .Win64
        case 80: self = .X86VectorCall
        case 81: self = .HHVM
        case 82: self = .HHVMC
        case 83: self = .X86INTR
        case 84: self = .AVRINTR
        case 85: self = .AVRSIGNAL
        case 86: self = .AVRBUILTIN
        case 87: self = .AMDGPUVS
        case 88: self = .AMDGPUGS
        case 89: self = .AMDGPUPS
        case 90: self = .AMDGPUC
        case 91: self = .AMDGPUKERNEL
        case 92: self = .X86RegCall
        case 93: self = .AMDGPUHS
        case 94: self = .MSP430BUILTIN
        case 95: self = .AMDGPULS
        case 96: self = .AMDGPUES
        default: self = .Custom(llvm)
        }
    }
}

extension CallConv: Equatable {
    public static func == (lhs: CallConv, rhs: CallConv) -> Bool {
        lhs.llvm == rhs.llvm
    }
}

public enum InlineAsmDialect: UInt32 {
    case ATT = 0
    case Intel = 1

    var llvm: LLVMInlineAsmDialect {
        switch self {
        case .ATT: LLVMInlineAsmDialectATT
        case .Intel: LLVMInlineAsmDialectIntel
        }
    }

    init?(llvm: LLVMInlineAsmDialect) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum IntPredicate: UInt32 {
    case EQ = 32
    case NE = 33
    case UGT = 34
    case UGE = 35
    case ULT = 36
    case ULE = 37
    case SGT = 38
    case SGE = 39
    case SLT = 40
    case SLE = 41

    var llvm: LLVMIntPredicate {
        switch self {
        case .EQ: LLVMIntEQ
        case .NE: LLVMIntNE
        case .UGT: LLVMIntUGT
        case .UGE: LLVMIntUGE
        case .ULT: LLVMIntULT
        case .ULE: LLVMIntULE
        case .SGT: LLVMIntSGT
        case .SGE: LLVMIntSGE
        case .SLT: LLVMIntSLT
        case .SLE: LLVMIntSLE
        }
    }

    init?(llvm: LLVMIntPredicate) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum RealPredicate: UInt32 {
    case False = 0
    case OEQ = 1
    case OGT = 2
    case OGE = 3
    case OLT = 4
    case OLE = 5
    case ONE = 6
    case ORD = 7
    case UNO = 8
    case UEQ = 9
    case UGT = 10
    case UGE = 11
    case ULT = 12
    case ULE = 13
    case UNE = 14
    case True = 15

    var llvm: LLVMRealPredicate {
        switch self {
        case .False: LLVMRealPredicateFalse
        case .OEQ: LLVMRealOEQ
        case .OGT: LLVMRealOGT
        case .OGE: LLVMRealOGE
        case .OLT: LLVMRealOLT
        case .OLE: LLVMRealOLE
        case .ONE: LLVMRealONE
        case .ORD: LLVMRealORD
        case .UNO: LLVMRealUNO
        case .UEQ: LLVMRealUEQ
        case .UGT: LLVMRealUGT
        case .UGE: LLVMRealUGE
        case .ULT: LLVMRealULT
        case .ULE: LLVMRealULE
        case .UNE: LLVMRealUNE
        case .True: LLVMRealPredicateTrue
        }
    }

    init?(llvm: LLVMRealPredicate) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum TailCallKind: UInt32 {
    case None = 0
    case Tail = 1
    case MustTail = 2
    case NoTail = 3

    var llvm: LLVMTailCallKind {
        switch self {
        case .None: LLVMTailCallKindNone
        case .Tail: LLVMTailCallKindTail
        case .MustTail: LLVMTailCallKindMustTail
        case .NoTail: LLVMTailCallKindNoTail
        }
    }

    init?(llvm: LLVMTailCallKind) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum AtomicOrdering: UInt32 {
    case NotAtomic = 0
    case Unordered = 1
    case Monotonic = 2
    case Acquire = 4
    case Release = 5
    case AcquireRelease = 6
    case SequentiallyConsistent = 7

    var llvm: LLVMAtomicOrdering {
        switch self {
        case .NotAtomic: LLVMAtomicOrderingNotAtomic
        case .Unordered: LLVMAtomicOrderingUnordered
        case .Monotonic: LLVMAtomicOrderingMonotonic
        case .Acquire: LLVMAtomicOrderingAcquire
        case .Release: LLVMAtomicOrderingRelease
        case .AcquireRelease: LLVMAtomicOrderingAcquireRelease
        case .SequentiallyConsistent: LLVMAtomicOrderingSequentiallyConsistent
        }
    }

    init?(llvm: LLVMAtomicOrdering) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum AtomicRMWBinOp: UInt32 {
    case Xchg = 0
    case Add = 1
    case Sub = 2
    case And = 3
    case Nand = 4
    case Or = 5
    case Xor = 6
    case Max = 7
    case Min = 8
    case UMax = 9
    case UMin = 10
    case FAdd = 11
    case FSub = 12
    case FMax = 13
    case FMin = 14
    case UIncWrap = 15
    case UDecWrap = 16
    case USubCond = 17
    case USubSat = 18
    case FMaximum = 19
    case FMinimum = 20

    var llvm: LLVMAtomicRMWBinOp {
        switch self {
        case .Xchg: LLVMAtomicRMWBinOpXchg
        case .Add: LLVMAtomicRMWBinOpAdd
        case .Sub: LLVMAtomicRMWBinOpSub
        case .And: LLVMAtomicRMWBinOpAnd
        case .Nand: LLVMAtomicRMWBinOpNand
        case .Or: LLVMAtomicRMWBinOpOr
        case .Xor: LLVMAtomicRMWBinOpXor
        case .Max: LLVMAtomicRMWBinOpMax
        case .Min: LLVMAtomicRMWBinOpMin
        case .UMax: LLVMAtomicRMWBinOpUMax
        case .UMin: LLVMAtomicRMWBinOpUMin
        case .FAdd: LLVMAtomicRMWBinOpFAdd
        case .FSub: LLVMAtomicRMWBinOpFSub
        case .FMax: LLVMAtomicRMWBinOpFMax
        case .FMin: LLVMAtomicRMWBinOpFMin
        case .UIncWrap: LLVMAtomicRMWBinOpUIncWrap
        case .UDecWrap: LLVMAtomicRMWBinOpUDecWrap
        case .USubCond: LLVMAtomicRMWBinOpUSubCond
        case .USubSat: LLVMAtomicRMWBinOpUSubSat
        case .FMaximum: LLVMAtomicRMWBinOpFMaximum
        case .FMinimum: LLVMAtomicRMWBinOpFMinimum
        }
    }

    init?(llvm: LLVMAtomicRMWBinOp) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum ComdatSelectionKind: UInt32 {
    case `Any` = 0
    case ExactMatch = 1
    case Largest = 2
    case NoDeduplicate = 3
    case SameSize = 4

    var llvm: LLVMComdatSelectionKind {
        switch self {
        case .Any: LLVMAnyComdatSelectionKind
        case .ExactMatch: LLVMExactMatchComdatSelectionKind
        case .Largest: LLVMLargestComdatSelectionKind
        case .NoDeduplicate: LLVMNoDeduplicateComdatSelectionKind
        case .SameSize: LLVMSameSizeComdatSelectionKind
        }
    }

    init?(llvm: LLVMComdatSelectionKind) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum ModuleFlagBehavior: UInt32 {
    case Error = 0
    case Warning = 1
    case Require = 2
    case Override = 3
    case Append = 4
    case AppendUnique = 5

    var llvm: LLVMModuleFlagBehavior {
        switch self {
        case .Error: LLVMModuleFlagBehaviorError
        case .Warning: LLVMModuleFlagBehaviorWarning
        case .Require: LLVMModuleFlagBehaviorRequire
        case .Override: LLVMModuleFlagBehaviorOverride
        case .Append: LLVMModuleFlagBehaviorAppend
        case .AppendUnique: LLVMModuleFlagBehaviorAppendUnique
        }
    }

    init?(llvm: LLVMModuleFlagBehavior) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum ByteOrdering: UInt32 {
    case BigEndian = 0
    case LittleEndian = 1

    var llvm: LLVMByteOrdering {
        switch self {
        case .BigEndian: LLVMBigEndian
        case .LittleEndian: LLVMLittleEndian
        }
    }

    init?(llvm: LLVMByteOrdering) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum VerifierFailureAction: UInt32 {
    case AbortProcess = 0
    case PrintMessage = 1
    case ReturnStatus = 2

    var llvm: LLVMVerifierFailureAction {
        switch self {
        case .AbortProcess: LLVMAbortProcessAction
        case .PrintMessage: LLVMPrintMessageAction
        case .ReturnStatus: LLVMReturnStatusAction
        }
    }

    init?(llvm: LLVMVerifierFailureAction) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum TypeKind: UInt32 {
    case Void = 0
    case Half = 1
    case Float = 2
    case Double = 3
    case X86FP80 = 4
    case FP128 = 5
    case PPCFP128 = 6
    case Label = 7
    case Integer = 8
    case Function = 9
    case Struct = 10
    case Array = 11
    case Pointer = 12
    case Vector = 13
    case Metadata = 14
    case Token = 16
    case ScalableVector = 17
    case BFloat = 18
    case X86AMX = 19
    case TargetExt = 20

    var llvm: LLVMTypeKind {
        switch self {
        case .Void: LLVMVoidTypeKind
        case .Half: LLVMHalfTypeKind
        case .Float: LLVMFloatTypeKind
        case .Double: LLVMDoubleTypeKind
        case .X86FP80: LLVMX86_FP80TypeKind
        case .FP128: LLVMFP128TypeKind
        case .PPCFP128: LLVMPPC_FP128TypeKind
        case .Label: LLVMLabelTypeKind
        case .Integer: LLVMIntegerTypeKind
        case .Function: LLVMFunctionTypeKind
        case .Struct: LLVMStructTypeKind
        case .Array: LLVMArrayTypeKind
        case .Pointer: LLVMPointerTypeKind
        case .Vector: LLVMVectorTypeKind
        case .Metadata: LLVMMetadataTypeKind
        case .Token: LLVMTokenTypeKind
        case .ScalableVector: LLVMScalableVectorTypeKind
        case .BFloat: LLVMBFloatTypeKind
        case .X86AMX: LLVMX86_AMXTypeKind
        case .TargetExt: LLVMTargetExtTypeKind
        }
    }

    init?(llvm: LLVMTypeKind) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum ValueKind: UInt32 {
    case Argument = 0
    case BasicBlock = 1
    case MemoryUse = 2
    case MemoryDef = 3
    case MemoryPhi = 4
    case Function = 5
    case GlobalAlias = 6
    case GlobalIFunc = 7
    case GlobalVariable = 8
    case BlockAddress = 9
    case ConstantExpr = 10
    case ConstantArray = 11
    case ConstantStruct = 12
    case ConstantVector = 13
    case UndefValue = 14
    case ConstantAggregateZero = 15
    case ConstantDataArray = 16
    case ConstantDataVector = 17
    case ConstantInt = 18
    case ConstantFP = 19
    case ConstantPointerNull = 20
    case ConstantTokenNone = 21
    case MetadataAsValue = 22
    case InlineAsm = 23
    case Instruction = 24
    case PoisonValue = 25
    case ConstantTargetNone = 26
    case ConstantPtrAuth = 27

    var llvm: LLVMValueKind {
        switch self {
        case .Argument: LLVMArgumentValueKind
        case .BasicBlock: LLVMBasicBlockValueKind
        case .MemoryUse: LLVMMemoryUseValueKind
        case .MemoryDef: LLVMMemoryDefValueKind
        case .MemoryPhi: LLVMMemoryPhiValueKind
        case .Function: LLVMFunctionValueKind
        case .GlobalAlias: LLVMGlobalAliasValueKind
        case .GlobalIFunc: LLVMGlobalIFuncValueKind
        case .GlobalVariable: LLVMGlobalVariableValueKind
        case .BlockAddress: LLVMBlockAddressValueKind
        case .ConstantExpr: LLVMConstantExprValueKind
        case .ConstantArray: LLVMConstantArrayValueKind
        case .ConstantStruct: LLVMConstantStructValueKind
        case .ConstantVector: LLVMConstantVectorValueKind
        case .UndefValue: LLVMUndefValueValueKind
        case .ConstantAggregateZero: LLVMConstantAggregateZeroValueKind
        case .ConstantDataArray: LLVMConstantDataArrayValueKind
        case .ConstantDataVector: LLVMConstantDataVectorValueKind
        case .ConstantInt: LLVMConstantIntValueKind
        case .ConstantFP: LLVMConstantFPValueKind
        case .ConstantPointerNull: LLVMConstantPointerNullValueKind
        case .ConstantTokenNone: LLVMConstantTokenNoneValueKind
        case .MetadataAsValue: LLVMMetadataAsValueValueKind
        case .InlineAsm: LLVMInlineAsmValueKind
        case .Instruction: LLVMInstructionValueKind
        case .PoisonValue: LLVMPoisonValueValueKind
        case .ConstantTargetNone: LLVMConstantTargetNoneValueKind
        case .ConstantPtrAuth: LLVMConstantPtrAuthValueKind
        }
    }

    init?(llvm: LLVMValueKind) {
        self.init(rawValue: llvm.rawValue)
    }
}

public enum Opcode: UInt32 {
    case Ret = 1
    case Br = 2
    case Switch = 3
    case IndirectBr = 4
    case Invoke = 5
    case Unreachable = 7
    case CallBr = 67
    case FNeg = 66
    case Add = 8
    case FAdd = 9
    case Sub = 10
    case FSub = 11
    case Mul = 12
    case FMul = 13
    case UDiv = 14
    case SDiv = 15
    case FDiv = 16
    case URem = 17
    case SRem = 18
    case FRem = 19
    case Shl = 20
    case LShr = 21
    case AShr = 22
    case And = 23
    case Or = 24
    case Xor = 25
    case Alloca = 26
    case Load = 27
    case Store = 28
    case GetElementPtr = 29
    case Trunc = 30
    case ZExt = 31
    case SExt = 32
    case FPToUI = 33
    case FPToSI = 34
    case UIToFP = 35
    case SIToFP = 36
    case FPTrunc = 37
    case FPExt = 38
    case PtrToInt = 39
    case PtrToAddr = 69
    case IntToPtr = 40
    case BitCast = 41
    case AddrSpaceCast = 60
    case ICmp = 42
    case FCmp = 43
    case PHI = 44
    case Call = 45
    case Select = 46
    case UserOp1 = 47
    case UserOp2 = 48
    case VAArg = 49
    case ExtractElement = 50
    case InsertElement = 51
    case ShuffleVector = 52
    case ExtractValue = 53
    case InsertValue = 54
    case Freeze = 68
    case Fence = 55
    case AtomicCmpXchg = 56
    case AtomicRMW = 57
    case Resume = 58
    case LandingPad = 59
    case CleanupRet = 61
    case CatchRet = 62
    case CatchPad = 63
    case CleanupPad = 64
    case CatchSwitch = 65

    var llvm: LLVMOpcode {
        switch self {
        case .Ret: LLVMRet
        case .Br: LLVMBr
        case .Switch: LLVMSwitch
        case .IndirectBr: LLVMIndirectBr
        case .Invoke: LLVMInvoke
        case .Unreachable: LLVMUnreachable
        case .CallBr: LLVMCallBr
        case .FNeg: LLVMFNeg
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
        case .Alloca: LLVMAlloca
        case .Load: LLVMLoad
        case .Store: LLVMStore
        case .GetElementPtr: LLVMGetElementPtr
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
        case .PtrToAddr: LLVMPtrToAddr
        case .IntToPtr: LLVMIntToPtr
        case .BitCast: LLVMBitCast
        case .AddrSpaceCast: LLVMAddrSpaceCast
        case .ICmp: LLVMICmp
        case .FCmp: LLVMFCmp
        case .PHI: LLVMPHI
        case .Call: LLVMCall
        case .Select: LLVMSelect
        case .UserOp1: LLVMUserOp1
        case .UserOp2: LLVMUserOp2
        case .VAArg: LLVMVAArg
        case .ExtractElement: LLVMExtractElement
        case .InsertElement: LLVMInsertElement
        case .ShuffleVector: LLVMShuffleVector
        case .ExtractValue: LLVMExtractValue
        case .InsertValue: LLVMInsertValue
        case .Freeze: LLVMFreeze
        case .Fence: LLVMFence
        case .AtomicCmpXchg: LLVMAtomicCmpXchg
        case .AtomicRMW: LLVMAtomicRMW
        case .Resume: LLVMResume
        case .LandingPad: LLVMLandingPad
        case .CleanupRet: LLVMCleanupRet
        case .CatchRet: LLVMCatchRet
        case .CatchPad: LLVMCatchPad
        case .CleanupPad: LLVMCleanupPad
        case .CatchSwitch: LLVMCatchSwitch
        }
    }

    init?(llvm: LLVMOpcode) {
        self.init(rawValue: llvm.rawValue)
    }
}
