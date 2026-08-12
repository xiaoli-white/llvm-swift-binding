# LLVMSwiftBinding User Guide

A type-safe Swift binding over the LLVM C API (LLVM 22). This guide walks through the
main workflows: building IR, running optimizations, emitting machine code, and
JIT-executing — all from Swift.

## Requirements

- Swift 6+ (package tools version 6.3, language mode v6)
- LLVM 22 — `llvm-c` headers and `libLLVM-22`
  - Arch Linux: `sudo pacman -S llvm`

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/xiaoli-white/llvm-swift-binding", from: "1.0.0")
```

Then import it:

```swift
import LLVMSwiftBinding
```

`cLLVM` types (e.g. `LLVMAtomicOrdering`, `LLVMCCallConv`) are re-exported through
`LLVMSwiftBinding`, so a single `import` is enough.

## Quick Start

Build a module, verify it, and print the IR:

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

Output:

```llvm
define i32 @main(i32 %0) {
entry:
  %x = add i32 %0, 2
  ret i32 %x
}
```

## Core Concepts

- **Context** owns LLVM types, constants, and diagnostic state. All types and constants
  are created through it (`ctx.int32`, `ctx.constantInt(...)`, `ctx.functionType(...)`),
  and it caches them internally.
- **Module** holds functions, globals, aliases, and metadata. It is the unit you verify,
  print, link, and serialize.
- **Builder** appends instructions to a basic block. Position it with
  `builder.positionAtEnd(of:)`, then call build methods.
- **Ownership** — every wrapper is a class. Owning classes dispose their underlying C
  object in `deinit`; borrowing wrappers keep a strong reference to their owner. You
  normally do not need to manage lifetimes manually.

## JIT Execution

### MCJIT via ExecutionEngine

Compile a module and call a function directly:

```swift
TargetMachine.initializeAllTargets()
let engine = try ExecutionEngine(module: module)
let result = engine.runFunction(main, args: [GenericValue.ofInt(40, type: i32, isSigned: true)])!
print(result.toInt(isSigned: true)) // prints 42
```

### ORC via LLJIT

`LLJIT` adds IR modules and looks up symbols. There is no built-in `runFunction` —
look up the symbol address and cast it to the function type yourself:

```swift
let jit = try LLJIT()
try jit.addModule(module) // module must contain a `main` that returns i32

let address = try jit.lookup("main")
let fn = unsafeBitCast(UInt(address), to: (@convention(c) () -> Int32).self)
print(fn()) // prints 42
```

`LLJIT` also exposes `dataLayout`, `triple`, `globalPrefix`, and
`enableDebugSupport()` for ORC-level control.

## Optimization Passes

The legacy pass manager operates on a module or a single function:

```swift
let pm = PassManager(module: module)
pm.addAnalysisPasses(of: targetMachine)
_ = pm.initialize()
_ = pm.run(on: module)
_ = pm.finalize()
```

The new pass manager runs passes by name through `PassBuilder`:

```swift
let pm = PassManager()
try pm.runPasses("default<O2>", on: module, targetMachine: targetMachine)
```

## Code Generation

Emit an object file, link it with `cc`, and run the binary:

```swift
TargetMachine.initializeAllTargets()
let triple = TargetMachine.defaultTriple
let target = try Target.fromTriple(triple)
let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

let objPath = "/tmp/example.o"
try tm.emitToFile(module: module, objPath)
```

```bash
cc /tmp/example.o -o /tmp/example && /tmp/example
```

`emitToFile` supports other file types through `fileType:` (assembly, object, etc.).

## Reading IR and Bitcode

```swift
let ctx = Context()

// From IR text
let m1 = try Module.parseIR("define i32 @f() { ret i32 1 }", in: ctx)

// From a file
let m2 = try Module.parseIRFile("/path/to/module.ll", in: ctx)
let m3 = try Module.parseBitcodeFile("/path/to/module.bc", in: ctx)

// Serialize back to bitcode
try m3.writeBitcode(to: "/path/to/out.bc")
```

## Linking Modules

```swift
try destinationModule.link(sourceModule)
```

The source module is consumed by the link and must not be reused.

## Debug Info

`DIBuilder` attaches DWARF metadata to a module:

```swift
let di = DIBuilder(module: module)
let file = di.createFile("example.c", directory: "/tmp")
let cu = di.createCompileUnit(
    language: LLVMDWARFSourceLanguageC,
    file: file,
    producer: "LLVMSwiftBinding",
    isOptimized: false
)
// ... create types, subprograms, locations ...
di.finalize()
```

## Object Inspection and Disassembly

Inspect object file sections and symbols:

```swift
let buffer = try MemoryBuffer.fromFile("/tmp/example.o")
let object = try Object(buffer: buffer)
for section in object.sections() {
    print(section.name, section.address, section.size)
}
```

Disassemble raw bytes for a target:

```swift
if let disassembler = Disassembler(triple: "x86_64-unknown-linux-gnu") {
    for instruction in disassembler.disassemble(bytes) {
        print(instruction)
    }
}
```

## API Area Map

| Area | File | Highlights |
|---|---|---|
| Module | `Module.swift` | functions/globals/aliases/ifuncs traversal, named lookup, bitcode, clone, named metadata |
| Context | `Context.swift` | type factories, constant factories, wrap functions |
| Builder | `Builder.swift` | instruction builders, memory intrinsics, atomic ops, callbr, debug location |
| Function | `Function.swift` | parameters, basic blocks, attributes, gc, linkage, call convention, personality |
| Value | `Value.swift` | operands, uses, name, type, printing, RAUW |
| Instruction | `Instruction.swift` | typed subclasses, opcode, operand bundles, debug location, clone/erase |
| Type | `Type.swift` | kind checks, struct/array/vector/target-ext accessors |
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

## Testing

Run the test suite with:

```bash
swift test
```

The suite uses the swift-testing framework. Two ORC JIT tests are disabled on glibc
2.44 (an LLVM assertion in `tpp.c` on Arch Linux).
