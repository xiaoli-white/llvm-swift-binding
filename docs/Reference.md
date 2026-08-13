# LLVMSwiftBinding API Reference

A type-safe Swift binding over the LLVM C API. The package has a two-layer
architecture: the **cLLVM** module wraps the raw LLVM C API (`llvm-c` headers),
and the **LLVMSwiftBinding** layer wraps it in Swift classes, structs, and
enums. `LLVMSwiftBinding.swift` re-exports the C layer with
`@_exported import cLLVM`, so all C types (`LLVMTypeRef`, `LLVMValueRef`,
`LLVMContextRef`, `LLVMAtomicOrdering`, `LLVMLinkage`, `LLVMAttributeIndex`, …)
are visible through a single `import LLVMSwiftBinding`. Such types are noted
below as *cLLVM re-exported types*.

The reference is organized by source file. Each file gets a `##` section, and
each `public` type a `###` subsection listing all of its public members —
properties, methods, static factories, and initializers — plus file-level
`public` extensions and enums.

## Analysis.swift

### VerifierFailureAction

```swift
public enum VerifierFailureAction {
    public static let abortProcess = LLVMAbortProcessAction
    public static let printMessage = LLVMPrintMessageAction
    public static let returnStatus = LLVMReturnStatusAction
}
```

Selects how the verifier reports a failure. The cases alias the cLLVM
re-exported `LLVMVerifierFailureAction` constants `LLVMAbortProcessAction`,
`LLVMPrintMessageAction`, and `LLVMReturnStatusAction`.

### Module Extension — verify

```swift
public func verify(action: LLVMVerifierFailureAction = LLVMReturnStatusAction) throws
```

Verifies the module. `action` is a cLLVM re-exported
`LLVMVerifierFailureAction`; on failure throws `LLVMError.parseFailed`.

### Function Extension — verify

```swift
public func verify(action: LLVMVerifierFailureAction = LLVMReturnStatusAction) -> Bool
```

Verifies the function and returns `true` if it is valid.

## Attribute.swift

### Attribute

```swift
public final class Attribute
```

A wrapper around an LLVM attribute. Attributes are attached to values at an
`LLVMAttributeIndex` (see `AttributeIndex`) and come in enum, string, and type
variants.

```swift
public let ref: LLVMAttributeRef
```
The underlying cLLVM re-exported `LLVMAttributeRef` handle.

```swift
public let context: Context
```
The context this attribute belongs to.

```swift
public init(ref: LLVMAttributeRef, context: Context)
```
Wraps an existing attribute handle.

```swift
public var isEnum: Bool
```
Whether this is an enum attribute.

```swift
public var isString: Bool
```
Whether this is a string attribute.

```swift
public var isType: Bool
```
Whether this is a type attribute.

```swift
public var enumKind: UInt32
```
The enum-kind of an enum attribute.

```swift
public var enumValue: UInt64
```
The integer value of an enum attribute.

```swift
public var stringKind: String?
```
The kind string of a string attribute, or `nil` if it is not a string attribute.

```swift
public var stringValue: String?
```
The value string of a string attribute, or `nil` if it is not a string attribute.

```swift
public var typeValue: LLVMType?
```
The type value of a type attribute, or `nil` if it is not a type attribute.

```swift
public static func enumAttribute(_ kind: UInt32, value: UInt64 = 0, in context: Context) -> Attribute
```
Creates an enum attribute with the given kind and optional value.

```swift
public static func stringAttribute(_ kind: String, value: String = "", in context: Context) -> Attribute
```
Creates a string attribute with the given kind and value.

```swift
public static func typeAttribute(_ kind: UInt32, type: LLVMType, in context: Context) -> Attribute
```
Creates a type attribute with the given kind and type.

### AttributeIndex

```swift
public enum AttributeIndex {
    public static let returnIndex: LLVMAttributeIndex = UInt32(LLVMAttributeReturnIndex)
    public static let functionIndex: LLVMAttributeIndex = UInt32(bitPattern: Int32(LLVMAttributeFunctionIndex))
}
```

Named indices used when attaching attributes. `LLVMAttributeIndex` is a cLLVM
re-exported type.

```swift
public static func parameter(_ index: UInt32) -> LLVMAttributeIndex
```
Returns the attribute index for the parameter at `index`.

### Value Extension — attributes

```swift
public func addAttribute(_ attribute: Attribute, at index: LLVMAttributeIndex)
```
Attaches an attribute to this value at the given index.

```swift
public func removeEnumAttribute(kind: UInt32, at index: LLVMAttributeIndex)
```
Removes an enum attribute by kind at the given index.

```swift
public func removeStringAttribute(kind: String, at index: LLVMAttributeIndex)
```
Removes a string attribute by kind at the given index.

```swift
public func attributes(at index: LLVMAttributeIndex) -> [Attribute]
```
Returns all attributes attached at the given index.

### CallInst Extension — call-site attributes

```swift
public func addCallSiteAttribute(_ attribute: Attribute, at index: LLVMAttributeIndex)
```
Attaches a call-site attribute at the given index.

```swift
public func removeCallSiteEnumAttribute(kind: UInt32, at index: LLVMAttributeIndex)
```
Removes a call-site enum attribute by kind at the given index.

```swift
public func callSiteAttributes(at index: LLVMAttributeIndex) -> [Attribute]
```
Returns all call-site attributes attached at the given index.

## BasicBlock.swift

### BasicBlock

```swift
public final class BasicBlock
```

A basic block inside a `Function`.

```swift
public let ref: LLVMBasicBlockRef
```
The underlying cLLVM re-exported `LLVMBasicBlockRef` handle.

```swift
public let function: Function
```
The function that owns this block.

```swift
public let module: Module
```
The module the owning function lives in.

```swift
public init(ref: LLVMBasicBlockRef, function: Function, module: Module)
```
Wraps an existing basic block handle.

```swift
public var context: Context
```
The context of the containing module.

```swift
public var name: String { get set }
```
The name of the basic block; settable.

```swift
public var terminator: Instruction?
```
The terminator instruction of the block, or `nil`.

```swift
public func insertBasicBlock(_ name: String) -> BasicBlock
```
Inserts a new basic block after this one in the function's block list.

```swift
public func moveBasicBlock(before other: BasicBlock)
```
Moves this block before `other` in the function's block list.

```swift
public var firstInstruction: Instruction?
```
The first instruction of the block, or `nil`.

```swift
public var lastInstruction: Instruction?
```
The last instruction of the block, or `nil`.

```swift
public var instructions: [Instruction]
```
All instructions in the block, in order.

## Builder.swift

### Builder

```swift
public final class Builder
```

Appends instructions to a basic block. Position the builder with
`positionAtEnd(of:)` or `positionBefore(_:)`, then call the `build*` methods.

```swift
public let ref: LLVMBuilderRef
```
The underlying cLLVM re-exported `LLVMBuilderRef` handle.

```swift
public let context: Context
```
The context the builder operates in.

```swift
public init(in context: Context)
```
Creates a builder in the given context.

```swift
public func positionAtEnd(of block: BasicBlock)
```
Positions the builder at the end of `block`.

```swift
public func positionBefore(_ inst: Instruction)
```
Positions the builder before `inst`.

```swift
public func setCurrentDebugLocation(_ location: Metadata?)
```
Sets the current debug location; `nil` clears it.

```swift
public var currentDebugLocation: Metadata?
```
The current debug location, or `nil`.

```swift
public func setInstDebugLocation(_ inst: Instruction)
```
Copies the debug location of `inst` onto the next built instruction.

```swift
@discardableResult
public func buildRet(_ value: Value) -> ReturnInst
```
Builds a `ret` instruction returning `value`.

```swift
@discardableResult
public func buildRetVoid() -> ReturnInst
```
Builds a `ret void` instruction.

```swift
@discardableResult
public func buildAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an integer `add` instruction.

```swift
@discardableResult
public func buildSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an integer `sub` instruction.

```swift
@discardableResult
public func buildMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an integer `mul` instruction.

```swift
@discardableResult
public func buildUDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an unsigned `udiv` instruction.

```swift
@discardableResult
public func buildSDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a signed `sdiv` instruction.

```swift
@discardableResult
public func buildNSWAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an `add` instruction with no-signed-wrap flags.

```swift
@discardableResult
public func buildNUWAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an `add` instruction with no-unsigned-wrap flags.

```swift
@discardableResult
public func buildNSWSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a `sub` instruction with no-signed-wrap flags.

```swift
@discardableResult
public func buildNUWSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a `sub` instruction with no-unsigned-wrap flags.

```swift
@discardableResult
public func buildNSWMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a `mul` instruction with no-signed-wrap flags.

```swift
@discardableResult
public func buildNUWMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a `mul` instruction with no-unsigned-wrap flags.

```swift
@discardableResult
public func buildExactUDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an exact unsigned `udiv` instruction.

```swift
@discardableResult
public func buildExactSDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an exact signed `sdiv` instruction.

```swift
@discardableResult
public func buildNSWNeg(_ value: Value, name: String = "") -> BinaryOperator
```
Builds a no-signed-wrap `neg` instruction.

```swift
@discardableResult
public func buildFNeg(_ value: Value, name: String = "") -> BinaryOperator
```
Builds a floating-point `fneg` instruction.

```swift
@discardableResult
public func buildURem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an unsigned `urem` instruction.

```swift
@discardableResult
public func buildSRem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a signed `srem` instruction.

```swift
@discardableResult
public func buildFAdd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a floating-point `fadd` instruction.

```swift
@discardableResult
public func buildFSub(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a floating-point `fsub` instruction.

```swift
@discardableResult
public func buildFMul(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a floating-point `fmul` instruction.

```swift
@discardableResult
public func buildFDiv(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a floating-point `fdiv` instruction.

```swift
@discardableResult
public func buildFRem(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a floating-point `frem` instruction.

```swift
@discardableResult
public func buildShl(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a `shl` instruction.

```swift
@discardableResult
public func buildLShr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a logical shift-right `lshr` instruction.

```swift
@discardableResult
public func buildAShr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds an arithmetic shift-right `ashr` instruction.

```swift
@discardableResult
public func buildAnd(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a bitwise `and` instruction.

```swift
@discardableResult
public func buildOr(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a bitwise `or` instruction.

```swift
@discardableResult
public func buildXor(_ lhs: Value, _ rhs: Value, name: String = "") -> BinaryOperator
```
Builds a bitwise `xor` instruction.

```swift
@discardableResult
public func buildAlloca(_ type: LLVMType, name: String = "") -> AllocaInst
```
Builds an `alloca` instruction for `type`.

```swift
@discardableResult
public func buildLoad(_ type: LLVMType, _ ptr: Value, name: String = "") -> LoadInst
```
Builds a `load` instruction of `type` from `ptr`.

```swift
@discardableResult
public func buildStore(_ value: Value, to ptr: Value) -> StoreInst
```
Builds a `store` instruction storing `value` to `ptr`.

```swift
@discardableResult
public func buildBr(_ dest: BasicBlock) -> BranchInst
```
Builds an unconditional `br` instruction to `dest`.

```swift
@discardableResult
public func buildCondBr(_ cond: Value, then: BasicBlock, else elseBlock: BasicBlock) -> BranchInst
```
Builds a conditional `br` instruction on `cond`.

```swift
@discardableResult
public func buildICmp(_ predicate: LLVMIntPredicate, _ lhs: Value, _ rhs: Value, name: String = "") -> ICmpInst
```
Builds an `icmp` instruction. `predicate` is a cLLVM re-exported `LLVMIntPredicate`.

```swift
@discardableResult
public func buildFCmp(_ predicate: LLVMRealPredicate, _ lhs: Value, _ rhs: Value, name: String = "") -> FCmpInst
```
Builds an `fcmp` instruction. `predicate` is a cLLVM re-exported `LLVMRealPredicate`.

```swift
@discardableResult
public func buildCall(_ function: Function, _ args: [Value], name: String = "") -> CallInst
```
Builds a `call` instruction invoking `function` with `args`.

```swift
@discardableResult
public func buildPhi(_ type: LLVMType, name: String = "") -> PHINode
```
Builds a `phi` node of `type`.

```swift
@discardableResult
public func buildSelect(_ cond: Value, then: Value, else: Value, name: String = "") -> SelectInst
```
Builds a `select` instruction choosing between `then` and `` `else` ``.

```swift
@discardableResult
public func buildGEP(_ elementType: LLVMType, _ ptr: Value, indices: [Value], name: String = "") -> GetElementPtrInst
```
Builds a `getelementptr` instruction into `ptr` with the given `indices`.

```swift
@discardableResult
public func buildTrunc(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `trunc` cast.

```swift
@discardableResult
public func buildZExt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a zero-extension `zext` cast.

```swift
@discardableResult
public func buildSExt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a sign-extension `sext` cast.

```swift
@discardableResult
public func buildBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `bitcast` cast.

```swift
@discardableResult
public func buildPtrToInt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `ptrtoint` cast.

```swift
@discardableResult
public func buildIntToPtr(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds an `inttoptr` cast.

```swift
@discardableResult
public func buildFPToUI(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `fptoui` cast.

```swift
@discardableResult
public func buildFPToSI(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `fptosi` cast.

```swift
@discardableResult
public func buildUIToFP(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `uitofp` cast.

```swift
@discardableResult
public func buildSIToFP(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `sitofp` cast.

```swift
@discardableResult
public func buildFPTrunc(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `fptrunc` cast.

```swift
@discardableResult
public func buildFPExt(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds an `fpext` cast.

```swift
@discardableResult
public func buildAddrSpaceCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds an `addrspacecast` cast.

```swift
@discardableResult
public func buildZExtOrBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `zext` or `bitcast`, whichever is valid.

```swift
@discardableResult
public func buildSExtOrBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `sext` or `bitcast`, whichever is valid.

```swift
@discardableResult
public func buildTruncOrBitCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a `trunc` or `bitcast`, whichever is valid.

```swift
@discardableResult
public func buildPointerCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a pointer cast (`ptrtoint`, `inttoptr`, or `bitcast`).

```swift
@discardableResult
public func buildIntCast(_ value: Value, to type: LLVMType, isSigned: Bool, name: String = "") -> CastInst
```
Builds an integer cast with the given signedness.

```swift
@discardableResult
public func buildFPCast(_ value: Value, to type: LLVMType, name: String = "") -> CastInst
```
Builds a floating-point cast.

```swift
@discardableResult
public func buildSwitch(_ value: Value, default dest: BasicBlock, numCases: UInt32 = 0) -> SwitchInst
```
Builds a `switch` instruction on `value` with a default destination.

```swift
@discardableResult
public func buildUnreachable() -> UnreachableInst
```
Builds an `unreachable` instruction.

```swift
@discardableResult
public func buildFence(ordering: LLVMAtomicOrdering, singleThread: Bool = false, name: String = "") -> FenceInst
```
Builds a `fence` instruction. `ordering` is a cLLVM re-exported `LLVMAtomicOrdering`.

```swift
@discardableResult
public func buildFenceSyncScope(ordering: LLVMAtomicOrdering, scope: UInt32, name: String = "") -> FenceInst
```
Builds a `fence` instruction with an explicit sync scope.

```swift
@discardableResult
public func buildAtomicRMW(_ op: LLVMAtomicRMWBinOp, _ ptr: Value, _ value: Value, ordering: LLVMAtomicOrdering, singleThread: Bool = false) -> AtomicRMWInst
```
Builds an atomic read-modify-write instruction. The op and ordering are cLLVM re-exported types.

```swift
@discardableResult
public func buildAtomicRMWSyncScope(_ op: LLVMAtomicRMWBinOp, _ ptr: Value, _ value: Value, ordering: LLVMAtomicOrdering, scope: UInt32) -> AtomicRMWInst
```
Builds an atomic read-modify-write instruction with an explicit sync scope.

```swift
@discardableResult
public func buildAtomicCmpXchg(_ ptr: Value, _ cmp: Value, _ new: Value, successOrdering: LLVMAtomicOrdering, failureOrdering: LLVMAtomicOrdering, singleThread: Bool = false) -> AtomicCmpXchgInst
```
Builds an atomic compare-and-exchange instruction.

```swift
@discardableResult
public func buildExtractValue(_ aggregate: Value, index: UInt32, name: String = "") -> ExtractValueInst
```
Builds an `extractvalue` instruction.

```swift
@discardableResult
public func buildInsertValue(_ aggregate: Value, _ element: Value, index: UInt32, name: String = "") -> InsertValueInst
```
Builds an `insertvalue` instruction.

```swift
@discardableResult
public func buildExtractElement(_ vector: Value, _ index: Value, name: String = "") -> ExtractElementInst
```
Builds an `extractelement` instruction.

```swift
@discardableResult
public func buildInsertElement(_ vector: Value, _ element: Value, _ index: Value, name: String = "") -> InsertElementInst
```
Builds an `insertelement` instruction.

```swift
@discardableResult
public func buildShuffleVector(_ v1: Value, _ v2: Value, mask: Value, name: String = "") -> ShuffleVectorInst
```
Builds a `shufflevector` instruction.

```swift
@discardableResult
public func buildFreeze(_ value: Value, name: String = "") -> FreezeInst
```
Builds a `freeze` instruction.

```swift
@discardableResult
public func buildVAArg(_ list: Value, type: LLVMType, name: String = "") -> VAArgInst
```
Builds a `va_arg` instruction.

```swift
@discardableResult
public func buildResume(_ exn: Value) -> ResumeInst
```
Builds a `resume` instruction.

```swift
@discardableResult
public func buildLandingPad(_ type: LLVMType, personality: Value? = nil, numClauses: UInt32 = 0, name: String = "") -> LandingPadInst
```
Builds a `landingpad` instruction.

```swift
@discardableResult
public func buildInvoke(_ function: Function, _ args: [Value], then: BasicBlock, catch: BasicBlock, name: String = "") -> InvokeInst
```
Builds an `invoke` instruction that lands in `` `catch` `` on unwind.

```swift
@discardableResult
public func buildIndirectBr(_ addr: Value, numDests: UInt32 = 0) -> IndirectBrInst
```
Builds an `indirectbr` instruction.

```swift
@discardableResult
public func buildMemSet(_ ptr: Value, _ value: Value, _ len: Value, alignment: UInt32 = 0) -> CallInst
```
Builds an `llvm.memset` intrinsic call.

```swift
@discardableResult
public func buildMemCpy(_ dest: Value, destAlign: UInt32 = 0, _ source: Value, sourceAlign: UInt32 = 0, _ len: Value) -> CallInst
```
Builds an `llvm.memcpy` intrinsic call.

```swift
@discardableResult
public func buildMemMove(_ dest: Value, destAlign: UInt32 = 0, _ source: Value, sourceAlign: UInt32 = 0, _ len: Value) -> CallInst
```
Builds an `llvm.memmove` intrinsic call.

```swift
@discardableResult
public func buildCallBr(_ callee: Value, args: [Value], default dest: BasicBlock, indirectDests: [BasicBlock], bundles: [OperandBundle] = [], name: String = "") -> CallBrInst
```
Builds a `callbr` instruction with indirect destinations and operand bundles.

```swift
@discardableResult
public func buildCleanupRet(_ cleanupPad: CleanupPadInst, to block: BasicBlock?) -> CleanupRetInst
```
Builds a `cleanupret` instruction.

```swift
@discardableResult
public func buildCatchRet(_ catchPad: CatchPadInst, to block: BasicBlock) -> CatchRetInst
```
Builds a `catchret` instruction.

```swift
@discardableResult
public func buildCatchPad(parentPad: Value?, args: [Value] = [], name: String = "") -> CatchPadInst
```
Builds a `catchpad` instruction.

```swift
@discardableResult
public func buildCleanupPad(parentPad: Value?, args: [Value] = [], name: String = "") -> CleanupPadInst
```
Builds a `cleanuppad` instruction.

```swift
@discardableResult
public func buildCatchSwitch(parentPad: Value?, unwind: BasicBlock?, numHandlers: UInt32 = 0, name: String = "") -> CatchSwitchInst
```
Builds a `catchswitch` instruction.

## Comdat.swift

### Comdat

```swift
public final class Comdat
```

A COMDAT group that can be attached to global values.

```swift
public let ref: LLVMComdatRef
```
The underlying cLLVM re-exported `LLVMComdatRef` handle.

```swift
public init(ref: LLVMComdatRef)
```
Wraps an existing comdat handle.

```swift
public var selectionKind: LLVMComdatSelectionKind { get set }
```
The selection kind of the comdat (cLLVM re-exported `LLVMComdatSelectionKind`).

### Module Extension — comdat

```swift
public func getOrInsertComdat(_ name: String) -> Comdat
```
Returns the comdat with `name`, creating it if needed.

### Value Extension — comdat

```swift
public var comdat: Comdat? { get set }
```
The comdat group this value belongs to, or `nil`; settable.

## Constant.swift

### Constant

```swift
public class Constant: Value
```
A constant value; the base class of all constant subclasses.

```swift
public init(ref: LLVMValueRef, context: Context)
```
Wraps an existing constant value handle.

```swift
public func aggregateElement(at index: UInt32) -> Constant?
```
Returns the element at `index` of an aggregate constant, or `nil`.

### ConstantInt

```swift
public final class ConstantInt: Constant
```
An integer constant.

```swift
public var unsignedValue: UInt64
```
The value interpreted as unsigned.

```swift
public var signedValue: Int64
```
The value interpreted as signed.

### ConstantFP

```swift
public final class ConstantFP: Constant
```
A floating-point constant.

```swift
public var doubleValue: Double
```
The value as a `Double`.

```swift
public var doubleValueWithStatus: (value: Double, isFinite: Bool)
```
The value as a `Double` plus whether the conversion was exact (finite).

### UndefValue

```swift
public final class UndefValue: Constant
```
An `undef` constant.

### PoisonValue

```swift
public final class PoisonValue: Constant
```
A `poison` constant.

### ConstantTokenNone

```swift
public final class ConstantTokenNone: Constant
```
A `token` `none` constant.

### ConstantAggregateZero

```swift
public final class ConstantAggregateZero: Constant
```
A zero-initialized aggregate constant.

### ConstantArray

```swift
public final class ConstantArray: Constant
```
An array constant.

### ConstantStruct

```swift
public final class ConstantStruct: Constant
```
A struct constant.

### ConstantDataArray

```swift
public final class ConstantDataArray: Constant
```
A data array constant.

```swift
public var isConstantString: Bool
```
Whether this data array is a constant string.

```swift
public var stringValue: String?
```
The string value, or `nil` if not a constant string.

```swift
public var rawData: [UInt8]
```
The raw bytes of the data array.

### ConstantExpr

```swift
public final class ConstantExpr: Constant
```
A constant expression.

```swift
public var opcode: LLVMOpcode
```
The opcode of the expression (cLLVM re-exported `LLVMOpcode`).

### ConstantVector

```swift
public final class ConstantVector: Constant
```
A vector constant.

### BlockAddress

```swift
public final class BlockAddress: Constant
```
The address of a basic block, taken as a constant.

```swift
public var function: Function?
```
The function containing the addressed block, or `nil`.

```swift
public var basicBlock: BasicBlock?
```
The addressed basic block, or `nil`.

## Context.swift

### Context

```swift
public final class Context
```

Owns LLVM types, constants, and diagnostic state, and caches the Swift wrapper
for each. All types and constants are created through a context.

```swift
public let ref: LLVMContextRef
```
The underlying cLLVM re-exported `LLVMContextRef` handle.

```swift
public init()
```
Creates a new context.

```swift
public var int1: IntegerType
```
The `i1` type.

```swift
public var int8: IntegerType
```
The `i8` type.

```swift
public var int16: IntegerType
```
The `i16` type.

```swift
public var int32: IntegerType
```
The `i32` type.

```swift
public var int64: IntegerType
```
The `i64` type.

```swift
public var int128: IntegerType
```
The `i128` type.

```swift
public func intType(width: UInt32) -> IntegerType
```
Creates an integer type of the given width.

```swift
public var void: VoidType
```
The `void` type.

```swift
public var float: FloatType
```
The `float` type.

```swift
public var double: FloatType
```
The `double` type.

```swift
public func functionType(returnType: LLVMType, parameterTypes: [LLVMType] = [], isVariadic: Bool = false) -> FunctionType
```
Creates a function type.

```swift
public func constantInt(_ value: UInt64, type: IntegerType) -> ConstantInt
```
Creates an unsigned integer constant.

```swift
public func constantInt(signed value: Int64, type: IntegerType) -> ConstantInt
```
Creates a signed integer constant.

```swift
public func constantFP(_ value: Double, type: FloatType) -> ConstantFP
```
Creates a floating-point constant.

```swift
public func pointerType(addressSpace: UInt32 = 0) -> PointerType
```
Creates a pointer type in the given address space.

```swift
public func constantNull(_ type: LLVMType) -> Constant
```
Creates a null constant of `type`.

```swift
public func undef(_ type: LLVMType) -> UndefValue
```
Creates an `undef` constant of `type`.

```swift
public func poison(_ type: LLVMType) -> PoisonValue
```
Creates a `poison` constant of `type`.

```swift
public func constantFP(ofString str: String, type: FloatType) -> ConstantFP
```
Parses a string into a floating-point constant.

```swift
public func constantString(_ str: String, dontNullTerminate: Bool = false) -> Constant
```
Creates a string constant; by default null-terminated.

```swift
public func constantReal(ofString str: String, type: FloatType) -> ConstantFP
```
Parses a string into a floating-point constant.

```swift
public func constantNeg(_ value: Constant) -> Constant
```
Creates a negated constant.

```swift
public func constantNSWNeg(_ value: Constant) -> Constant
```
Creates a no-signed-wrap negated constant.

```swift
public func constantAdd(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a constant `add` expression.

```swift
public func constantNSWAdd(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a no-signed-wrap constant `add` expression.

```swift
public func constantNUWAdd(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a no-unsigned-wrap constant `add` expression.

```swift
public func constantSub(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a constant `sub` expression.

```swift
public func constantNSWSub(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a no-signed-wrap constant `sub` expression.

```swift
public func constantNUWSub(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a no-unsigned-wrap constant `sub` expression.

```swift
public func constantTrunc(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant `trunc` expression.

```swift
public func constantPtrToInt(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant `ptrtoint` expression.

```swift
public func constantIntToPtr(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant `inttoptr` expression.

```swift
public func constantBitCast(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant `bitcast` expression.

```swift
public func constantArray(_ values: [Constant], elementType: LLVMType) -> ConstantArray
```
Creates an array constant.

```swift
public func constantDataArray(bytes: [UInt8], type: LLVMType) -> ConstantDataArray
```
Creates a data array constant from raw bytes.

```swift
public func constantVector(_ values: [Constant]) -> ConstantVector
```
Creates a vector constant.

```swift
public func constantInt(ofString str: String, type: IntegerType, radix: UInt8 = 0) -> ConstantInt
```
Parses a string into an integer constant, honoring `0x`/`0b`/`0o` prefixes when `radix` is `0`.

```swift
public func constantAllOnes(_ type: LLVMType) -> Constant
```
Creates an all-ones constant of `type`.

```swift
public func constantPointerNull(_ type: LLVMType) -> Constant
```
Creates a null pointer constant of `type`.

```swift
public func constantNot(_ value: Constant) -> Constant
```
Creates a bitwise `not` constant expression.

```swift
public func constantXor(_ lhs: Constant, _ rhs: Constant) -> Constant
```
Creates a constant `xor` expression.

```swift
public func constantGEP(_ elementType: LLVMType, _ value: Constant, indices: [Constant]) -> Constant
```
Creates a constant `getelementptr` expression.

```swift
public func constantTruncOrBitCast(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant `trunc` or `bitcast` expression.

```swift
public func constantPointerCast(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant pointer cast expression.

```swift
public func constantAddrSpaceCast(_ value: Constant, to type: LLVMType) -> Constant
```
Creates a constant `addrspacecast` expression.

```swift
public func constantExtractElement(_ vector: Constant, _ index: Constant) -> Constant
```
Creates a constant `extractelement` expression.

```swift
public func constantInsertElement(_ vector: Constant, _ element: Constant, _ index: Constant) -> Constant
```
Creates a constant `insertelement` expression.

```swift
public func constantShuffleVector(_ v1: Constant, _ v2: Constant, mask: Constant) -> Constant
```
Creates a constant `shufflevector` expression.

```swift
public func constantInlineAsm(_ type: LLVMType, asmString: String, constraints: String, hasSideEffects: Bool, isAlignStack: Bool, dialect: LLVMInlineAsmDialect = LLVMInlineAsmDialectATT, canThrow: Bool = false) -> Value
```
Creates an inline-asm value. `dialect` is a cLLVM re-exported `LLVMInlineAsmDialect`.

```swift
public func blockAddress(function: Function, block: BasicBlock) -> BlockAddress
```
Creates a `blockaddress` constant.

```swift
public func constantStruct(_ values: [Constant], isPacked: Bool = false) -> ConstantStruct
```
Creates a struct constant.

```swift
public func structType(elementTypes: [LLVMType], isPacked: Bool = false) -> StructType
```
Creates a literal struct type.

```swift
public func namedStructType(name: String, elementTypes: [LLVMType]? = nil, isPacked: Bool = false) -> StructType
```
Creates (and optionally bodies) a named struct type.

```swift
public func arrayType(elementType: LLVMType, count: UInt32) -> ArrayType
```
Creates an array type.

```swift
public func vectorType(elementType: LLVMType, count: UInt32) -> VectorType
```
Creates a fixed-length vector type.

```swift
public func scalableVectorType(elementType: LLVMType, count: UInt32) -> VectorType
```
Creates a scalable vector type.

```swift
public func targetExtType(name: String, typeParams: [LLVMType] = [], intParams: [UInt32] = []) -> TargetExtType
```
Creates a target extension type.

```swift
public func mdNode(_ elements: [Metadata]) -> Metadata
```
Creates a temporary metadata node from the given elements.

```swift
public func mdString(_ str: String) -> Metadata
```
Creates a metadata string node.

```swift
public func metadataAsValue(_ metadata: Metadata) -> Value
```
Lifts a metadata node to a value.

```swift
public func wrapType(_ ref: LLVMTypeRef) -> LLVMType
```
Wraps (and caches) a cLLVM `LLVMTypeRef` as the appropriate `LLVMType` subclass.

```swift
public func wrapConstant(_ ref: LLVMValueRef) -> Constant
```
Wraps (and caches) a cLLVM `LLVMValueRef` as the appropriate `Constant` subclass.

## DataLayout.swift

### DataLayout

```swift
public final class DataLayout
```

Queries the target data layout (sizes, alignments, pointer sizes).

```swift
public let ref: LLVMTargetDataRef
```
The underlying cLLVM re-exported `LLVMTargetDataRef` handle.

```swift
public init(string: String)
```
Creates a data layout from a layout string; owns the underlying handle.

```swift
public init(ref: LLVMTargetDataRef, owns: Bool)
```
Wraps an existing handle, optionally taking ownership.

```swift
public var string: String
```
The layout string representation.

```swift
public var byteOrder: LLVMByteOrdering
```
The byte order (cLLVM re-exported `LLVMByteOrdering`).

```swift
public var pointerSize: UInt32
```
The default pointer size in bits.

```swift
public func pointerSize(addressSpace: UInt32) -> UInt32
```
The pointer size in bits for a specific address space.

```swift
public func intPtrType(in context: Context) -> LLVMType
```
The integer type that matches the default pointer size.

```swift
public func intPtrType(addressSpace: UInt32, in context: Context) -> LLVMType
```
The integer type that matches the pointer size of an address space.

```swift
public func sizeOfTypeInBits(_ type: LLVMType) -> UInt64
```
The size in bits of `type`.

```swift
public func storeSizeOfType(_ type: LLVMType) -> UInt64
```
The store size in bits of `type`.

```swift
public func abiSizeOfType(_ type: LLVMType) -> UInt64
```
The ABI size in bits of `type`.

```swift
public func abiAlignmentOfType(_ type: LLVMType) -> UInt32
```
The ABI alignment in bits of `type`.

```swift
public func callFrameAlignmentOfType(_ type: LLVMType) -> UInt32
```
The call-frame alignment in bits of `type`.

```swift
public func preferredAlignmentOfType(_ type: LLVMType) -> UInt32
```
The preferred alignment in bits of `type`.

```swift
public func preferredAlignmentOfGlobal(_ global: GlobalVariable) -> UInt32
```
The preferred alignment in bits of a global variable.

```swift
public func element(atOffset offset: UInt64, in structType: StructType) -> UInt32
```
The element index at byte `offset` within a struct.

```swift
public func offsetOfElement(_ index: UInt32, in structType: StructType) -> UInt64
```
The byte offset of element `index` within a struct.

### Module Extension — data layout

```swift
public var dataLayout: DataLayout { get set }
```
The module's data layout (borrowed on get).

### TargetMachine Extension — data layout

```swift
public var dataLayout: DataLayout
```
The target machine's data layout (owned).

## DIBuilder.swift

### DIBuilder

```swift
public final class DIBuilder
```

Emits DWARF debug information into a module.

```swift
public let ref: LLVMDIBuilderRef
```
The underlying cLLVM re-exported `LLVMDIBuilderRef` handle.

```swift
public let module: Module
```
The module debug info is emitted into.

```swift
public init(module: Module)
```
Creates a debug-info builder for the module.

```swift
public func finalize()
```
Finalizes the debug-info module.

```swift
public func finalizeSubprogram(_ subprogram: Metadata)
```
Finalizes a subprogram descriptor.

```swift
public func createFile(_ filename: String, directory: String) -> Metadata
```
Creates a file descriptor.

```swift
public func createCompileUnit(language: LLVMDWARFSourceLanguage, file: Metadata, producer: String, isOptimized: Bool = false, flags: String = "", runtimeVersion: UInt32 = 0, emissionKind: LLVMDWARFEmissionKind = LLVMDWARFEmissionFull, splitDebugInlining: Bool = true) -> Metadata
```
Creates a compile-unit descriptor. The language and emission-kind types are cLLVM re-exported.

```swift
public func createSubroutineType(file: Metadata, returnTypes: [Metadata] = []) -> Metadata
```
Creates a subroutine type descriptor.

```swift
public func createFunction(scope: Metadata, name: String, linkageName: String = "", file: Metadata, line: UInt32, subroutineType: Metadata, isLocalToUnit: Bool = true, isDefinition: Bool = true, scopeLine: UInt32 = 0, flags: LLVMDIFlags = LLVMDIFlagZero, isOptimized: Bool = false) -> Metadata
```
Creates a function descriptor. `flags` is a cLLVM re-exported `LLVMDIFlags`.

```swift
public func createLexicalBlock(scope: Metadata, file: Metadata, line: UInt32, column: UInt32) -> Metadata
```
Creates a lexical block descriptor.

```swift
public func createDebugLocation(line: UInt32, column: UInt32, scope: Metadata, inlinedAt: Metadata? = nil) -> Metadata
```
Creates a debug location.

```swift
public func createBasicType(name: String, sizeInBits: UInt64, encoding: LLVMDWARFTypeEncoding, flags: LLVMDIFlags = LLVMDIFlagZero) -> Metadata
```
Creates a basic type descriptor. `encoding` is a cLLVM re-exported `LLVMDWARFTypeEncoding`.

```swift
public func createParameterVariable(scope: Metadata, name: String, argNo: UInt32, file: Metadata, line: UInt32, type: Metadata, alwaysPreserve: Bool = false, flags: LLVMDIFlags = LLVMDIFlagZero) -> Metadata
```
Creates a parameter variable descriptor.

```swift
public func createAutoVariable(scope: Metadata, name: String, file: Metadata, line: UInt32, type: Metadata, alwaysPreserve: Bool = false, flags: LLVMDIFlags = LLVMDIFlagZero, alignInBits: UInt32 = 0) -> Metadata
```
Creates an automatic (local) variable descriptor.

```swift
public func insertDeclareAtEnd(_ value: Value, diVar: Metadata, expr: Metadata, location: Metadata, block: BasicBlock)
```
Inserts a `llvm.dbg.declare` intrinsic record at the end of a block.

```swift
public func createPointerType(_ pointee: Metadata, sizeInBits: UInt64, alignInBits: UInt32 = 0, addressSpace: UInt32 = 0, name: String = "") -> Metadata
```
Creates a pointer type descriptor.

```swift
public func createQualifiedType(tag: UInt32, type: Metadata) -> Metadata
```
Creates a qualified type descriptor (const, volatile, …).

```swift
public func createNullPtrType() -> Metadata
```
Creates a null pointer type descriptor.

```swift
public func createTypedef(type: Metadata, name: String, file: Metadata, line: UInt32, scope: Metadata, alignInBits: UInt32 = 0) -> Metadata
```
Creates a typedef descriptor.

```swift
public func createStructType(scope: Metadata, name: String, file: Metadata, line: UInt32, sizeInBits: UInt64, alignInBits: UInt32, flags: LLVMDIFlags = LLVMDIFlagZero, derivedFrom: Metadata? = nil, elements: [Metadata] = []) -> Metadata
```
Creates a struct type descriptor.

```swift
public func createMemberType(scope: Metadata, name: String, file: Metadata, line: UInt32, sizeInBits: UInt64, alignInBits: UInt32, offsetInBits: UInt64, flags: LLVMDIFlags = LLVMDIFlagZero, type: Metadata) -> Metadata
```
Creates a member type descriptor.

```swift
public func createArrayType(size: UInt64, alignInBits: UInt32, elementType: Metadata, subscripts: [Metadata]) -> Metadata
```
Creates an array type descriptor.

```swift
public func createUnionType(scope: Metadata, name: String, file: Metadata, line: UInt32, sizeInBits: UInt64, alignInBits: UInt32, flags: LLVMDIFlags = LLVMDIFlagZero, elements: [Metadata] = []) -> Metadata
```
Creates a union type descriptor.

```swift
public func createForwardDecl(tag: UInt32, name: String, scope: Metadata, file: Metadata, line: UInt32, sizeInBits: UInt64 = 0, alignInBits: UInt32 = 0, uniqueIdentifier: String = "") -> Metadata
```
Creates a forward declaration descriptor.

```swift
public func createUnspecifiedType(_ name: String) -> Metadata
```
Creates an unspecified type descriptor.

```swift
public func createExpression(_ ops: [UInt64]) -> Metadata
```
Creates a DWARF expression node.

```swift
public func createConstantValueExpression(_ value: UInt64) -> Metadata
```
Creates a constant value expression node.

```swift
public func getOrCreateArray(_ elements: [Metadata]) -> Metadata
```
Gets (or creates) an array of metadata elements.

```swift
public func getOrCreateSubrange(lowerBound: Int64, count: Int64) -> Metadata
```
Gets (or creates) a subrange descriptor.

```swift
public func createGlobalVariableExpression(scope: Metadata, name: String, linkageName: String = "", file: Metadata, line: UInt32, type: Metadata, isLocalToUnit: Bool = true, expr: Metadata, decl: Metadata? = nil, alignInBits: UInt32 = 0) -> Metadata
```
Creates a global variable expression descriptor.

```swift
public func insertDbgValueRecordAtEnd(_ value: Value, diVar: Metadata, expr: Metadata, location: Metadata, block: BasicBlock)
```
Inserts a `llvm.dbg.value` intrinsic record at the end of a block.

```swift
public func createModule(scope: Metadata, name: String, configMacros: String = "", includePath: String = "", apiNotesFile: String = "") -> Metadata
```
Creates a debug-info module descriptor.

```swift
public func createNameSpace(scope: Metadata, name: String, exportSymbols: Bool = false) -> Metadata
```
Creates a namespace descriptor.

```swift
public func createEnumerator(name: String, value: Int64, isUnsigned: Bool = false) -> Metadata
```
Creates an enumerator descriptor.

```swift
public func createEnumerationType(scope: Metadata, name: String, file: Metadata, line: UInt32, sizeInBits: UInt64, alignInBits: UInt32, elements: [Metadata], classType: Metadata? = nil) -> Metadata
```
Creates an enumeration type descriptor.

```swift
public func createLexicalBlockFile(scope: Metadata, file: Metadata, discriminator: UInt32) -> Metadata
```
Creates a lexical block file descriptor.

```swift
public func createImportedModuleFromNamespace(scope: Metadata, namespace: Metadata, file: Metadata, line: UInt32) -> Metadata
```
Creates an imported-module descriptor.

### Metadata

```swift
public final class Metadata
```
A debug-info metadata node.

```swift
public let ref: LLVMMetadataRef
```
The underlying cLLVM re-exported `LLVMMetadataRef` handle.

```swift
public init(ref: LLVMMetadataRef)
```
Wraps an existing metadata handle.

```swift
public var tag: UInt16
```
The DINode tag.

```swift
public var kind: LLVMMetadataKind
```
The metadata kind (cLLVM re-exported `LLVMMetadataKind`).

## Disassembler.swift

### Disassembler

```swift
public final class Disassembler
```
A target-specific instruction disassembler.

```swift
public let ref: LLVMDisasmContextRef
```
The underlying cLLVM re-exported `LLVMDisasmContextRef` handle.

```swift
public init?(triple: String, cpu: String = "", features: String = "")
```
Creates a disassembler for `triple`; returns `nil` if the target is unavailable.

```swift
@discardableResult
public func setOptions(_ options: UInt64) -> Bool
```
Sets disassembler options; returns whether they were accepted.

```swift
public func disassemble(_ bytes: [UInt8], pc: UInt64 = 0) -> [String]
```
Disassembles the byte array starting at program counter `pc`, returning the instruction texts.

## Error.swift

### LLVMError

```swift
public enum LLVMError: Error {
    case targetNotFound(triple: String)
    case emitFailed(message: String)
    case parseFailed(message: String)
    case passRunFailed(message: String)
}
```
The error type thrown by all throwing APIs in the binding.

## ExecutionEngine.swift

### GenericValue

```swift
public final class GenericValue
```
A generic JIT value used to pass arguments to and read results from JIT-compiled functions.

```swift
public let ref: LLVMGenericValueRef
```
The underlying cLLVM re-exported `LLVMGenericValueRef` handle.

```swift
public init(ref: LLVMGenericValueRef)
```
Wraps an existing generic value handle.

```swift
public static func ofInt(_ value: UInt64, type: LLVMType, isSigned: Bool = false) -> GenericValue
```
Creates a generic value holding an integer.

```swift
public static func ofPointer(_ pointer: UnsafeMutableRawPointer?) -> GenericValue
```
Creates a generic value holding a pointer.

```swift
public static func ofFloat(_ value: Double, type: LLVMType) -> GenericValue
```
Creates a generic value holding a floating-point number.

```swift
public var intWidth: UInt32
```
The bit width of the integer held by this value.

```swift
public func toInt(isSigned: Bool) -> UInt64
```
Reads the integer, interpreted according to `isSigned`.

```swift
public var pointer: UnsafeMutableRawPointer?
```
The pointer held by this value, or `nil`.

```swift
public func toFloat(type: LLVMType) -> Double
```
Reads the floating-point value as a `Double`.

### ExecutionEngine

```swift
public final class ExecutionEngine
```
An MCJIT execution engine that compiles a module and runs its functions.

```swift
public let ref: LLVMExecutionEngineRef
```
The underlying cLLVM re-exported `LLVMExecutionEngineRef` handle.

```swift
public init(module: Module, optLevel: UInt32 = 0) throws
```
Creates an execution engine for the module at the given optimization level.

```swift
public func runFunction(_ function: Function, args: [GenericValue] = []) -> GenericValue?
```
Runs a function with the given arguments; returns `nil` if it returns void.

```swift
public func functionAddress(_ name: String) -> UInt64
```
The address of the function with `name`, or `0` if not found.

```swift
public func pointerToGlobal(_ global: GlobalVariable) -> UnsafeMutableRawPointer?
```
The JIT-resolved address of a global variable.

```swift
public func addModule(_ module: Module)
```
Adds another module to the engine, transferring ownership.

```swift
public func findFunction(_ name: String) -> Function?
```
Finds a function by name in the engine, or `nil`.

```swift
public func runStaticConstructors()
```
Runs the module's static constructors.

```swift
public func runStaticDestructors()
```
Runs the module's static destructors.

```swift
public func removeModule(_ module: Module) throws -> Module
```
Removes a module from the engine and returns it.

```swift
public func addGlobalMapping(_ global: GlobalVariable, to pointer: UnsafeMutableRawPointer)
```
Maps a global variable to a concrete pointer.

```swift
public func globalValueAddress(_ name: String) -> UInt64
```
The address of the global value with `name`, or `0`.

```swift
public var targetData: DataLayout
```
The engine's target data layout (borrowed).

```swift
public var targetMachine: TargetMachine
```
The engine's target machine (borrowed).

```swift
public var lastErrorMessage: String?
```
The last engine error message, or `nil`.

```swift
public func runFunctionAsMain(_ function: Function, args: [String] = [], env: [String] = []) -> Int32
```
Runs a function as `main`, passing `args` as `argv` and `env` as `envp`; returns the exit status.

```swift
public func freeMachineCode(for function: Function)
```
Frees the machine code compiled for a function.

## Function.swift

### Function

```swift
public final class Function: Value
```
A function value, owned by a module.

```swift
public init(ref: LLVMValueRef, module: Module)
```
Wraps an existing function handle.

```swift
public func appendBasicBlock(_ name: String) -> BasicBlock
```
Appends a new basic block with `name` to the function.

```swift
public var parameterCount: UInt32
```
The number of parameters.

```swift
public func parameter(at index: UInt32) -> Argument
```
The parameter at `index`.

```swift
public var entryBlock: BasicBlock?
```
The entry basic block, or `nil`.

```swift
public var basicBlockCount: UInt32
```
The number of basic blocks.

```swift
public var basicBlocks: [BasicBlock]
```
All basic blocks in the function, in order.

```swift
public var parameters: [Argument]
```
All parameters, in order.

```swift
public func setSubprogram(_ sp: Metadata)
```
Sets the debug subprogram metadata.

```swift
public var subprogram: Metadata?
```
The debug subprogram metadata, or `nil`.

```swift
public var personality: Function? { get set }
```
The personality function, or `nil`; settable.

```swift
public var gc: String? { get set }
```
The garbage-collector name, or `nil`; settable.

```swift
public var linkage: LLVMLinkage { get set }
```
The linkage (cLLVM re-exported `LLVMLinkage`).

```swift
public var callConv: LLVMCallConv { get set }
```
The calling convention (cLLVM re-exported `LLVMCallConv`).

## GlobalAlias.swift

### GlobalAlias

```swift
public final class GlobalAlias: Value
```
A global alias.

```swift
public init(ref: LLVMValueRef, module: Module)
```
Wraps an existing alias handle.

```swift
public var aliasee: Value?
```
The aliased value, or `nil`.

```swift
public var aliaseeType: LLVMType
```
The type of the aliased value.

### GlobalIFunc

```swift
public final class GlobalIFunc: Value
```
A global indirect function.

```swift
public init(ref: LLVMValueRef, module: Module)
```
Wraps an existing ifunc handle.

```swift
public var resolver: Value?
```
The resolver function, or `nil`.

## GlobalVariable.swift

### GlobalVariable

```swift
public final class GlobalVariable: Value
```
A global variable.

```swift
public init(ref: LLVMValueRef, module: Module)
```
Wraps an existing global handle.

```swift
public var initializer: Constant? { get set }
```
The initializer constant, or `nil`; settable.

```swift
public override var isConstant: Bool
```
Whether the global is declared constant.

```swift
public var isThreadLocal: Bool { get set }
```
Whether the global is thread-local.

```swift
public var isGlobalConstant: Bool { get set }
```
Whether the global is a constant.

```swift
public var tlsModel: LLVMThreadLocalMode { get set }
```
The thread-local model (cLLVM re-exported `LLVMThreadLocalMode`).

```swift
public var section: String { get set }
```
The section this global lives in.

```swift
public var unnamedAddress: LLVMUnnamedAddr { get set }
```
The unnamed-address mode (cLLVM re-exported `LLVMUnnamedAddr`).

```swift
public var linkage: LLVMLinkage { get set }
```
The linkage (cLLVM re-exported `LLVMLinkage`).

```swift
public var alignment: UInt32 { get set }
```
The alignment in bits.

```swift
public var parentModule: Module
```
The module that owns this global (borrowed).

```swift
public func addDebugInfo(_ gve: Metadata)
```
Adds a debug-info global variable expression to this global.

```swift
public func setMetadata(kind: UInt32, _ metadata: Metadata?)
```
Sets the metadata of the given kind.

```swift
public func addMetadata(kind: UInt32, _ metadata: Metadata)
```
Adds a metadata node of the given kind.

```swift
public func eraseMetadata(kind: UInt32)
```
Erases the metadata of the given kind.

```swift
public func clearMetadata()
```
Clears all metadata on this global.

## Instruction.swift

### OperandBundle

```swift
public struct OperandBundle {
    public let tag: String
    public let args: [Value]
}
```
An operand bundle attached to a call-like instruction.

```swift
public init(tag: String, args: [Value])
```
Creates an operand bundle with a tag and argument values.

### Instruction

```swift
public class Instruction: Value
```
Base class of all instructions.

```swift
public static func wrap(_ ref: LLVMValueRef, context: Context, module: Module?) -> Instruction
```
Wraps an instruction handle into the concrete subclass matching its opcode.

```swift
public var opcode: LLVMOpcode
```
The instruction opcode (cLLVM re-exported `LLVMOpcode`).

```swift
public var opcodeName: String
```
A human-readable name for the opcode.

```swift
public var operandBundles: [OperandBundle]
```
The operand bundles of a call/invoke/callbr instruction, or `[]`.

```swift
public var debugLocLine: UInt32
```
The line of the debug location.

```swift
public var debugLocColumn: UInt32
```
The column of the debug location.

```swift
public var debugLocFilename: String?
```
The filename of the debug location, or `nil`.

```swift
public var debugLocDirectory: String?
```
The directory of the debug location, or `nil`.

```swift
public var parentBlock: BasicBlock?
```
The basic block containing this instruction, or `nil`.

```swift
public func clone() -> Instruction?
```
Clones the instruction, or `nil` on failure.

```swift
public func removeFromParent()
```
Detaches the instruction from its parent block.

```swift
public func eraseFromParent()
```
Erases the instruction from its parent block.

### ReturnInst

```swift
public final class ReturnInst: Instruction
```
A `ret` instruction.

### BinaryOperator

```swift
public final class BinaryOperator: Instruction
```
A binary operation instruction.

### AllocaInst

```swift
public final class AllocaInst: Instruction
```
An `alloca` instruction.

### LoadInst

```swift
public final class LoadInst: Instruction
```
A `load` instruction.

```swift
public var isVolatile: Bool { get set }
```
Whether the load is volatile.

```swift
public var ordering: LLVMAtomicOrdering { get set }
```
The atomic ordering (cLLVM re-exported `LLVMAtomicOrdering`).

### StoreInst

```swift
public final class StoreInst: Instruction
```
A `store` instruction.

```swift
public var isVolatile: Bool { get set }
```
Whether the store is volatile.

```swift
public var ordering: LLVMAtomicOrdering { get set }
```
The atomic ordering (cLLVM re-exported `LLVMAtomicOrdering`).

### BranchInst

```swift
public final class BranchInst: Instruction
```
A `br` instruction.

### SwitchInst

```swift
public final class SwitchInst: Instruction
```
A `switch` instruction.

```swift
public func addCase(_ on: Value, _ dest: BasicBlock)
```
Adds a case to the switch.

```swift
public var condition: Value?
```
The value being switched on.

```swift
public var defaultDestination: BasicBlock?
```
The default destination block, or `nil`.

```swift
public var caseCount: UInt32
```
The number of cases.

```swift
public func caseDestination(at index: UInt32) -> BasicBlock?
```
The destination block of the case at `index`, or `nil`.

### ICmpInst

```swift
public final class ICmpInst: Instruction
```
An `icmp` instruction.

```swift
public var predicate: LLVMIntPredicate
```
The comparison predicate (cLLVM re-exported `LLVMIntPredicate`).

### FCmpInst

```swift
public final class FCmpInst: Instruction
```
An `fcmp` instruction.

```swift
public var predicate: LLVMRealPredicate
```
The comparison predicate (cLLVM re-exported `LLVMRealPredicate`).

### CallInst

```swift
public final class CallInst: Instruction
```
A `call` instruction.

```swift
public var isTailCall: Bool { get set }
```
Whether this is a tail call.

```swift
public var tailCallKind: LLVMTailCallKind { get set }
```
The tail-call kind (cLLVM re-exported `LLVMTailCallKind`).

```swift
public var callConvention: LLVMCallConv { get set }
```
The calling convention (cLLVM re-exported `LLVMCallConv`).

```swift
public var calledValue: Value?
```
The callee value, or `nil`.

```swift
public var calledFunctionType: LLVMType?
```
The function type of the callee, or `nil`.

### CallBrInst

```swift
public final class CallBrInst: Instruction
```
A `callbr` instruction.

### PHINode

```swift
public final class PHINode: Instruction
```
A `phi` node.

```swift
public func addIncoming(_ value: Value, from block: BasicBlock)
```
Adds a single incoming `(value, block)` pair.

```swift
public func addIncoming(_ values: [(value: Value, block: BasicBlock)])
```
Adds multiple incoming `(value, block)` pairs.

```swift
public var incomingCount: UInt32
```
The number of incoming edges.

```swift
public func incomingValue(at index: UInt32) -> Value
```
The incoming value at `index`.

```swift
public func incomingBlock(at index: UInt32) -> BasicBlock?
```
The incoming block at `index`, or `nil`.

### SelectInst

```swift
public final class SelectInst: Instruction
```
A `select` instruction.

### GetElementPtrInst

```swift
public final class GetElementPtrInst: Instruction
```
A `getelementptr` instruction.

### CastInst

```swift
public final class CastInst: Instruction
```
A cast instruction.

```swift
public var value: Value?
```
The operand being cast.

```swift
public var destinationType: LLVMType
```
The destination type of the cast.

### UnreachableInst

```swift
public final class UnreachableInst: Instruction
```
An `unreachable` instruction.

### FenceInst

```swift
public final class FenceInst: Instruction
```
A `fence` instruction.

### AtomicRMWInst

```swift
public final class AtomicRMWInst: Instruction
```
An atomic read-modify-write instruction.

```swift
public var isVolatile: Bool { get set }
```
Whether the operation is volatile.

```swift
public var ordering: LLVMAtomicOrdering { get set }
```
The atomic ordering (cLLVM re-exported `LLVMAtomicOrdering`).

```swift
public var binOp: LLVMAtomicRMWBinOp { get set }
```
The binary operation (cLLVM re-exported `LLVMAtomicRMWBinOp`).

### AtomicCmpXchgInst

```swift
public final class AtomicCmpXchgInst: Instruction
```
An atomic compare-and-exchange instruction.

```swift
public var isVolatile: Bool { get set }
```
Whether the operation is volatile.

### ExtractValueInst

```swift
public final class ExtractValueInst: Instruction
```
An `extractvalue` instruction.

### InsertValueInst

```swift
public final class InsertValueInst: Instruction
```
An `insertvalue` instruction.

### ExtractElementInst

```swift
public final class ExtractElementInst: Instruction
```
An `extractelement` instruction.

### InsertElementInst

```swift
public final class InsertElementInst: Instruction
```
An `insertelement` instruction.

### ShuffleVectorInst

```swift
public final class ShuffleVectorInst: Instruction
```
A `shufflevector` instruction.

### FreezeInst

```swift
public final class FreezeInst: Instruction
```
A `freeze` instruction.

### VAArgInst

```swift
public final class VAArgInst: Instruction
```
A `va_arg` instruction.

### ResumeInst

```swift
public final class ResumeInst: Instruction
```
A `resume` instruction.

### InvokeInst

```swift
public final class InvokeInst: Instruction
```
An `invoke` instruction.

```swift
public func addClause(_ clause: Value)
```
Adds a clause to the invoke.

### LandingPadInst

```swift
public final class LandingPadInst: Instruction
```
A `landingpad` instruction.

```swift
public var isCleanup: Bool { get set }
```
Whether the landing pad is a cleanup.

```swift
public var clauseCount: UInt32
```
The number of clauses.

```swift
public func clause(at index: UInt32) -> Value
```
The clause at `index`.

```swift
public func addClause(_ clause: Value)
```
Adds a clause to the landing pad.

### CatchPadInst

```swift
public final class CatchPadInst: Instruction
```
A `catchpad` instruction.

### CleanupPadInst

```swift
public final class CleanupPadInst: Instruction
```
A `cleanuppad` instruction.

### IndirectBrInst

```swift
public final class IndirectBrInst: Instruction
```
An `indirectbr` instruction.

```swift
public func addDestination(_ dest: BasicBlock)
```
Adds a destination block.

### CleanupRetInst

```swift
public final class CleanupRetInst: Instruction
```
A `cleanupret` instruction.

### CatchRetInst

```swift
public final class CatchRetInst: Instruction
```
A `catchret` instruction.

### CatchSwitchInst

```swift
public final class CatchSwitchInst: Instruction
```
A `catchswitch` instruction.

```swift
public func addHandler(_ handler: BasicBlock)
```
Adds a handler block.

## IRReader.swift

### Module Extension — IR reading

```swift
public static func parseIR(_ ir: String, in context: Context, bufferName: String = "ir") throws -> Module
```
Parses IR text into a module.

```swift
public static func parseIRFile(_ path: String, in context: Context) throws -> Module
```
Parses an IR file into a module.

```swift
public static func parseBitcode(_ data: [UInt8], in context: Context) throws -> Module
```
Parses in-memory bitcode into a module.

```swift
public static func parseBitcodeFile(_ path: String, in context: Context) throws -> Module
```
Parses a bitcode file into a module.

```swift
public func writeBitcode(to path: String) throws
```
Writes the module to a bitcode file.

```swift
public func writeBitcodeToMemoryBuffer() -> MemoryBuffer
```
Serializes the module to an in-memory bitcode buffer.

## Linker.swift

### Module Extension — linking

```swift
public func link(_ source: Module) throws
```
Links `source` into this module; the source is consumed and must not be reused.

## LLJIT.swift

### LLJIT

```swift
public final class LLJIT
```
An ORC JIT that compiles and executes LLVM IR modules.

```swift
public let ref: LLVMOrcLLJITRef
```
The underlying cLLVM re-exported `LLVMOrcLLJITRef` handle.

```swift
public init() throws
```
Creates an LLJIT instance, initializing all targets first.

```swift
public var dataLayout: String
```
The JIT's data layout string.

```swift
public var triple: String
```
The JIT's target triple.

```swift
public var globalPrefix: Character
```
The JIT's global symbol prefix.

```swift
public func enableDebugSupport() throws
```
Enables debug support (e.g. GDB JIT registration).

```swift
public func addModule(_ module: Module) throws
```
Adds an IR module to the main JIT dylib.

```swift
public func lookup(_ name: String) throws -> UInt64
```
Resolves the address of the symbol with `name`.

## LLVMSwiftBinding.swift

```swift
@_exported import cLLVM
```
The module file re-exports the **cLLVM** C layer, making every C type and
function (`LLVMTypeRef`, `LLVMValueRef`, `LLVMAtomicOrdering`, `LLVMLinkage`,
`LLVMAttributeIndex`, `LLVMOrcLLJITRef`, …) visible through
`import LLVMSwiftBinding`. There are no additional declarations in this file.

## MemoryBuffer.swift

### MemoryBuffer

```swift
public final class MemoryBuffer
```
An in-memory buffer of bytes.

```swift
public let ref: LLVMMemoryBufferRef
```
The underlying cLLVM re-exported `LLVMMemoryBufferRef` handle.

```swift
public init(ref: LLVMMemoryBufferRef, owns: Bool = true)
```
Wraps an existing buffer handle, optionally taking ownership.

```swift
public var bytes: [UInt8]
```
The raw buffer contents.

```swift
public var string: String?
```
The buffer contents as a string, or `nil` if empty.

```swift
public static func fromString(_ str: String, bufferName: String = "") -> MemoryBuffer
```
Creates a buffer from a string.

```swift
public static func fromBytes(_ bytes: [UInt8], bufferName: String = "") -> MemoryBuffer
```
Creates a buffer from raw bytes.

```swift
public static func fromFile(_ path: String) throws -> MemoryBuffer
```
Reads a file into a buffer, throwing `LLVMError.parseFailed` on failure.

## Module.swift

### Module

```swift
public final class Module
```
An LLVM IR module — the unit you verify, print, link, and serialize.

```swift
public let ref: LLVMModuleRef
```
The underlying cLLVM re-exported `LLVMModuleRef` handle.

```swift
public let context: Context
```
The context the module belongs to.

```swift
public var ownsRef: Bool = true
```
Whether this wrapper disposes the underlying module on deinit.

```swift
public init(name: String, in context: Context)
```
Creates a named module in the given context.

```swift
public init(ref: LLVMModuleRef, context: Context)
```
Wraps an existing module handle.

```swift
public func dump()
```
Prints the module IR to stderr.

```swift
public func clone() -> Module
```
Clones the module.

```swift
public var irString: String
```
The module IR as a string.

```swift
public func addFunction(_ name: String, type: FunctionType) -> Function
```
Adds a function with the given name and type.

```swift
public func function(named name: String) -> Function?
```
Finds a function by name, or `nil`.

```swift
public func getOrInsertFunction(_ name: String, type: FunctionType) -> Function
```
Gets an existing function or inserts a new declaration.

```swift
public var functions: [Function]
```
All functions in the module.

```swift
public func addAlias(_ name: String, type: LLVMType, aliasee: Value, addressSpace: UInt32 = 0) -> GlobalAlias
```
Adds a global alias.

```swift
public func alias(named name: String) -> GlobalAlias?
```
Finds a global alias by name, or `nil`.

```swift
public var aliases: [GlobalAlias]
```
All global aliases in the module.

```swift
public func addIFunc(_ name: String, type: FunctionType, resolver: Value, addressSpace: UInt32 = 0) -> GlobalIFunc
```
Adds a global indirect function.

```swift
public func ifunc(named name: String) -> GlobalIFunc?
```
Finds a global ifunc by name, or `nil`.

```swift
public var ifuncs: [GlobalIFunc]
```
All global ifuncs in the module.

```swift
public func addGlobal(_ name: String, type: LLVMType) -> GlobalVariable
```
Adds a global variable.

```swift
public func global(named name: String) -> GlobalVariable?
```
Finds a global variable by name, or `nil`.

```swift
public var globals: [GlobalVariable]
```
All global variables in the module.

```swift
public var target: String { get set }
```
The target triple string.

```swift
public var identifier: String { get set }
```
The module identifier string.

```swift
public var sourceFileName: String { get set }
```
The source file name string.

```swift
public var inlineAsm: String { get set }
```
The module-level inline assembly.

```swift
public func addNamedMetadataOperand(_ name: String, _ node: Value)
```
Adds an operand to the named metadata node `name`.

```swift
public var namedMetadataNames: [String]
```
The names of all named metadata nodes.

```swift
public func namedMetadataOperandCount(_ name: String) -> UInt32
```
The operand count of the named metadata node `name`.

```swift
public func namedMetadataOperands(_ name: String) -> [Value]
```
The operands of the named metadata node `name`.

## Object.swift

### SectionInfo

```swift
public struct SectionInfo {
    public let name: String
    public let size: UInt64
    public let contents: [UInt8]
    public let address: UInt64
}
```
Describes one section of an object file.

```swift
public init(name: String, size: UInt64, contents: [UInt8], address: UInt64)
```
Creates a section descriptor.

### SymbolInfo

```swift
public struct SymbolInfo {
    public let name: String
    public let address: UInt64
    public let size: UInt64
}
```
Describes one symbol of an object file.

```swift
public init(name: String, address: UInt64, size: UInt64)
```
Creates a symbol descriptor.

### Binary

```swift
public final class Binary
```
An object-file binary opened for inspection.

```swift
public let ref: LLVMBinaryRef
```
The underlying cLLVM re-exported `LLVMBinaryRef` handle.

```swift
public let buffer: MemoryBuffer
```
The buffer the binary was created from.

```swift
public init(buffer: MemoryBuffer, context: Context? = nil) throws
```
Creates a binary from a buffer, throwing `LLVMError.parseFailed` on failure.

```swift
public var type: LLVMBinaryType
```
The binary format type (cLLVM re-exported `LLVMBinaryType`).

```swift
public var typeDescription: String
```
A human-readable description of the binary type.

```swift
public func sections() -> [SectionInfo]
```
All sections of the binary.

```swift
public func symbols() -> [SymbolInfo]
```
All symbols of the binary.

## PassManager.swift

### PassManager

```swift
public final class PassManager
```
Runs LLVM optimization passes over a module or a single function.

```swift
public let ref: LLVMPassManagerRef
```
The underlying cLLVM re-exported `LLVMPassManagerRef` handle.

```swift
public init()
```
Creates a module pass manager.

```swift
public init(module: Module)
```
Creates a function pass manager for the module.

```swift
public func addAnalysisPasses(of targetMachine: TargetMachine)
```
Adds the target machine's analysis passes.

```swift
@discardableResult
public func run(on module: Module) -> Bool
```
Runs the pass manager over the module; returns whether it was preserved.

```swift
@discardableResult
public func initialize() -> Bool
```
Initializes the function pass manager.

```swift
@discardableResult
public func run(on function: Function) -> Bool
```
Runs the pass manager over a single function.

```swift
@discardableResult
public func finalize() -> Bool
```
Finalizes the function pass manager.

```swift
public func runPasses(_ passes: String, on module: Module, targetMachine: TargetMachine? = nil, options: PassBuilderOptions? = nil) throws
```
Runs the named new-PM passes over the module.

```swift
public func runPassesOnFunction(_ passes: String, function: Function, targetMachine: TargetMachine? = nil, options: PassBuilderOptions? = nil) throws
```
Runs the named new-PM passes over a single function.

### PassBuilderOptions

```swift
public final class PassBuilderOptions
```
Options controlling the new pass manager.

```swift
public let ref: LLVMPassBuilderOptionsRef
```
The underlying cLLVM re-exported `LLVMPassBuilderOptionsRef` handle.

```swift
public init()
```
Creates an empty options object.

```swift
public func setVerifyEach(_ value: Bool)
```
Enables or disables verifying the module after each pass.

```swift
public func setDebugLogging(_ value: Bool)
```
Enables or disables debug logging.

```swift
public func setLoopInterleaving(_ value: Bool)
```
Enables or disables loop interleaving.

```swift
public func setLoopVectorization(_ value: Bool)
```
Enables or disables loop vectorization.

```swift
public func setSLPVectorization(_ value: Bool)
```
Enables or disables SLP vectorization.

```swift
public func setLoopUnrolling(_ value: Bool)
```
Enables or disables loop unrolling.

```swift
public func setCallGraphProfile(_ value: Bool)
```
Enables or disables call-graph profiling.

```swift
public func setMergeFunctions(_ value: Bool)
```
Enables or disables function merging.

```swift
public func setInlinerThreshold(_ value: Int32)
```
Sets the inliner threshold.

## TargetMachine.swift

### Target

```swift
public final class Target
```
A registered LLVM target.

```swift
public let ref: LLVMTargetRef
```
The underlying cLLVM re-exported `LLVMTargetRef` handle.

```swift
public init(ref: LLVMTargetRef)
```
Wraps an existing target handle.

```swift
public static func fromTriple(_ triple: String) throws -> Target
```
Looks up the target for `triple`, throwing `LLVMError.targetNotFound` if none.

```swift
public var name: String
```
The target name.

```swift
public var description: String
```
The target description.

```swift
public var hasTargetMachine: Bool
```
Whether the target can create target machines.

### TargetMachine

```swift
public final class TargetMachine
```
A target machine used for code generation.

```swift
public let ref: LLVMTargetMachineRef
```
The underlying cLLVM re-exported `LLVMTargetMachineRef` handle.

```swift
public var ownsRef: Bool = true
```
Whether this wrapper disposes the underlying machine on deinit.

```swift
public init(target: Target, triple: String, cpu: String? = nil, features: String? = nil, optLevel: LLVMCodeGenOptLevel = LLVMCodeGenLevelDefault, relocMode: LLVMRelocMode = LLVMRelocDefault, codeModel: LLVMCodeModel = LLVMCodeModelDefault)
```
Creates a target machine. The level/mode/model types are cLLVM re-exported.

```swift
public init(ref: LLVMTargetMachineRef)
```
Wraps an existing target machine handle (borrowed).

```swift
public static var defaultTriple: String
```
The default target triple.

```swift
public static var hostCPUName: String
```
The host CPU name.

```swift
public static func initializeAllTargets()
```
Initializes all registered targets, target infos, MCs, asm printers, and disassemblers.

```swift
public var target: Target
```
The target this machine was created for.

```swift
public var triple: String
```
The target triple.

```swift
public var cpu: String
```
The CPU name.

```swift
public var featureString: String
```
The feature string.

```swift
public func emitToFile(module: Module, _ filename: String, fileType: LLVMCodeGenFileType = LLVMObjectFile) throws
```
Emits the module to a file in the given format (cLLVM re-exported `LLVMCodeGenFileType`).

## Type.swift

### LLVMType

```swift
public class LLVMType
```
The base class of all types (renamed from `Type`).

```swift
public let ref: LLVMTypeRef
```
The underlying cLLVM re-exported `LLVMTypeRef` handle.

```swift
public let context: Context
```
The context the type belongs to.

```swift
public init(ref: LLVMTypeRef, context: Context)
```
Wraps an existing type handle.

```swift
public var kind: LLVMTypeKind
```
The type kind (cLLVM re-exported `LLVMTypeKind`).

```swift
public var isVoid: Bool
```
Whether this is a `void` type.

```swift
public var isInteger: Bool
```
Whether this is an integer type.

```swift
public var isFloat: Bool
```
Whether this is any floating-point type.

```swift
public var isFunction: Bool
```
Whether this is a function type.

```swift
public var isStruct: Bool
```
Whether this is a struct type.

```swift
public var isArray: Bool
```
Whether this is an array type.

```swift
public var isPointer: Bool
```
Whether this is a pointer type.

```swift
public var isVector: Bool
```
Whether this is a (fixed or scalable) vector type.

```swift
public var isTargetExt: Bool
```
Whether this is a target extension type.

```swift
public var contextRef: LLVMContextRef
```
The owning context (cLLVM re-exported `LLVMContextRef`).

```swift
public var description: String
```
A textual description of the type.

### VoidType

```swift
public final class VoidType: LLVMType
```
The `void` type.

### IntegerType

```swift
public final class IntegerType: LLVMType
```
An integer type.

```swift
public var width: UInt32
```
The bit width.

### FloatType

```swift
public final class FloatType: LLVMType
```
Any floating-point type.

### FunctionType

```swift
public final class FunctionType: LLVMType
```
A function type.

```swift
public var returnType: LLVMType
```
The return type.

```swift
public var parameterCount: UInt32
```
The number of parameter types.

```swift
public var parameterTypes: [LLVMType]
```
The parameter types, in order.

```swift
public var isVariadic: Bool
```
Whether the function type is variadic.

### PointerType

```swift
public final class PointerType: LLVMType
```
A pointer type.

```swift
public var elementType: LLVMType
```
The pointee element type.

```swift
public var addressSpace: UInt32
```
The address space.

### StructType

```swift
public final class StructType: LLVMType
```
A struct type.

```swift
public var elementCount: UInt32
```
The number of element types.

```swift
public var elementTypes: [LLVMType]
```
The element types, in order.

```swift
public func elementType(at index: UInt32) -> LLVMType
```
The element type at `index`.

```swift
public var isPacked: Bool
```
Whether the struct is packed.

```swift
public var isOpaque: Bool
```
Whether the struct is opaque.

```swift
public var isLiteral: Bool
```
Whether the struct is literal.

```swift
public var name: String?
```
The struct name, or `nil` for literal structs.

### ArrayType

```swift
public final class ArrayType: LLVMType
```
An array type.

```swift
public var elementType: LLVMType
```
The element type.

```swift
public var elementCount: UInt64
```
The number of elements.

### VectorType

```swift
public final class VectorType: LLVMType
```
A vector type.

```swift
public var elementType: LLVMType
```
The element type.

```swift
public var elementCount: UInt32
```
The number of elements.

```swift
public var isScalable: Bool
```
Whether the vector is scalable.

### LabelType

```swift
public final class LabelType: LLVMType
```
The label type.

### TokenType

```swift
public final class TokenType: LLVMType
```
The token type.

### MetadataType

```swift
public final class MetadataType: LLVMType
```
The metadata type.

### TargetExtType

```swift
public final class TargetExtType: LLVMType
```
A target extension type.

```swift
public var name: String?
```
The target extension type name, or `nil`.

```swift
public var typeParameterCount: UInt32
```
The number of type parameters.

```swift
public func typeParameter(at index: UInt32) -> LLVMType
```
The type parameter at `index`.

```swift
public var intParameterCount: UInt32
```
The number of integer parameters.

```swift
public func intParameter(at index: UInt32) -> UInt32
```
The integer parameter at `index`.

## Util.swift

This file contains no `public` declarations. It defines only internal helpers
(`disposeMessage`, `errorMessage(from:)` overloads, and `cString`) used by the
rest of the binding; they are not part of the public API.

## Value.swift

### Value

```swift
public class Value
```
The base class of all LLVM values.

```swift
public let ref: LLVMValueRef
```
The underlying cLLVM re-exported `LLVMValueRef` handle.

```swift
public let context: Context
```
The context the value belongs to.

```swift
public let module: Module?
```
The module the value lives in, if any.

```swift
public init(ref: LLVMValueRef, context: Context, module: Module? = nil)
```
Wraps an existing value handle.

```swift
public var type: LLVMType
```
The type of this value.

```swift
public var name: String { get set }
```
The name of this value; settable.

```swift
public var nameWithLength: String
```
The name, read with explicit length (safe for embedded NULs).

```swift
public var shortName: String
```
The name with a leading `%` stripped.

```swift
public var hasMetadata: Bool
```
Whether this value has metadata attached.

```swift
public var isConstant: Bool
```
Whether this is a constant.

```swift
public var isUndef: Bool
```
Whether this is an `undef` value.

```swift
public var isNull: Bool
```
Whether this is a null value.

```swift
public var isPoison: Bool
```
Whether this is a `poison` value.

```swift
public var isDeclaration: Bool
```
Whether this value is a declaration (not a definition).

```swift
public var visibility: LLVMVisibility { get set }
```
The visibility (cLLVM re-exported `LLVMVisibility`).

```swift
public var dllStorageClass: LLVMDLLStorageClass { get set }
```
The DLL storage class (cLLVM re-exported `LLVMDLLStorageClass`).

```swift
public var description: String
```
A textual description of the value.

```swift
public var valueKind: LLVMValueKind
```
The value kind (cLLVM re-exported `LLVMValueKind`).

```swift
public var kindName: String
```
A human-readable name for the value kind.

```swift
public var numOperands: UInt32
```
The number of operands.

```swift
public func operand(at index: UInt32) -> Value?
```
The operand at `index`, or `nil`.

```swift
public func replaceAllUsesWith(_ newValue: Value)
```
Replaces every use of this value with `newValue`.

```swift
public var uses: [Value]
```
All users of this value.

```swift
public var useCount: UInt32
```
The number of users.

```swift
public func operandUser(at index: UInt32) -> Value?
```
The user of the operand at `index`, or `nil`.

```swift
public func setMetadata(kind: UInt32, _ node: Value?)
```
Sets the metadata node of the given kind.

```swift
public func getMetadata(kind: UInt32) -> Value?
```
The metadata node of the given kind, or `nil`.

### Argument

```swift
public final class Argument: Value
```
A function parameter.

```swift
public init(ref: LLVMValueRef, function: Function, module: Module)
```
Wraps an existing argument handle, linked to its function.
