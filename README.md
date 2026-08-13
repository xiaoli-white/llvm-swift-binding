# LLVMSwiftBinding

![Swift](https://img.shields.io/badge/Swift-6.3-orange)
![LLVM](https://img.shields.io/badge/LLVM-22-blue)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

A type-safe Swift binding for the [LLVM C API](https://llvm.org/docs/CoreFunctions.html) (LLVM 22). Build and inspect LLVM IR, run optimizations, emit machine code, and JIT-execute — all from Swift, without dropping down to C.

## Features

- **Type-safe API** over the raw LLVM C interface, with idiomatic Swift ownership (contexts, modules, builders, values).
- **IR construction** — types, constants, functions, basic blocks, and the full instruction set, including typed instruction subclasses (`BinaryOperator`, `LoadInst`, `PHINode`, …).
- **Module management** — verification, printing, cloning, linking, bitcode round-trips, named metadata.
- **Pass pipeline** — legacy pass manager and the new pass manager (via `PassBuilder`).
- **Execution** — MCJIT (`ExecutionEngine`) and ORC JIT (`LLJIT`).
- **Codegen tooling** — target machine queries and code emission, object file inspection, disassembly (x86/ARM), data layout.
- **Debug info** — `DIBuilder` for compile units, types, subprograms, and locations.
- **Zero extra dependencies** — only a system LLVM 22 installation; `cLLVM` types are re-exported so no separate `import cLLVM` is needed.

## Requirements

- Swift 6+ (package tools version 6.3)
- LLVM 22 — `llvm-c` headers and `libLLVM-22`
  - Arch Linux: `sudo pacman -S llvm`
  - Tested with LLVM 22.1.8 on Arch Linux (x86_64)

## Installation

Add as a dependency in `Package.swift`:

```swift
.package(url: "https://github.com/xiaoli-white/llvm-swift-binding", from: "1.0.0")
```

```swift
import LLVMSwiftBinding
```

`cLLVM` types (e.g. `LLVMAtomicOrdering`, `LLVMCCallConv`) are re-exported through `LLVMSwiftBinding` — no separate `import cLLVM` needed.

## Usage

For a complete walkthrough of every workflow — JIT execution (MCJIT and ORC), optimization passes, code generation, IR reading, debug info, object inspection — see the [User Guide](docs/UserGuide.md).

### Generate IR

```swift
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

### JIT-compile and run

Continuing with the same module, compile it with MCJIT and call `main(40)`:

```swift
TargetMachine.initializeAllTargets()
let engine = try ExecutionEngine(module: module)
let result = engine.runFunction(main, args: [GenericValue.ofInt(40, type: i32, isSigned: true)])!
print(result.toInt(isSigned: true)) // prints 42
```

## API overview

| Area | File | Highlights |
|---|---|---|
| Module | `Module.swift` | functions/globals/aliases/ifuncs traversal, named lookup, bitcode, clone, named metadata |
| Context | `Context.swift` | type factories, constant factories, wrap functions |
| Builder | `Builder.swift` | instruction builders, memory intrinsics, atomic ops, callbr, debug location |
| Function | `Function.swift` | parameters, basic blocks, attributes, gc, linkage, call convention, personality |
| Value | `Value.swift` | operands, uses, name, type, printing, RAUW |
| Instruction | `Instruction.swift` | typed subclasses, opcode, operand bundles, debug location, clone/erase |
| LLVMType | `Type.swift` | kind checks, struct/array/vector/target-ext accessors |
| Constant | `Constant.swift` | data arrays, expressions, vectors, block address, poison/undef |
| Globals | `GlobalVariable.swift`, `GlobalAlias.swift` | globals, aliases, ifuncs, TLS models, initializers |
| Debug info | `DIBuilder.swift` | compile units, types, subprograms, locations, declare records |
| ExecutionEngine | `ExecutionEngine.swift` | MCJIT, runFunction, globals, static constructors |
| LLJIT | `LLJIT.swift` | ORC JIT, symbol lookup |
| PassManager | `PassManager.swift` | legacy PM, new PM (PassBuilder), pass options |
| TargetMachine | `TargetMachine.swift` | target queries, code emission, ABI |
| Object | `Object.swift` | object file section/symbol inspection |
| Disassembler | `Disassembler.swift` | x86/ARM instruction disassembly |
| IR reading | `IRReader.swift`, `MemoryBuffer.swift` | parse IR text or bitcode from files and memory |
| Linking | `Linker.swift` | module linking, comdat selection |
| Attributes | `Attribute.swift` | enum/string/type attributes, call-site attributes |
| Data layout | `DataLayout.swift` | target data layout queries |
| Analysis | `Analysis.swift` | module/function verification |

## Project layout

```
Sources/
  cLLVM/                 module map over the system LLVM headers (umbrella llvm-c, links LLVM-22)
  LLVMSwiftBinding/      28 Swift files, one area per file
Tests/
  LLVMSwiftBindingTests/ swift-testing suite
docs/
  UserGuide.md           user guide (full workflow walkthrough)
```

## Testing

```bash
swift test
```

The suite contains 92 tests covering IR construction, codegen, MCJIT and ORC JIT execution, debug info, and more — all passing against LLVM 22.1.8 on Arch Linux (x86_64).

## Contributing

Bug reports and feature requests are welcome via issues; pull requests should follow the existing style — one area per file, public API surface, and a test for each new capability using the swift-testing framework.

## License

Released under the MIT License. See the [LICENSE](LICENSE) file for details.
