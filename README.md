# LLVMSwiftBinding

Swift binding for the LLVM C API (LLVM 22).

## Requirements

- Swift 6+
- LLVM 22 (`libLLVM-22` + `llvm-c` headers)

## Usage

Add as a dependency in `Package.swift`:

```swift
.package(path: "../llvm-swift-binding")
```

```swift
import LLVMSwiftBinding

let ctx = Context()
let module = Module(name: "example", in: ctx)
let i32 = ctx.int32

let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
let main = module.addFunction("main", type: mainType)
let entry = main.appendBasicBlock("entry")
let builder = Builder(in: ctx)
builder.positionAtEnd(of: entry)
let x = builder.buildAdd(main.parameter(at: 0), ctx.constantInt(2, type: i32), name: "x")
builder.buildRet(x)

try module.verify()
print(module.irString)
```

cLLVM types (e.g. `LLVMAtomicOrdering`, `LLVMCCallConv`) are re-exported — no separate `import cLLVM` needed.

## API overview

| Area | File | Highlights |
|---|---|---|
| Module | `Module.swift` | functions/globals/aliases/ifuncs traversal, named lookup, linking, bitcode, clone, named metadata |
| Context | `Context.swift` | type factories, constant factories, wrap functions |
| Builder | `Builder.swift` | instruction builders, memory intrinsics, atomic ops, callbr, debug location |
| Function | `Function.swift` | parameters, basic blocks, attributes, gc, linkage, call convention, personality |
| Value | `Value.swift` | operands, uses, name, type, printing, RAUW |
| Instruction | `Instruction.swift` | typed subclasses, opcode, operand bundles, debug location, clone/erase |
| Type | `Type.swift` | kind checks, struct/array/vector/target-ext accessors |
| Constant | `Constant.swift` | data arrays, expressions, vectors, block address, poison/undef |
| Debug info | `DIBuilder.swift` | compile units, types, subprograms, locations, declare records |
| ExecutionEngine | `ExecutionEngine.swift` | MCJIT, runFunction, globals, static constructors |
| LLJIT | `LLJIT.swift` | ORC JIT, symbol lookup |
| PassManager | `PassManager.swift` | legacy PM, new PM (PassBuilder), pass options |
| TargetMachine | `TargetMachine.swift` | target queries, code emission, ABI |
| Object | `Object.swift` | object file section/symbol inspection |
| Disassembler | `Disassembler.swift` | x86/ARM instruction disassembly |

## Testing

```bash
swift test
```

All 76 tests pass against LLVM 22.1.8 (2 ORC JIT tests disabled on glibc 2.44).
