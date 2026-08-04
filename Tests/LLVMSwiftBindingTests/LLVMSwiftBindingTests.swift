import Testing
import Foundation
import cLLVM
@testable import LLVMSwiftBinding

@Suite(.serialized)
struct LLVMSwiftBindingTests {

@Test func helloWorldIR() {
    let ctx = Context()
    let module = Module(name: "hello", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let ir = module.irString
    #expect(ir.contains("define i32 @main()"))
    #expect(ir.contains("ret i32 42"))
}

@Test func helloWorldEndToEnd() throws {
    let ctx = Context()
    let module = Module(name: "hello", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)hello_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)hello_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func addAndCall() throws {
    let ctx = Context()
    let module = Module(name: "addcall", in: ctx)
    let i32 = ctx.int32

    let addType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let addFunc = module.addFunction("add", type: addType)
    let addEntry = addFunc.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: addEntry)
    let sum = builder.buildAdd(addFunc.parameter(at: 0), addFunc.parameter(at: 1), name: "sum")
    builder.buildRet(sum)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let mainEntry = main.appendBasicBlock("entry")
    builder.positionAtEnd(of: mainEntry)
    let result = builder.buildCall(addFunc, [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)], name: "result")
    builder.buildRet(result)

    let ir = module.irString
    #expect(ir.contains("define i32 @add"))
    #expect(ir.contains("define i32 @main"))
    #expect(ir.contains("call i32 @add"))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)addcall_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)addcall_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func loopWithPhi() throws {
    let ctx = Context()
    let module = Module(name: "loop", in: ctx)
    let i32 = ctx.int32

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)

    let entry = main.appendBasicBlock("entry")
    let loop = main.appendBasicBlock("loop")
    let body = main.appendBasicBlock("body")
    let done = main.appendBasicBlock("done")

    let builder = Builder(in: ctx)

    builder.positionAtEnd(of: entry)
    builder.buildBr(loop)

    builder.positionAtEnd(of: loop)
    let i = builder.buildPhi(i32, name: "i")
    i.addIncoming(ctx.constantInt(0, type: i32), from: entry)
    let cond = builder.buildICmp(LLVMIntSLT, i, ctx.constantInt(42, type: i32), name: "cond")
    builder.buildCondBr(cond, then: body, else: done)

    builder.positionAtEnd(of: body)
    let next = builder.buildAdd(i, ctx.constantInt(1, type: i32), name: "next")
    builder.buildBr(loop)
    i.addIncoming(next, from: body)

    builder.positionAtEnd(of: done)
    builder.buildRet(i)

    let ir = module.irString
    #expect(ir.contains("phi"))
    #expect(ir.contains("icmp slt"))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)loop_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)loop_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func globalVariable() throws {
    let ctx = Context()
    let module = Module(name: "global", in: ctx)
    let i32 = ctx.int32

    let answer = module.addGlobal("answer", type: i32)
    answer.initializer = ctx.constantInt(42, type: i32)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let val = builder.buildLoad(i32, answer, name: "val")
    builder.buildRet(val)

    let ir = module.irString
    #expect(ir.contains("@answer = global i32 42"))
    #expect(ir.contains("load i32"))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)global_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)global_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func irReaderRoundTrip() throws {
    let ctx = Context()
    let module = Module(name: "hello", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let ir = module.irString

    let ctx2 = Context()
    let parsed = try Module.parseIR(ir, in: ctx2)
    #expect(parsed.irString.contains("ret i32 42"))
}

@Test func bitcodeRoundTrip() throws {
    let ctx = Context()
    let module = Module(name: "bc", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let tmpDir = NSTemporaryDirectory()
    let bcPath = "\(tmpDir)bc_\(UUID().uuidString).bc"
    try module.writeBitcode(to: bcPath)
    defer { try? FileManager.default.removeItem(atPath: bcPath) }

    let ctx2 = Context()
    let parsed = try Module.parseBitcodeFile(bcPath, in: ctx2)
    #expect(parsed.irString.contains("ret i32 42"))
}

@Test(.disabled("LLVM ORC JIT crashes with glibc 2.44 tpp.c assertion on Arch Linux"))
func jitHelloWorld() throws {
    let ctx = Context()
    let module = Module(name: "jit", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let jit = try LLJIT()
    try jit.addModule(module)
    let result = try jit.runFunction("main")
    #expect(result == 42)
}

@Test(.disabled("LLVM ORC JIT crashes with glibc 2.44 tpp.c assertion on Arch Linux"))
func jitAddFunction() throws {
    let ctx = Context()
    let module = Module(name: "jitadd", in: ctx)
    let i32 = ctx.int32

    let addType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let addFunc = module.addFunction("add", type: addType)
    let addEntry = addFunc.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: addEntry)
    builder.buildRet(builder.buildAdd(addFunc.parameter(at: 0), addFunc.parameter(at: 1), name: "sum"))

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let mainEntry = main.appendBasicBlock("entry")
    builder.positionAtEnd(of: mainEntry)
    builder.buildRet(builder.buildCall(addFunc, [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)], name: "result"))

    let jit = try LLJIT()
    try jit.addModule(module)
    let result = try jit.runFunction("main")
    #expect(result == 42)
}

@Test func debugInfo() throws {
    let ctx = Context()
    let module = Module(name: "debug", in: ctx)
    let i32 = ctx.int32

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )

    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)
    let subType = di.createSubroutineType(file: file, returnTypes: [intType])

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let subprogram = di.createFunction(
        scope: cu,
        name: "main",
        file: file,
        line: 1,
        subroutineType: subType,
        isLocalToUnit: true,
        isDefinition: true,
        scopeLine: 1
    )
    main.setSubprogram(subprogram)

    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DICompileUnit"))
    #expect(ir.contains("!DIFile"))
    #expect(ir.contains("!DISubprogram"))
}

@Test func passManagerAnalysis() throws {
    let ctx = Context()
    let module = Module(name: "pm", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let pm = PassManager()
    pm.addAnalysisPasses(of: tm)
    pm.run(on: module)
}

@Test func moduleLinking() throws {
    let ctx = Context()
    let module = Module(name: "dest", in: ctx)
    let i32 = ctx.int32
    let mainType = ctx.functionType(returnType: i32)

    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(builder.buildCall(module.addFunction("helper", type: mainType), [], name: "r"))

    let source = Module(name: "src", in: ctx)
    let helper = source.addFunction("helper", type: mainType)
    let helperEntry = helper.appendBasicBlock("entry")
    builder.positionAtEnd(of: helperEntry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    try module.link(source)
    #expect(module.irString.contains("define i32 @helper()"))
    #expect(module.irString.contains("call i32 @helper"))
}

@Test func comdatAndAttribute() throws {
    let ctx = Context()
    let module = Module(name: "comdat", in: ctx)
    let i32 = ctx.int32

    let comdat = module.getOrInsertComdat("mycomdat")
    comdat.selectionKind = LLVMAnyComdatSelectionKind

    let answer = module.addGlobal("answer", type: i32)
    answer.initializer = ctx.constantInt(42, type: i32)
    answer.comdat = comdat

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    main.addAttribute(.enumAttribute(10, in: ctx), at: AttributeIndex.functionIndex)
    main.addAttribute(.stringAttribute("noinline", in: ctx), at: AttributeIndex.functionIndex)

    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let ir = module.irString
    #expect(ir.contains("$mycomdat"))
    #expect(ir.contains("noinline"))
    #expect(ir.contains("#"))

    let attrs = main.attributes(at: AttributeIndex.functionIndex)
    #expect(attrs.contains { $0.isString && $0.stringKind == "noinline" })
}

@Test func dataLayout() throws {
    let ctx = Context()
    let module = Module(name: "dl", in: ctx)
    let i32 = ctx.int32

    let dl = DataLayout(string: "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128")
    module.dataLayout = dl

    #expect(module.dataLayout.string.contains("i64:64"))
    #expect(dl.sizeOfTypeInBits(i32) == 32)
    #expect(dl.storeSizeOfType(i32) == 4)
    #expect(dl.abiSizeOfType(i32) == 4)
    #expect(dl.abiAlignmentOfType(i32) == 4)
}

@Test func debugInfoTypes() throws {
    let ctx = Context()
    let module = Module(name: "ditypes", in: ctx)

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )

    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)
    let ptrType = di.createPointerType(intType, sizeInBits: 64)
    let constType = di.createQualifiedType(tag: 0x26, type: intType)
    let typedefType = di.createTypedef(type: intType, name: "myint", file: file, line: 1, scope: cu)
    let structType = di.createStructType(
        scope: cu,
        name: "Point",
        file: file,
        line: 2,
        sizeInBits: 64,
        alignInBits: 32,
        elements: [
            di.createMemberType(
                scope: cu, name: "x", file: file, line: 2,
                sizeInBits: 32, alignInBits: 32, offsetInBits: 0, type: intType
            )
        ]
    )
    let subType = di.createSubroutineType(file: file, returnTypes: [typedefType, structType])
    let subprogram = di.createFunction(
        scope: cu, name: "main", file: file, line: 1,
        subroutineType: subType, isLocalToUnit: true, isDefinition: true, scopeLine: 1
    )

    let i32 = ctx.int32
    let mainFunc = module.addFunction("main", type: ctx.functionType(returnType: i32))
    let entry = mainFunc.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))
    mainFunc.setSubprogram(subprogram)

    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DICompileUnit"))
    #expect(ir.contains("!DIDerivedType"))
    #expect(ir.contains("!DICompositeType"))
}

@Test func verifyModule() throws {
    let ctx = Context()
    let module = Module(name: "verify", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    try module.verify()
    #expect(main.verify())
}

@Test func disassembleCode() throws {
    let triple = TargetMachine.defaultTriple
    guard let disasm = Disassembler(triple: triple) else {
        Issue.record("failed to create disassembler")
        return
    }
    let bytes: [UInt8] = [0xb8, 0x2a, 0x00, 0x00, 0x00, 0xc3]
    let instructions = disasm.disassemble(bytes)
    #expect(instructions.count == 2)
    #expect(instructions[0].contains("42") || instructions[0].contains("eax"))
    #expect(instructions[1].contains("ret"))
}

@Test func executionEngine() throws {
    let ctx = Context()
    let module = Module(name: "ee", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let ee = try ExecutionEngine(module: module)
    let result = ee.runFunction(main)?.toInt(isSigned: false) ?? 0
    #expect(result == 42)
    #expect(ee.functionAddress("main") != 0)
}

@Test func objectFileRead() throws {
    let ctx = Context()
    let module = Module(name: "obj", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)obj_\(UUID().uuidString).o"
    try tm.emitToFile(module: module, objPath)
    defer { try? FileManager.default.removeItem(atPath: objPath) }

    let buffer = try MemoryBuffer.fromFile(objPath)
    let binary = try Binary(buffer: buffer)
    #expect(binary.type == LLVMBinaryTypeELF64L || binary.type == LLVMBinaryTypeELF64B)
    #expect(binary.sections().contains { $0.name.contains("text") })
    #expect(binary.symbols().contains { $0.name.contains("main") })
}

@Test func atomicAndAggregateInstructions() throws {
    let ctx = Context()
    let module = Module(name: "atomic", in: ctx)
    let i32 = ctx.int32
    let i64 = ctx.int64

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let a0 = main.parameter(at: 0)
    let a1 = main.parameter(at: 1)

    let ptr = builder.buildAlloca(i32, name: "ptr")
    builder.buildStore(ctx.constantInt(0, type: i32), to: ptr)
    builder.buildFence(ordering: LLVMAtomicOrderingSequentiallyConsistent)
    let old = builder.buildAtomicRMW(
        LLVMAtomicRMWBinOpAdd, ptr, ctx.constantInt(1, type: i32),
        ordering: LLVMAtomicOrderingSequentiallyConsistent
    )
    builder.buildStore(old, to: ptr)

    let agg = ctx.constantStruct([
        ctx.constantInt(7, type: i32),
        ctx.constantInt(9, type: i64)
    ])
    let i64val = builder.buildSExt(a0, to: i64, name: "wide")
    let inserted = builder.buildInsertValue(agg, i64val, index: 1, name: "agg")
    _ = builder.buildExtractValue(inserted, index: 1, name: "val")

    let vecType = ctx.vectorType(elementType: i32, count: 4)
    let vec = ctx.undef(vecType)
    let zero = ctx.constantInt(0, type: i32)
    let insEl = builder.buildInsertElement(vec, a0, zero, name: "vec")
    let exEl = builder.buildExtractElement(insEl, a1, name: "el")
    let frozen = builder.buildFreeze(exEl, name: "frozen")

    builder.buildRet(frozen)

    let ir = module.irString
    #expect(ir.contains("fence seq_cst"))
    #expect(ir.contains("atomicrmw add"))
    #expect(ir.contains("insertvalue"))
    #expect(ir.contains("extractvalue"))
    #expect(ir.contains("insertelement"))
    #expect(ir.contains("extractelement"))
    #expect(ir.contains("freeze"))

    try module.verify()
}

@Test func debugGlobalVariable() throws {
    let ctx = Context()
    let module = Module(name: "dbgglobal", in: ctx)
    let i32 = ctx.int32

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )
    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)

    let expr = di.createExpression([])
    let gve = di.createGlobalVariableExpression(
        scope: cu,
        name: "answer",
        file: file,
        line: 1,
        type: intType,
        isLocalToUnit: true,
        expr: expr
    )

    let global = module.addGlobal("answer", type: i32)
    global.initializer = ctx.constantInt(42, type: i32)
    global.addDebugInfo(gve)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let subType = di.createSubroutineType(file: file, returnTypes: [intType])
    let subprogram = di.createFunction(
        scope: cu, name: "main", file: file, line: 1,
        subroutineType: subType, isLocalToUnit: true, isDefinition: true, scopeLine: 1
    )
    main.setSubprogram(subprogram)

    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DIGlobalVariable"))
    #expect(ir.contains("!DIGlobalVariableExpression"))
    #expect(ir.contains("!DIExpression"))
}

@Test func dbgValueRecordAndNamedMetadata() throws {
    let ctx = Context()
    let module = Module(name: "dbgval", in: ctx)
    let i32 = ctx.int32

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )
    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)

    let localVar = di.createParameterVariable(
        scope: cu, name: "x", argNo: 1, file: file, line: 1, type: intType
    )
    let loc = di.createDebugLocation(line: 2, column: 3, scope: cu)
    di.insertDbgValueRecordAtEnd(
        main.parameter(at: 0),
        diVar: localVar,
        expr: di.createExpression([]),
        location: loc,
        block: entry
    )
    builder.buildRet(ctx.constantInt(42, type: i32))

    let subType = di.createSubroutineType(file: file, returnTypes: [intType])
    let subprogram = di.createFunction(
        scope: cu, name: "main", file: file, line: 1,
        subroutineType: subType, isLocalToUnit: true, isDefinition: true, scopeLine: 1
    )
    main.setSubprogram(subprogram)
    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DILocalVariable"))
    #expect(ir.contains("!DILocation"))

    module.addNamedMetadataOperand("llvm.module.flags", ctx.metadataAsValue(ctx.mdNode([])))
    #expect(module.namedMetadataOperandCount("llvm.module.flags") == 1)
    #expect(module.namedMetadataOperands("llvm.module.flags").count == 1)
    #expect(module.irString.contains("llvm.module.flags"))
}

@Test func executionEngineExtensions() throws {
    let ctx = Context()
    let module = Module(name: "eeext", in: ctx)
    let i32 = ctx.int32

    let answer = module.addGlobal("answer", type: i32)
    answer.initializer = ctx.constantInt(7, type: i32)

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(main.parameter(at: 0))

    TargetMachine.initializeAllTargets()
    let ee = try ExecutionEngine(module: module)

    #expect(ee.targetData.string.contains("i64:64"))
    #expect(ee.targetMachine.ref != nil)
    #expect(ee.globalValueAddress("answer") != 0)
    let result = ee.runFunctionAsMain(main, args: ["prog", "42"], env: [])
    #expect(result == 2)
}

@Test func indirectBranchInstruction() throws {
    let ctx = Context()
    let module = Module(name: "indirectbr", in: ctx)
    let i32 = ctx.int32

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let a = main.parameter(at: 0)

    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let aPtr = builder.buildIntToPtr(a, to: ctx.pointerType(), name: "ap")
    let indirect = builder.buildIndirectBr(aPtr, numDests: 2)
    let dest1 = main.appendBasicBlock("dest1")
    let dest2 = main.appendBasicBlock("dest2")
    indirect.addDestination(dest1)
    indirect.addDestination(dest2)

    builder.positionAtEnd(of: dest1)
    builder.buildRet(ctx.constantInt(1, type: i32))

    builder.positionAtEnd(of: dest2)
    builder.buildRet(ctx.constantInt(2, type: i32))

    let ir = module.irString
    #expect(ir.contains("indirectbr"))
    try module.verify()
}

@Test func ehPadInstructions() throws {
    let ctx = Context()
    let module = Module(name: "eh", in: ctx)
    let i32 = ctx.int32

    let personalityType = ctx.functionType(returnType: ctx.int32, parameterTypes: [i32, ctx.pointerType(), ctx.pointerType()])
    let personality = module.addFunction("__gxx_personality_v0", type: personalityType)
    let fooType = ctx.functionType(returnType: ctx.void)
    let foo = module.addFunction("foo", type: fooType)
    let fooEntry = foo.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: fooEntry)
    builder.buildRetVoid()

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    main.personality = personality
    let entry = main.appendBasicBlock("entry")
    let cont = main.appendBasicBlock("cont")
    let pad = main.appendBasicBlock("pad")
    let handler = main.appendBasicBlock("handler")

    builder.positionAtEnd(of: entry)
    builder.buildInvoke(foo, [], then: cont, catch: pad)

    builder.positionAtEnd(of: pad)
    let cs = builder.buildCatchSwitch(parentPad: nil, unwind: nil, name: "cs")
    cs.addHandler(handler)

    builder.positionAtEnd(of: handler)
    let cp = builder.buildCatchPad(parentPad: cs, name: "cp")
    builder.buildCatchRet(cp, to: cont)

    builder.positionAtEnd(of: cont)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let cleanupFuncType = ctx.functionType(returnType: i32)
    let cleanupFunc = module.addFunction("cleanup_test", type: cleanupFuncType)
    cleanupFunc.personality = personality
    let ce = cleanupFunc.appendBasicBlock("entry")
    let ccont = cleanupFunc.appendBasicBlock("cont")
    let cpad = cleanupFunc.appendBasicBlock("pad")
    builder.positionAtEnd(of: ce)
    builder.buildInvoke(foo, [], then: ccont, catch: cpad)
    builder.positionAtEnd(of: cpad)
    let cp2 = builder.buildCleanupPad(parentPad: nil, name: "cp2")
    builder.buildCleanupRet(cp2, to: nil)
    builder.positionAtEnd(of: ccont)
    builder.buildRet(ctx.constantInt(0, type: i32))

    let ir = module.irString
    #expect(ir.contains("invoke"))
    #expect(ir.contains("catchswitch"))
    #expect(ir.contains("catchpad"))
    #expect(ir.contains("catchret"))
    #expect(ir.contains("cleanuppad"))
    #expect(ir.contains("cleanupret"))
    try module.verify()
}

@Test func traversalAndQueries() throws {
    let ctx = Context()
    let module = Module(name: "traverse", in: ctx)
    let i32 = ctx.int32

    let addType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let add = module.addFunction("add", type: addType)
    let entry = add.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let sum = builder.buildAdd(add.parameter(at: 0), add.parameter(at: 1), name: "sum")
    builder.buildRet(sum)

    #expect(add.basicBlockCount == 1)
    #expect(add.basicBlocks.count == 1)
    #expect(add.parameters.count == 2)
    #expect(entry.name == "entry")

    let instructions = entry.instructions
    #expect(instructions.count == 2)
    #expect(instructions[0] is BinaryOperator)
    #expect(instructions[1] is ReturnInst)
    #expect(entry.firstInstruction is BinaryOperator)
    #expect(entry.terminator is ReturnInst)

    #expect(sum.isConstant == false)
    #expect(sum.valueKind == LLVMInstructionValueKind)
    #expect(ctx.constantInt(42, type: i32).isConstant)
    #expect(ctx.constantNull(i32).isNull)
    #expect(ctx.undef(i32).isUndef)
}

@Test func constantExpressions() throws {
    let ctx = Context()
    let module = Module(name: "constexpr", in: ctx)
    let i32 = ctx.int32
    let i8 = ctx.int8

    let str = ctx.constantString("hello")
    #expect(str.isConstant)
    #expect(ctx.constantReal(ofString: "3.5", type: ctx.double).doubleValue == 3.5)

    let five = ctx.constantInt(5, type: i32)
    let three = ctx.constantInt(3, type: i32)
    let eight = ctx.constantAdd(five, three)
    #expect((eight as! ConstantInt).unsignedValue == 8)
    let two = ctx.constantSub(five, three)
    #expect((two as! ConstantInt).unsignedValue == 2)
    let neg = ctx.constantNeg(five)
    #expect((neg as! ConstantInt).signedValue == -5)

    let truncated = ctx.constantTrunc(five, to: i8)
    #expect((truncated as! ConstantInt).unsignedValue == 5)
    let bitcast = ctx.constantBitCast(five, to: ctx.float)
    #expect(bitcast.isConstant)

    let i8Ptr = ctx.pointerType()
    let intToPtr = ctx.constantIntToPtr(five, to: i8Ptr)
    #expect(intToPtr.isConstant)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(two)
    try module.verify()
}

@Test func callBrInstruction() throws {
    let ctx = Context()
    let module = Module(name: "callbr", in: ctx)
    let i32 = ctx.int32

    let asmType = ctx.functionType(returnType: ctx.void)
    let asm = ctx.constantInlineAsm(asmType, asmString: "", constraints: "!i", hasSideEffects: false, isAlignStack: false)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let normal = main.appendBasicBlock("normal")
    let indirect = main.appendBasicBlock("indirect")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let callBr = builder.buildCallBr(asm, args: [], default: normal, indirectDests: [indirect], bundles: [OperandBundle(tag: "deopt", args: [ctx.constantInt(0, type: i32)])])
    builder.positionAtEnd(of: normal)
    builder.buildRet(ctx.constantInt(0, type: i32))
    builder.positionAtEnd(of: indirect)
    builder.buildRet(ctx.constantInt(1, type: i32))

    #expect(callBr is CallBrInst)
    let ir = module.irString
    #expect(ir.contains("callbr"))
    #expect(ir.contains("asm"))
    #expect(ir.contains("\"deopt\""))

    let bundles = callBr.operandBundles
    #expect(bundles.count == 1)
    #expect(bundles[0].tag == "deopt")
    #expect(bundles[0].args.count == 1)
    try module.verify()
}

@Test func valueOperations() throws {
    let ctx = Context()
    let module = Module(name: "values", in: ctx)
    let i32 = ctx.int32

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let lhs = main.parameter(at: 0)
    let rhs = main.parameter(at: 1)
    let sum = builder.buildAdd(lhs, rhs, name: "sum")
    let ret = builder.buildRet(sum)

    #expect(sum.numOperands == 2)
    #expect(sum.operand(at: 0)?.ref == lhs.ref)
    #expect(sum.operand(at: 1)?.ref == rhs.ref)
    #expect(ret.numOperands == 1)
    #expect(ret.operand(at: 0)?.ref == sum.ref)

    let three = ctx.constantInt(3, type: i32)
    sum.replaceAllUsesWith(three)
    let terminator = entry.terminator!
    #expect(terminator.operand(at: 0)?.ref == three.ref)
    let ir = module.irString
    #expect(ir.contains("ret i32 3"))
    try module.verify()
}

@Test func constantDataArrayAndExpressions() throws {
    let ctx = Context()
    let module = Module(name: "constdata", in: ctx)
    let i32 = ctx.int32
    let i8 = ctx.int8

    let str = ctx.constantDataArray(bytes: [104, 101, 108, 108, 111], type: i8)
    #expect(str.isConstantString)
    #expect(str.stringValue == "hello")
    #expect((str.aggregateElement(at: 0) as? ConstantInt)?.unsignedValue == 104)

    let ints = ctx.constantDataArray(bytes: [1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0], type: i32)
    #expect(!ints.isConstantString)
    #expect(ints.stringValue == nil)
    #expect(ints.rawData.count == 12)
    #expect((ints.aggregateElement(at: 2) as? ConstantInt)?.unsignedValue == 3)

    let five = ctx.constantInt(5, type: i32)
    let three = ctx.constantInt(3, type: i32)
    let notFive = ctx.constantNot(five)
    #expect((notFive as! ConstantInt).signedValue == -6)
    let xorResult = ctx.constantXor(five, three)
    #expect((xorResult as! ConstantInt).unsignedValue == 6)
    let allOnes = ctx.constantAllOnes(i32)
    #expect((allOnes as! ConstantInt).unsignedValue == 0xFFFFFFFF)
    let nullPtr = ctx.constantPointerNull(ctx.pointerType())
    #expect(nullPtr.isNull)
    let truncated = ctx.constantTruncOrBitCast(five, to: i8)
    #expect((truncated as! ConstantInt).unsignedValue == 5)
    #expect(ctx.constantInt(ofString: "42", type: i32).unsignedValue == 42)
    #expect(ctx.constantInt(ofString: "0x2a", type: i32).unsignedValue == 42)
    #expect(ctx.constantInt(ofString: "0b101010", type: i32).unsignedValue == 42)
    #expect(ctx.constantInt(ofString: "052", type: i32, radix: 8).unsignedValue == 42)
    #expect(ctx.constantInt(ofString: "2a", type: i32, radix: 16).unsignedValue == 42)

    let vector = ctx.constantVector([five, three])
    #expect(vector.isConstant)
    #expect(vector.aggregateElement(at: 1)?.ref == three.ref)

    let element = ctx.constantExtractElement(vector, ctx.constantInt(0, type: i32))
    #expect(element.isConstant)
    let mask = ctx.constantVector([ctx.constantInt(0, type: i32), ctx.constantInt(1, type: i32)])
    let shuffled = ctx.constantShuffleVector(vector, vector, mask: mask)
    #expect(shuffled.isConstant)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let ba = ctx.blockAddress(function: main, block: entry)
    #expect(ba is BlockAddress)
    #expect(ba.function?.name == "main")
    #expect(ba.basicBlock?.name == "entry")
}

@Test func globalQueries() throws {
    let ctx = Context()
    let module = Module(name: "globals", in: ctx)
    let i32 = ctx.int32

    let counter = module.addGlobal("counter", type: i32)
    let flag = module.addGlobal("flag", type: ctx.int1)

    #expect(module.globals.count == 2)
    #expect(module.global(named: "counter")?.ref == counter.ref)
    #expect(module.global(named: "flag")?.ref == flag.ref)
    #expect(module.global(named: "missing") == nil)
    #expect(counter.parentModule.ref == module.ref)
}

@Test func callBrAsmGoto() throws {
    let ctx = Context()
    let module = Module(name: "callbrasm", in: ctx)
    let i32 = ctx.int32

    let asmType = ctx.functionType(returnType: ctx.void, parameterTypes: [ctx.pointerType()])
    let asm = ctx.constantInlineAsm(asmType, asmString: "jmp ${0:l}", constraints: "X,!i", hasSideEffects: true, isAlignStack: false)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let normal = main.appendBasicBlock("normal")
    let indirect = main.appendBasicBlock("indirect")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let ba = ctx.blockAddress(function: main, block: indirect)
    let callBr = builder.buildCallBr(asm, args: [ba], default: normal, indirectDests: [indirect])
    builder.positionAtEnd(of: normal)
    builder.buildRet(ctx.constantInt(0, type: i32))
    builder.positionAtEnd(of: indirect)
    builder.buildRet(ctx.constantInt(1, type: i32))

    #expect(callBr is CallBrInst)
    let ir = module.irString
    #expect(ir.contains("callbr"))
    #expect(ir.contains("asm sideeffect"))
    #expect(ir.contains("blockaddress"))
    try module.verify()
}

@Test func callInstructionAttributes() throws {
    let ctx = Context()
    let module = Module(name: "callattrs", in: ctx)
    let i32 = ctx.int32

    let calleeType = ctx.functionType(returnType: i32)
    let callee = module.addFunction("callee", type: calleeType)
    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let call = builder.buildCall(callee, [], name: "c")
    builder.buildRet(call)

    #expect(!call.isTailCall)
    #expect(call.callConvention == LLVMCCallConv)
    call.isTailCall = true
    #expect(call.isTailCall)
    #expect(call.tailCallKind == LLVMTailCallKindTail)
    call.callConvention = LLVMFastCallConv
    #expect(call.callConvention == LLVMFastCallConv)
    let ir = module.irString
    #expect(ir.contains("tail call"))
    #expect(ir.contains("fastcc"))
    try module.verify()
}

@Test func globalAliasAndIFunc() throws {
    let ctx = Context()
    let module = Module(name: "aliasifunc", in: ctx)
    let i32 = ctx.int32

    let targetType = ctx.functionType(returnType: i32)
    let target = module.addFunction("target", type: targetType)
    let targetBuilder = Builder(in: ctx)
    targetBuilder.positionAtEnd(of: target.appendBasicBlock("entry"))
    targetBuilder.buildRet(ctx.constantInt(0, type: i32))
    let alias = module.addAlias("alias", type: targetType, aliasee: target)
    #expect(alias.aliasee?.ref == target.ref)
    #expect(module.alias(named: "alias")?.ref == alias.ref)
    #expect(module.alias(named: "missing") == nil)
    #expect(module.aliases.count == 1)

    let resolverType = ctx.functionType(returnType: ctx.pointerType())
    let resolver = module.addFunction("resolver", type: resolverType)
    let resolverBuilder = Builder(in: ctx)
    resolverBuilder.positionAtEnd(of: resolver.appendBasicBlock("entry"))
    resolverBuilder.buildRet(ctx.constantPointerNull(ctx.pointerType()))
    let ifunc = module.addIFunc("ifunc", type: targetType, resolver: resolver)
    #expect(ifunc.resolver?.ref == resolver.ref)
    #expect(module.ifunc(named: "ifunc")?.ref == ifunc.ref)
    #expect(module.ifuncs.count == 1)

    let ir = module.irString
    #expect(ir.contains("@alias"))
    #expect(ir.contains("@ifunc"))
    try module.verify()
}

@Test func moduleQueries() throws {
    let ctx = Context()
    let module = Module(name: "queries", in: ctx)
    let i32 = ctx.int32
    let voidType = ctx.functionType(returnType: ctx.void)

    let a = module.addFunction("a", type: voidType)
    let b = module.addFunction("b", type: voidType)
    let c = module.addFunction("c", type: ctx.functionType(returnType: i32))

    #expect(module.functions.count == 3)
    #expect(module.function(named: "a")?.ref == a.ref)
    #expect(module.function(named: "b")?.ref == b.ref)
    #expect(module.function(named: "c")?.ref == c.ref)
    #expect(module.function(named: "missing") == nil)
}

@Test func valueUses() throws {
    let ctx = Context()
    let module = Module(name: "uses", in: ctx)
    let i32 = ctx.int32

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let param = main.parameter(at: 0)
    let sum = builder.buildAdd(param, ctx.constantInt(1, type: i32), name: "sum")
    builder.buildRet(sum)

    #expect(param.uses.count == 1)
    #expect(param.uses[0].ref == sum.ref)
    #expect(sum.uses.count == 1)
    #expect(sum.uses[0].ref == entry.terminator!.ref)

    let three = ctx.constantInt(3, type: i32)
    sum.replaceAllUsesWith(three)
    #expect(sum.uses.isEmpty)
    #expect(entry.terminator!.operand(at: 0)?.ref == three.ref)
    #expect(param.uses.count == 1)
    #expect(param.uses[0].ref == sum.ref)
}

@Test func invokeLandingPadResume() throws {
    let ctx = Context()
    let module = Module(name: "invoke", in: ctx)
    let i32 = ctx.int32
    let voidFn = ctx.functionType(returnType: ctx.void)
    let callee = module.addFunction("callee", type: voidFn)
    let person = module.addFunction("person", type: voidFn)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    main.personality = person
    let entry = main.appendBasicBlock("entry")
    let normal = main.appendBasicBlock("normal")
    let lpadBlock = main.appendBasicBlock("lpad")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let inv = builder.buildInvoke(callee, [], then: normal, catch: lpadBlock)
    builder.positionAtEnd(of: normal)
    builder.buildRet(ctx.constantInt(0, type: i32))
    builder.positionAtEnd(of: lpadBlock)
    let lpType = ctx.structType(elementTypes: [ctx.pointerType(), i32])
    let lp = builder.buildLandingPad(lpType, personality: person, numClauses: 1, name: "lp")
    lp.addClause(ctx.constantPointerNull(ctx.pointerType()))
    lp.isCleanup = true
    builder.buildResume(lp)

    #expect(inv is InvokeInst)
    #expect(lp is LandingPadInst)
    #expect(lp.clauseCount == 1)
    #expect(lp.isCleanup)
    #expect(main.personality?.ref == person.ref)
    let ir = module.irString
    #expect(ir.contains("invoke"))
    #expect(ir.contains("landingpad"))
    #expect(ir.contains("resume"))
    try module.verify()
}

@Test func callSiteAttributesAndCalledValue() throws {
    let ctx = Context()
    let module = Module(name: "callattr2", in: ctx)
    let i32 = ctx.int32
    let calleeType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let callee = module.addFunction("callee", type: calleeType)
    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let call = builder.buildCall(callee, [main.parameter(at: 0)], name: "c")
    builder.buildRet(call)

    #expect(call.calledValue?.ref == callee.ref)
    #expect(call.calledFunctionType?.ref == calleeType.ref)

    let attr = Attribute.stringAttribute("noinline", in: ctx)
    call.addCallSiteAttribute(attr, at: AttributeIndex.functionIndex)
    let attrs = call.callSiteAttributes(at: AttributeIndex.functionIndex)
    #expect(attrs.count == 1)
    #expect(attrs[0].isString)
    let ir = module.irString
    #expect(ir.contains("noinline"))
    try module.verify()
}

@Test func globalVariableAttributes() throws {
    let ctx = Context()
    let module = Module(name: "gvattrs", in: ctx)
    let i32 = ctx.int32
    let gv = module.addGlobal("g", type: i32)

    gv.initializer = ctx.constantInt(7, type: i32)
    #expect((gv.initializer as? ConstantInt)?.unsignedValue == 7)
    gv.section = ".data"
    #expect(gv.section == ".data")
    gv.isThreadLocal = true
    #expect(gv.isThreadLocal)
    gv.unnamedAddress = LLVMGlobalUnnamedAddr
    #expect(gv.unnamedAddress == LLVMGlobalUnnamedAddr)

    let ir = module.irString
    #expect(ir.contains("thread_local"))
    #expect(ir.contains(".data"))
    #expect(ir.contains("unnamed_addr"))
    try module.verify()
}

@Test func moduleMetadata() throws {
    let ctx = Context()
    let module = Module(name: "orig", in: ctx)

    #expect(module.identifier == "orig")
    module.identifier = "renamed"
    #expect(module.identifier == "renamed")
    module.sourceFileName = "src.c"
    #expect(module.sourceFileName == "src.c")
    module.inlineAsm = "nop"
    #expect(module.inlineAsm.contains("nop"))

    let ir = module.irString
    #expect(ir.contains("module asm"))
    #expect(ir.contains("nop"))
}

@Test func instructionTraversal() throws {
    let ctx = Context()
    let module = Module(name: "insts", in: ctx)
    let i32 = ctx.int32
    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let param = main.parameter(at: 0)
    let alloca = builder.buildAlloca(i32, name: "a")
    let add = builder.buildAdd(param, ctx.constantInt(1, type: i32), name: "s")
    let ret = builder.buildRet(add)

    #expect(entry.firstInstruction?.ref == alloca.ref)
    #expect(entry.lastInstruction?.ref == ret.ref)
    let insts = entry.instructions
    #expect(insts.count == 3)
    #expect(insts[0].ref == alloca.ref)
    #expect(insts[1].ref == add.ref)
    #expect(insts[2].ref == ret.ref)
}
}

