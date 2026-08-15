import cLLVM
import Foundation
@testable import LLVMSwiftBinding
import Testing

private func resolveExecutable(_ name: String) -> String {
    guard let path = ProcessInfo.processInfo.environment["PATH"] else { return name }
    for dir in path.split(separator: ":") {
        let candidate = URL(fileURLWithPath: String(dir)).appendingPathComponent(name).path
        if FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }
    }
    return name
}

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
        linkProcess.executableURL = URL(fileURLWithPath: resolveExecutable("cc"))
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
        let result = builder.buildCall(
            addFunc,
            [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)],
            name: "result"
        )
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
        linkProcess.executableURL = URL(fileURLWithPath: resolveExecutable("cc"))
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
        let cond = builder.buildICmp(.SLT, i, ctx.constantInt(42, type: i32), name: "cond")
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
        linkProcess.executableURL = URL(fileURLWithPath: resolveExecutable("cc"))
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
        linkProcess.executableURL = URL(fileURLWithPath: resolveExecutable("cc"))
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

    @Test
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
        #expect(jit.globalPrefix == Character(UnicodeScalar(0)))
        #expect(jit.triple.hasPrefix("x86_64"))
        try jit.enableDebugSupport()
        try jit.addModule(module)
        let address = try jit.lookup("main")
        let fn = unsafeBitCast(UInt(address), to: (@convention(c) () -> Int32).self)
        let result = fn()
        #expect(result == 42)
    }

    @Test
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
        builder.buildRet(builder.buildCall(
            addFunc,
            [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)],
            name: "result"
        ))

        let jit = try LLJIT()
        try jit.addModule(module)
        let address = try jit.lookup("main")
        let fn = unsafeBitCast(UInt(address), to: (@convention(c) () -> Int32).self)
        let result = fn()
        #expect(result == 42)
    }

    @Test func buildCallWithValueCallee() throws {
        let ctx = Context()
        let module = Module(name: "call", in: ctx)
        let i32 = ctx.int32
        let addType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
        let add = module.addFunction("add", type: addType)
        let addEntry = add.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: addEntry)
        builder.buildRet(builder.buildAdd(add.parameter(at: 0), add.parameter(at: 1), name: "sum"))

        let mainType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: mainType)
        let mainEntry = main.appendBasicBlock("entry")
        builder.positionAtEnd(of: mainEntry)
        let callee: Value = add
        let result = builder.buildCall(
            callee,
            type: addType,
            [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)],
            name: "r"
        )
        builder.buildRet(result)

        try module.verify()
        let ir = module.irString
        #expect(ir.contains("call i32 @add"))
    }

    @Test func builderSupplementaryOps() throws {
        let ctx = Context()
        let module = Module(name: "bops", in: ctx)
        let i32 = ctx.int32
        let main = module.addFunction("main", type: ctx.functionType(returnType: i32, parameterTypes: [i32]))
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)

        let x = main.parameter(at: 0)
        let neg = builder.buildNeg(x, name: "neg")
        let not = builder.buildNot(x, name: "not")
        let isNull = builder.buildIsNull(x, name: "isnull")
        builder.buildIsNotNull(x, name: "isnotnull")
        let bin = builder.buildBinOp(.And, x, ctx.constantInt(1, type: i32), name: "binop")
        let cast = builder.buildCast(.ZExt, isNull, to: i32, name: "cast")
        let sum = builder.buildAdd(
            builder.buildAdd(neg, not, name: "a"),
            builder.buildAdd(bin, cast, name: "b"),
            name: "sum"
        )
        builder.buildRet(sum)

        try module.verify()
        let ir = module.irString
        #expect(ir.contains("sub i32 0"))
        #expect(ir.contains("xor i32"))
        #expect(ir.contains("icmp eq i32"))
        #expect(ir.contains("icmp ne i32"))
        #expect(ir.contains("and i32"))
        #expect(ir.contains("zext i1"))
    }

    @Test func builderGEPAndStrings() throws {
        let ctx = Context()
        let module = Module(name: "geps", in: ctx)
        let i32 = ctx.int32
        let i8 = ctx.int8
        let pair = ctx.structType(elementTypes: [i32, i8])
        let main = module.addFunction("main", type: ctx.functionType(returnType: i32))
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)

        let alloca = builder.buildAlloca(pair, name: "p")
        let zero = ctx.constantInt(0, type: i32)
        let one = ctx.constantInt(1, type: i32)
        let fieldPtr = builder.buildStructGEP(pair, alloca, index: 1, name: "fp")
        let field = builder.buildLoad(i8, fieldPtr, name: "f")
        _ = builder.buildInBoundsGEP(pair, alloca, indices: [zero, one], name: "g")
        _ = builder.buildGEPWithNoWrapFlags(pair, alloca, indices: [zero], noWrapFlags: [.InBounds], name: "gf")
        _ = builder.buildPtrDiff(i32, alloca, alloca, name: "pd")
        let arr = builder.buildArrayAlloca(i32, size: ctx.constantInt(8, type: i32), name: "arr")
        _ = builder.buildInBoundsGEP(i32, arr, indices: [ctx.constantInt(2, type: i32)], name: "ap")
        _ = builder.buildGlobalString("hi", name: "msg")
        _ = builder.buildGlobalStringPtr("hi2", name: "msg2")

        let ext = builder.buildZExt(field, to: i32, name: "e")
        builder.buildRet(ext)

        try module.verify()
        let ir = module.irString
        #expect(ir.contains("getelementptr inbounds"))
        #expect(ir.contains("@msg"))
        #expect(ir.contains("@msg2"))
        #expect(ir.contains("alloca i32, i32 8"))
    }

    @Test func builderCallWithOperandBundlesEmpty() throws {
        let ctx = Context()
        let module = Module(name: "cb", in: ctx)
        let i32 = ctx.int32
        let fnType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let fn = module.addFunction("f", type: fnType)
        let fEntry = fn.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: fEntry)
        builder.buildRet(fn.parameter(at: 0))

        let main = module.addFunction("main", type: ctx.functionType(returnType: i32))
        let mEntry = main.appendBasicBlock("entry")
        builder.positionAtEnd(of: mEntry)
        let callee: Value = fn
        let result = builder.buildCallWithOperandBundles(
            callee,
            type: fnType,
            [ctx.constantInt(7, type: i32)],
            bundles: [],
            name: "r"
        )
        builder.buildRet(result)

        try module.verify()
        #expect(module.irString.contains("call i32 @f"))
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
        comdat.selectionKind = .Any

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
                ),
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
        let bytes: [UInt8] = [0xB8, 0x2A, 0x00, 0x00, 0x00, 0xC3]
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
        builder.buildFence(ordering: .SequentiallyConsistent)
        let old = builder.buildAtomicRMW(
            .Add, ptr, ctx.constantInt(1, type: i32),
            ordering: .SequentiallyConsistent
        )
        builder.buildStore(old, to: ptr)

        let agg = ctx.constantStruct([
            ctx.constantInt(7, type: i32),
            ctx.constantInt(9, type: i64),
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

        let personalityType = ctx.functionType(
            returnType: ctx.int32,
            parameterTypes: [i32, ctx.pointerType(), ctx.pointerType()]
        )
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
        #expect(sum.valueKind == .Instruction)
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
        let asm = ctx.constantInlineAsm(
            asmType,
            asmString: "",
            constraints: "!i",
            hasSideEffects: false,
            isAlignStack: false
        )

        let mainType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let normal = main.appendBasicBlock("normal")
        let indirect = main.appendBasicBlock("indirect")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let callBr = builder.buildCallBr(
            asm,
            args: [],
            default: normal,
            indirectDests: [indirect],
            bundles: [OperandBundle(tag: "deopt", args: [ctx.constantInt(0, type: i32)])]
        )
        builder.positionAtEnd(of: normal)
        builder.buildRet(ctx.constantInt(0, type: i32))
        builder.positionAtEnd(of: indirect)
        builder.buildRet(ctx.constantInt(1, type: i32))

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
        #expect((allOnes as! ConstantInt).unsignedValue == 0xFFFF_FFFF)
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
        let asm = ctx.constantInlineAsm(
            asmType,
            asmString: "jmp ${0:l}",
            constraints: "X,!i",
            hasSideEffects: true,
            isAlignStack: false
        )

        let mainType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let normal = main.appendBasicBlock("normal")
        let indirect = main.appendBasicBlock("indirect")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let ba = ctx.blockAddress(function: main, block: indirect)
        builder.buildCallBr(asm, args: [ba], default: normal, indirectDests: [indirect])
        builder.positionAtEnd(of: normal)
        builder.buildRet(ctx.constantInt(0, type: i32))
        builder.positionAtEnd(of: indirect)
        builder.buildRet(ctx.constantInt(1, type: i32))

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
        #expect(call.callConvention == .C)
        call.isTailCall = true
        #expect(call.isTailCall)
        #expect(call.tailCallKind == .Tail)
        call.callConvention = .Fast
        #expect(call.callConvention == .Fast)
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
        builder.buildInvoke(callee, [], then: normal, catch: lpadBlock)
        builder.positionAtEnd(of: normal)
        builder.buildRet(ctx.constantInt(0, type: i32))
        builder.positionAtEnd(of: lpadBlock)
        let lpType = ctx.structType(elementTypes: [ctx.pointerType(), i32])
        let lp = builder.buildLandingPad(lpType, personality: person, numClauses: 1, name: "lp")
        lp.addClause(ctx.constantPointerNull(ctx.pointerType()))
        lp.isCleanup = true
        builder.buildResume(lp)

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
        gv.unnamedAddress = .Global
        #expect(gv.unnamedAddress == .Global)

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

    @Test func typeSystemDetails() throws {
        let ctx = Context()
        let i32 = ctx.int32
        let ptr = ctx.pointerType()

        let named = ctx.namedStructType(name: "mystruct", elementTypes: [i32, ptr], isPacked: false)
        #expect(named.isStruct)
        #expect(!named.isOpaque)
        #expect(!named.isLiteral)
        #expect(named.name == "mystruct")
        #expect(named.elementCount == 2)
        #expect(named.elementType(at: 0).ref == i32.ref)
        #expect(named.elementType(at: 1).ref == ptr.ref)
        #expect(named.elementTypes.count == 2)

        let opaque = ctx.namedStructType(name: "opaque_struct")
        #expect(opaque.isOpaque)
        #expect(opaque.elementCount == 0)

        let literal = ctx.structType(elementTypes: [i32, i32], isPacked: true)
        #expect(literal.isLiteral)
        #expect(literal.isPacked)
        #expect(literal.name == nil)

        let vec = ctx.vectorType(elementType: i32, count: 4)
        #expect(vec.isVector)
        #expect(!vec.isScalable)
        #expect(vec.elementCount == 4)
        #expect(vec.elementType.ref == i32.ref)

        let scalable = ctx.scalableVectorType(elementType: i32, count: 4)
        #expect(scalable.isVector)
        #expect(scalable.isScalable)

        let array = ctx.arrayType(elementType: i32, count: 8)
        #expect(array.isArray)
        #expect(array.elementCount == 8)
        #expect(array.elementType.ref == i32.ref)

        let tet = ctx.targetExtType(name: "ptrauth", typeParams: [i32], intParams: [0, 1])
        #expect(tet.isTargetExt)
        #expect(tet.name == "ptrauth")
        #expect(tet.typeParameterCount == 1)
        #expect(tet.typeParameter(at: 0).ref == i32.ref)
        #expect(tet.intParameterCount == 2)
        #expect(tet.intParameter(at: 0) == 0)
        #expect(tet.intParameter(at: 1) == 1)

        #expect(i32.isInteger)
        #expect(ctx.void.isVoid)
        #expect(ctx.double.isFloat)
        #expect(ptr.isPointer)
        #expect(!i32.isPointer)
        #expect(i32.description == "i32")
        #expect(ctx.functionType(returnType: ctx.void).description == "void ()")
    }

    @Test func debugInfoEndToEnd() throws {
        let ctx = Context()
        let module = Module(name: "dbg", in: ctx)
        let i32 = ctx.int32
        let builder = Builder(in: ctx)
        let di = DIBuilder(module: module)

        let file = di.createFile("test.c", directory: "/tmp")
        let cu = di.createCompileUnit(language: LLVMDWARFSourceLanguageC, file: file, producer: "swift-binding")
        let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)
        let subType = di.createSubroutineType(file: file, returnTypes: [intType])
        let sp = di.createFunction(
            scope: cu,
            name: "main",
            linkageName: "main",
            file: file,
            line: 1,
            subroutineType: subType
        )

        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        main.setSubprogram(sp)
        let entry = main.appendBasicBlock("entry")
        builder.positionAtEnd(of: entry)

        let loc = di.createDebugLocation(line: 42, column: 7, scope: sp)
        builder.setCurrentDebugLocation(loc)
        #expect(builder.currentDebugLocation?.ref == loc.ref)

        let param = main.parameter(at: 0)
        let alloca = builder.buildAlloca(i32, name: "x")
        builder.buildStore(param, to: alloca)
        let ret = builder.buildRet(ctx.constantInt(0, type: i32))

        #expect(alloca.debugLocLine == 42)
        #expect(alloca.debugLocColumn == 7)
        #expect(alloca.debugLocFilename == "test.c")
        #expect(alloca.debugLocDirectory == "/tmp")
        #expect(ret.debugLocLine == 42)

        let autoVar = di.createAutoVariable(scope: sp, name: "x", file: file, line: 5, type: intType)
        let expr = di.createExpression([])
        di.insertDeclareAtEnd(alloca, diVar: autoVar, expr: expr, location: loc, block: entry)
        di.finalize()

        let ir = module.irString
        #expect(ir.contains("!dbg"))
        #expect(ir.contains("llvm.dbg"))
        try module.verify()
    }

    @Test func passBuilderRunPasses() throws {
        let ctx = Context()
        let module = Module(name: "passes", in: ctx)
        let i32 = ctx.int32

        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let zero = ctx.constantInt(0, type: i32)
        let x = builder.buildAdd(main.parameter(at: 0), zero, name: "x")
        builder.buildRet(x)

        let before = module.irString
        #expect(before.contains("%x = add"))

        let pm = PassManager()
        let options = PassBuilderOptions()
        options.setVerifyEach(true)
        options.setDebugLogging(false)
        try pm.runPasses("instcombine", on: module, options: options)

        let after = module.irString
        #expect(!after.contains("add"))
        try module.verify()
    }

    @Test func passBuilderRunPassesWithoutOptions() throws {
        let ctx = Context()
        let module = Module(name: "passes", in: ctx)
        let i32 = ctx.int32

        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let x = builder.buildAdd(main.parameter(at: 0), ctx.constantInt(0, type: i32), name: "x")
        builder.buildRet(x)

        let pm = PassManager()
        try pm.runPasses("instcombine", on: module)

        let after = module.irString
        #expect(!after.contains("add"))
        try module.verify()
    }

    @Test func constantsSupplementary() throws {
        let ctx = Context()
        let i32 = ctx.int32

        let poison = ctx.poison(i32)
        let undef = ctx.undef(i32)

        let fp = ctx.constantFP(ofString: "3.14", type: ctx.double)
        #expect(abs(fp.doubleValue - 3.14) < 0.001)

        let vector = ctx.constantVector([poison, undef])
        #expect(vector.aggregateElement(at: 1) is UndefValue)
    }

    @Test func executionEngineGlobals() throws {
        let ctx = Context()
        let module = Module(name: "eeglobals", in: ctx)
        let i32 = ctx.int32

        let gv = module.addGlobal("g", type: i32)
        gv.initializer = ctx.constantInt(7, type: i32)
        let mainType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let load = builder.buildLoad(i32, gv, name: "v")
        builder.buildRet(load)

        let ee = try ExecutionEngine(module: module)
        ee.runStaticConstructors()
        let result = ee.runFunction(main)?.toInt(isSigned: false) ?? 0
        #expect(result == 7)
        #expect(ee.pointerToGlobal(gv) != nil)
        #expect(ee.globalValueAddress("g") != 0)
        ee.runStaticDestructors()
    }

    @Test func valueUseIteration() throws {
        let ctx = Context()
        let module = Module(name: "useiter", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let p0 = main.parameter(at: 0)
        let p1 = main.parameter(at: 1)
        let sum = builder.buildAdd(p0, p1, name: "s")
        builder.buildRet(sum)

        #expect(p0.useCount == 1)
        #expect(p1.useCount == 1)
        #expect(sum.useCount == 1)
        #expect(sum.operandUser(at: 0)?.ref == sum.ref)
        #expect(sum.operandUser(at: 1)?.ref == sum.ref)
    }

    @Test func instructionOperations() throws {
        let ctx = Context()
        let module = Module(name: "instops", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let add = builder.buildAdd(main.parameter(at: 0), ctx.constantInt(1, type: i32), name: "a")
        let ret = builder.buildRet(add)

        #expect(add.parentBlock?.ref == entry.ref)
        #expect(ret.parentBlock?.ref == entry.ref)
        let cloned = add.clone()
        #expect(cloned != nil)
        #expect(cloned?.ref != add.ref)
        try module.verify()
    }

    @Test func moduleCloneAndBitcode() throws {
        let ctx = Context()
        let module = Module(name: "clone", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(main.parameter(at: 0))

        let cloned = module.clone()
        #expect(cloned.ref != module.ref)
        #expect(cloned.irString.contains("define i32 @main"))
        #expect(cloned.function(named: "main") != nil)

        let buf = module.writeBitcodeToMemoryBuffer()
        #expect(!buf.bytes.isEmpty)
        let restored = try Module.parseBitcode(buf.bytes, in: ctx)
        #expect(restored.function(named: "main") != nil)
        #expect(restored.irString.contains("define i32 @main"))
        try restored.verify()
    }

    @Test func metadataKinds() throws {
        let ctx = Context()
        let module = Module(name: "mdkinds", in: ctx)
        let di = DIBuilder(module: module)

        let file = di.createFile("f.c", directory: "/tmp")
        let cu = di.createCompileUnit(language: LLVMDWARFSourceLanguageC, file: file, producer: "p")
        let mdStr = ctx.mdString("hello")

        #expect(mdStr.kind == LLVMMDStringMetadataKind)
        #expect(file.kind == LLVMDIFileMetadataKind)
        #expect(cu.kind == LLVMDICompileUnitMetadataKind)
    }

    @Test func instructionInsertionAndDeletion() throws {
        let ctx = Context()
        let module = Module(name: "instinsdel", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let a = builder.buildAlloca(i32, name: "a")
        let ret = builder.buildRet(ctx.constantInt(0, type: i32))

        builder.positionBefore(ret)
        let x = builder.buildAdd(main.parameter(at: 0), ctx.constantInt(1, type: i32), name: "x")
        #expect(entry.instructions.count == 3)
        #expect(entry.instructions[1].ref == x.ref)

        x.removeFromParent()
        #expect(entry.instructions.count == 2)

        a.eraseFromParent()
        #expect(entry.instructions.count == 1)
        #expect(entry.firstInstruction?.ref == ret.ref)
        try module.verify()
    }

    @Test func switchAndPhiQueries() throws {
        let ctx = Context()
        let module = Module(name: "switchphi", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let defBlock = main.appendBasicBlock("def")
        let case0 = main.appendBasicBlock("case0")
        let case1 = main.appendBasicBlock("case1")
        let merge = main.appendBasicBlock("merge")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let sw = builder.buildSwitch(main.parameter(at: 0), default: defBlock, numCases: 2)
        sw.addCase(ctx.constantInt(0, type: i32), case0)
        sw.addCase(ctx.constantInt(1, type: i32), case1)

        builder.positionAtEnd(of: defBlock)
        builder.buildBr(merge)
        builder.positionAtEnd(of: case0)
        builder.buildBr(merge)
        builder.positionAtEnd(of: case1)
        builder.buildBr(merge)

        builder.positionAtEnd(of: merge)
        let phi = builder.buildPhi(i32, name: "p")
        phi.addIncoming(ctx.constantInt(1, type: i32), from: case0)
        phi.addIncoming(ctx.constantInt(2, type: i32), from: case1)
        phi.addIncoming(ctx.constantInt(3, type: i32), from: defBlock)
        builder.buildRet(phi)

        #expect(sw.caseCount == 2)
        #expect(sw.condition?.ref == main.parameter(at: 0).ref)
        #expect(sw.defaultDestination?.ref == defBlock.ref)
        #expect(sw.caseDestination(at: 0)?.ref == case0.ref)
        #expect(sw.caseDestination(at: 1)?.ref == case1.ref)

        #expect(phi.incomingCount == 3)
        #expect(phi.incomingValue(at: 0).ref == ctx.constantInt(1, type: i32).ref)
        #expect(phi.incomingBlock(at: 0)?.ref == case0.ref)
        #expect(phi.incomingBlock(at: 2)?.ref == defBlock.ref)
        try module.verify()
    }

    @Test func builderOverflowAndFNeg() throws {
        let ctx = Context()
        let module = Module(name: "overflow", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, ctx.double])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let p = main.parameter(at: 0)
        builder.buildNSWAdd(p, p, name: "nsw")
        builder.buildNUWSub(p, p, name: "nuw")
        builder.buildExactSDiv(p, ctx.constantInt(2, type: i32), name: "exact")
        builder.buildNSWNeg(p, name: "nswneg")
        builder.buildFNeg(main.parameter(at: 1), name: "fneg")
        builder.buildRet(p)

        let ir = module.irString
        #expect(ir.contains("nsw"))
        #expect(ir.contains("nuw"))
        #expect(ir.contains("exact"))
        #expect(ir.contains("fneg"))
        try module.verify()
    }

    @Test func constantAggregateZeroAndTypeContext() throws {
        let ctx = Context()
        let module = try Module.parseIR(
            "@g = global [2 x i32] zeroinitializer\ndefine i32 @main() { ret i32 0 }",
            in: ctx
        )
        let gv = module.global(named: "g")
        #expect(gv?.initializer is ConstantAggregateZero)
        #expect(ctx.int32.contextRef == ctx.ref)
        #expect(ctx.pointerType().contextRef == ctx.ref)
    }

    @Test func instructionAtomicAttributes() throws {
        let ctx = Context()
        let module = Module(name: "atomic", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let gv = module.addGlobal("g", type: i32)
        gv.initializer = ctx.constantInt(0, type: i32)

        let load = builder.buildLoad(i32, gv, name: "l")
        load.isVolatile = true
        load.ordering = .Acquire
        #expect(load.isVolatile)
        #expect(load.ordering == .Acquire)

        let store = builder.buildStore(ctx.constantInt(1, type: i32), to: gv)
        store.isVolatile = true
        #expect(store.isVolatile)

        let rmw = builder.buildAtomicRMW(
            .Xchg,
            gv,
            ctx.constantInt(5, type: i32),
            ordering: .SequentiallyConsistent
        )
        #expect(!rmw.isVolatile)
        #expect(rmw.binOp == .Xchg)
        rmw.binOp = .Add
        #expect(rmw.binOp == .Add)

        builder.buildFence(ordering: .Release)

        builder.buildRet(ctx.constantInt(0, type: i32))
        let ir = module.irString
        #expect(ir.contains("volatile"))
        #expect(ir.contains("acquire"))
        #expect(ir.contains("atomicrmw"))
        #expect(ir.contains("fence"))
        try module.verify()
    }

    @Test func globalValueAttributes() throws {
        let ctx = Context()
        let module = Module(name: "gvattrs2", in: ctx)
        let i32 = ctx.int32
        let fnType = ctx.functionType(returnType: i32)
        let declared = module.addFunction("declared", type: fnType)
        let defined = module.addFunction("defined", type: fnType)
        let entry = defined.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(ctx.constantInt(0, type: i32))

        #expect(declared.isDeclaration)
        #expect(!defined.isDeclaration)

        let gv = module.addGlobal("g", type: i32)
        #expect(gv.isDeclaration)
        gv.initializer = ctx.constantInt(1, type: i32)
        #expect(!gv.isDeclaration)

        let hiddenFn = module.addFunction("hiddenfn", type: fnType)
        hiddenFn.visibility = .Hidden
        #expect(hiddenFn.visibility == .Hidden)

        let importFn = module.addFunction("importfn", type: fnType)
        importFn.dllStorageClass = .DLLImport
        #expect(importFn.dllStorageClass == .DLLImport)
        let ir = module.irString
        #expect(ir.contains("hidden"))
        #expect(ir.contains("dllimport"))
        try module.verify()
    }

    @Test func valuePrinting() throws {
        let ctx = Context()
        let module = Module(name: "print", in: ctx)
        let i32 = ctx.int32

        let c = ctx.constantInt(42, type: i32)
        #expect(c.description.contains("42"))
        #expect((c.type as? IntegerType)?.width == 32)

        let fp = ctx.constantFP(3.5, type: ctx.double)
        #expect(abs(fp.doubleValue - 3.5) < 1e-9)

        let gv = module.addGlobal("g", type: i32)
        #expect(gv.description.contains("g"))
    }

    @Test func functionAttributes() throws {
        let ctx = Context()
        let module = Module(name: "fnattrs", in: ctx)
        let voidType = ctx.functionType(returnType: ctx.void)
        let f = module.addFunction("f", type: voidType)
        let entry = f.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRetVoid()

        #expect(f.gc == nil)
        f.gc = "shadow-stack"
        #expect(f.gc == "shadow-stack")
        #expect(f.linkage == .External)
        f.linkage = .Internal
        #expect(f.linkage == .Internal)
        let ir = module.irString
        #expect(ir.contains("internal"))
        #expect(ir.contains("shadow-stack"))
        try module.verify()
    }

    @Test func moduleGetOrInsertFunction() throws {
        let ctx = Context()
        let module = Module(name: "getorinsert", in: ctx)
        let fnType = ctx.functionType(returnType: ctx.int32)
        let f1 = module.getOrInsertFunction("foo", type: fnType)
        let f2 = module.getOrInsertFunction("foo", type: fnType)
        #expect(f1.ref == f2.ref)
        #expect(module.function(named: "foo")?.ref == f1.ref)
    }

    @Test func basicBlockOperations() throws {
        let ctx = Context()
        let module = Module(name: "bbops", in: ctx)
        let voidType = ctx.functionType(returnType: ctx.void)
        let f = module.addFunction("f", type: voidType)
        let first = f.appendBasicBlock("first")
        let second = f.appendBasicBlock("second")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: first)
        builder.buildRetVoid()
        builder.positionAtEnd(of: second)
        builder.buildRetVoid()

        let newBlock = first.insertBasicBlock("new")
        builder.positionAtEnd(of: newBlock)
        builder.buildRetVoid()
        #expect(f.basicBlocks.count == 3)
        #expect(f.basicBlocks[0].ref == newBlock.ref)
        #expect(f.basicBlocks[1].ref == first.ref)

        newBlock.moveBasicBlock(before: second)
        #expect(f.basicBlocks[1].ref == newBlock.ref)
        try module.verify()
    }

    @Test func targetMachineQueries() throws {
        TargetMachine.initializeAllTargets()
        let triple = TargetMachine.defaultTriple
        let target = try Target.fromTriple(triple)
        let tm = TargetMachine(target: target, triple: triple)
        #expect(tm.triple == triple)
        #expect(tm.target.name == target.name)
    }

    @Test func vectorBuilderInstructions() throws {
        let ctx = Context()
        let module = Module(name: "vecbuild", in: ctx)
        let i32 = ctx.int32
        let vecType = ctx.vectorType(elementType: i32, count: 4)
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [vecType])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let vec = main.parameter(at: 0)
        let idx = ctx.constantInt(1, type: i32)
        builder.buildExtractElement(vec, idx, name: "e")
        builder.buildInsertElement(vec, ctx.constantInt(9, type: i32), idx, name: "i")
        let mask = ctx.constantVector([
            ctx.constantInt(0, type: i32), ctx.constantInt(0, type: i32),
            ctx.constantInt(0, type: i32), ctx.constantInt(0, type: i32),
        ])
        builder.buildShuffleVector(vec, vec, mask: mask, name: "s")
        builder.buildRet(ctx.constantInt(0, type: i32))

        let ir = module.irString
        #expect(ir.contains("extractelement"))
        #expect(ir.contains("insertelement"))
        #expect(ir.contains("shufflevector"))
        try module.verify()
    }

    @Test func constantExprOpcode() throws {
        let ctx = Context()
        let i32 = ctx.int32
        let five = ctx.constantInt(5, type: i32)
        let three = ctx.constantInt(3, type: i32)

        let notExpr = ctx.constantNot(five)
        if let ce = notExpr as? ConstantExpr {
            #expect(ce.opcode == .Xor)
        }

        let xorExpr = ctx.constantXor(five, three)
        if let ce = xorExpr as? ConstantExpr {
            #expect(ce.opcode == .Xor)
            #expect(ce.numOperands == 2)
        }

        let intToPtr = ctx.constantIntToPtr(five, to: ctx.pointerType())
        if let ce = intToPtr as? ConstantExpr {
            #expect(ce.opcode == .IntToPtr)
        }
    }

    @Test func globalVariableMore() throws {
        let ctx = Context()
        let module = Module(name: "gvmore", in: ctx)
        let i32 = ctx.int32
        let gv = module.addGlobal("g", type: i32)

        #expect(!gv.isGlobalConstant)
        gv.isGlobalConstant = true
        gv.initializer = ctx.constantInt(1, type: i32)
        #expect(gv.isGlobalConstant)

        gv.isThreadLocal = true
        gv.tlsModel = .LocalDynamic
        #expect(gv.tlsModel == .LocalDynamic)

        let ir = module.irString
        #expect(ir.contains("constant"))
        #expect(ir.contains("localdynamic"))
        try module.verify()
    }

    @Test func builderMemoryIntrinsics() throws {
        let ctx = Context()
        let module = Module(name: "memintr", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: ctx.void)
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let dest = builder.buildAlloca(i32, name: "d")
        let src = builder.buildAlloca(i32, name: "s")
        builder.buildStore(ctx.constantInt(7, type: i32), to: src)
        let len = ctx.constantInt(4, type: i32)
        builder.buildMemSet(dest, ctx.constantInt(0, type: ctx.int8), len, alignment: 4)
        builder.buildMemCpy(dest, destAlign: 4, src, sourceAlign: 4, len)
        builder.buildMemMove(dest, destAlign: 4, src, sourceAlign: 4, len)
        builder.buildRetVoid()

        let ir = module.irString
        #expect(ir.contains("llvm.memset"))
        #expect(ir.contains("llvm.memcpy"))
        #expect(ir.contains("llvm.memmove"))
        try module.verify()
    }

    @Test func builderCastVariants() throws {
        let ctx = Context()
        let module = Module(name: "castvars", in: ctx)
        let i32 = ctx.int32
        let i8 = ctx.int8
        let mainType = ctx.functionType(returnType: i8, parameterTypes: [i8, ctx.double, ctx.pointerType()])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let p0 = main.parameter(at: 0)
        builder.buildZExtOrBitCast(p0, to: i32, name: "zext")
        builder.buildSExtOrBitCast(p0, to: i32, name: "sext")
        builder.buildIntCast(p0, to: i32, isSigned: true, name: "intcast")
        builder.buildFPCast(main.parameter(at: 1), to: ctx.float, name: "fpcast")
        builder.buildRet(p0)

        let ir = module.irString
        #expect(ir.contains("zext"))
        #expect(ir.contains("sext"))
        #expect(ir.contains("intcast"))
        #expect(ir.contains("fpcast"))
        try module.verify()
    }

    @Test func valueNameAndModuleMetadata() throws {
        let ctx = Context()
        let module = Module(name: "mdmore", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let x = builder.buildAdd(main.parameter(at: 0), ctx.constantInt(2, type: i32), name: "x")
        builder.buildRet(x)

        #expect(x.shortName == "x")
        x.name = "renamed"
        #expect(x.shortName == "renamed")

        let md = ctx.mdString("named-md")
        module.addNamedMetadataOperand("foo", ctx.metadataAsValue(md))
        #expect(module.namedMetadataOperandCount("foo") == 1)
        #expect(module.namedMetadataOperands("foo").count == 1)
        let ir = module.irString
        #expect(ir.contains("!foo"))
        try module.verify()
    }

    @Test func functionCallConv() throws {
        let ctx = Context()
        let module = Module(name: "fncc", in: ctx)
        let voidType = ctx.functionType(returnType: ctx.void)
        let f = module.addFunction("f", type: voidType)
        let entry = f.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRetVoid()

        #expect(f.callConv == .C)
        f.callConv = .Fast
        #expect(f.callConv == .Fast)
        let ir = module.irString
        #expect(ir.contains("fastcc"))
        try module.verify()
    }

    @Test func instructionOpcodeNames() throws {
        let ctx = Context()
        let module = Module(name: "opcodes", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let p0 = main.parameter(at: 0)
        let add = builder.buildAdd(p0, main.parameter(at: 1), name: "s")
        let icmp = builder.buildICmp(.EQ, p0, main.parameter(at: 1), name: "c")
        builder.buildRet(add)

        #expect(add.opcode == .Add)
        #expect(add.opcodeName == "add")
        #expect(icmp.opcode == .ICmp)
        #expect(icmp.opcodeName == "icmp")
        #expect(entry.terminator?.opcodeName == "ret")

        #expect(module.context.ref == ctx.ref)
        let ptrType = ctx.pointerType()
        #expect(ptrType.addressSpace == 0)
        let addrSpacePtr = ctx.pointerType(addressSpace: 3)
        #expect(addrSpacePtr.addressSpace == 3)
        #expect(ctx.int32.width == 32)
    }

    @Test func functionPassManagerLifecycle() throws {
        let ctx = Context()
        let module = Module(name: "fpm", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(main.parameter(at: 0))

        let fpm = PassManager(module: module)
        fpm.initialize()
        fpm.run(on: main)
        fpm.finalize()
        try module.verify()
    }

    @Test func atomicCmpXchgBuilder() throws {
        let ctx = Context()
        let module = Module(name: "cmpxchg", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let gv = module.addGlobal("g", type: i32)
        gv.initializer = ctx.constantInt(0, type: i32)
        let cmpxchg = builder.buildAtomicCmpXchg(
            gv,
            ctx.constantInt(0, type: i32),
            ctx.constantInt(1, type: i32),
            successOrdering: .Acquire,
            failureOrdering: .Monotonic
        )
        builder.buildRet(ctx.constantInt(0, type: i32))

        #expect(cmpxchg.isVolatile == false)
        let ir = module.irString
        #expect(ir.contains("cmpxchg"))
        try module.verify()
    }

    @Test func targetDescriptionAndConstantFPBits() throws {
        TargetMachine.initializeAllTargets()
        let triple = TargetMachine.defaultTriple
        let target = try Target.fromTriple(triple)
        #expect(!target.name.isEmpty)
        #expect(!target.description.isEmpty)

        let ctx = Context()
        let fp = ctx.constantFP(1.5, type: ctx.double)
        let (value, isFinite) = fp.doubleValueWithStatus
        #expect(abs(value - 1.5) < 1e-12)
        #expect(isFinite)
    }

    @Test func valueKindNames() throws {
        let ctx = Context()
        let module = Module(name: "kinds", in: ctx)
        let i32 = ctx.int32
        let fnType = ctx.functionType(returnType: i32)
        let fn = module.addFunction("f", type: fnType)
        let entry = fn.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(ctx.constantInt(0, type: i32))

        #expect(fn.kindName == "function")
        #expect(ctx.constantInt(1, type: i32).kindName == "constant-int")
        #expect(ctx.poison(i32).kindName == "poison")
        #expect(ctx.constantPointerNull(ctx.pointerType()).kindName == "constant-pointer-null")
    }

    @Test func namedMetadataTraversal() throws {
        let ctx = Context()
        let module = Module(name: "mdnames", in: ctx)

        let md1 = ctx.mdString("first")
        module.addNamedMetadataOperand("llvm.dbg.cu", ctx.metadataAsValue(md1))
        let md2 = ctx.mdString("second")
        module.addNamedMetadataOperand("custom.meta", ctx.metadataAsValue(md2))

        let names = module.namedMetadataNames
        #expect(names.contains("llvm.dbg.cu"))
        #expect(names.contains("custom.meta"))
        #expect(module.namedMetadataOperandCount("llvm.dbg.cu") == 1)
        #expect(module.namedMetadataOperands("custom.meta").count == 1)
    }

    @Test func icmpFcmpPredicates() throws {
        let ctx = Context()
        let module = Module(name: "preds", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32, ctx.double, ctx.double])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let icmp = builder.buildICmp(.SGT, main.parameter(at: 0), main.parameter(at: 1), name: "i")
        let fcmp = builder.buildFCmp(.OGT, main.parameter(at: 2), main.parameter(at: 3), name: "f")
        builder.buildRet(ctx.constantInt(0, type: i32))

        #expect(icmp.predicate == .SGT)
        #expect(fcmp.predicate == .OGT)
        try module.verify()
    }

    @Test func constantExprArithmetic() throws {
        let ctx = Context()
        let i32 = ctx.int32
        let five = ctx.constantInt(5, type: i32)
        let three = ctx.constantInt(3, type: i32)

        #expect((ctx.constantNSWAdd(five, three) as? ConstantInt)?.unsignedValue == 8)
        #expect((ctx.constantNUWAdd(five, three) as? ConstantInt)?.unsignedValue == 8)
        #expect((ctx.constantNSWSub(five, three) as? ConstantInt)?.signedValue == 2)
        #expect((ctx.constantNUWSub(five, three) as? ConstantInt)?.unsignedValue == 2)
        #expect((ctx.constantNSWNeg(five) as? ConstantInt)?.signedValue == -5)
    }

    @Test func instructionQueriesAndFlags() throws {
        let ctx = Context()
        let module = Module(name: "queries", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32, ctx.double, ctx.double])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)

        let add = builder.buildNSWAdd(main.parameter(at: 0), main.parameter(at: 1), name: "s")
        #expect(add.isNSW)
        #expect(!add.isNUW)
        add.isNUW = true
        #expect(add.isNUW)
        add.isExact = true
        #expect(add.isExact)
        add.isNNeg = true
        #expect(add.isNNeg)
        add.isDisjoint = true
        #expect(add.isDisjoint)
        #expect(add.isTerminator == false)

        let alloca = builder.buildAlloca(i32)
        #expect(alloca.allocatedType.isInteger)
        #expect(alloca.allocatedType.ref == ctx.int32.ref)

        let icmp = builder.buildICmp(.SGT, main.parameter(at: 0), main.parameter(at: 1))
        icmp.isSameSign = true
        #expect(icmp.isSameSign)

        let fadd = builder.buildFAdd(main.parameter(at: 2), main.parameter(at: 3))
        #expect(fadd.canUseFastMathFlags)
        fadd.fastMathFlags = UInt32(LLVMFastMathAllowReassoc)
        #expect(fadd.fastMathFlags == UInt32(LLVMFastMathAllowReassoc))

        let ok = main.appendBasicBlock("ok")
        let elseBlock = main.appendBasicBlock("else")
        let br = builder.buildCondBr(icmp, then: ok, else: elseBlock)
        #expect(br.isConditional)
        #expect(br.condition != nil)
        #expect(br.isTerminator)
        #expect(br.successorCount == 2)
        #expect(br.successor(at: 0)?.ref == ok.ref)
        builder.positionAtEnd(of: elseBlock)
        builder.buildRet(ctx.constantInt(1, type: i32))

        let funcType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let callee = module.addFunction("callee", type: funcType)
        builder.positionAtEnd(of: ok)
        let call = builder.buildCall(callee, [main.parameter(at: 0)])
        #expect(call.numArgOperands == 1)
        let arg8 = ctx.constantInt(8, type: i32)
        call.setArgOperand(at: 0, arg8)
        #expect(call.numArgOperands == 1)
        #expect(call.argOperand(at: 0)?.ref == arg8.ref)

        let atomicRMW = builder.buildAtomicRMW(
            .Add, alloca, ctx.constantInt(1, type: i32),
            ordering: .SequentiallyConsistent
        )
        #expect(atomicRMW.isAtomic)
        let singleThread = ctx.syncScopeID("singlethread")
        atomicRMW.syncScopeID = singleThread
        #expect(atomicRMW.syncScopeID == singleThread)
        atomicRMW.isAtomicSingleThread = true
        #expect(atomicRMW.isAtomicSingleThread)

        let zero = ctx.constantInt(0, type: i32)
        let cmpVal = ctx.constantInt(1, type: i32)
        let newVal = ctx.constantInt(2, type: i32)
        let cmpxchg = builder.buildAtomicCmpXchg(
            alloca, cmpVal, newVal,
            successOrdering: .SequentiallyConsistent,
            failureOrdering: .Acquire
        )
        #expect(cmpxchg.successOrdering == .SequentiallyConsistent)
        #expect(cmpxchg.failureOrdering == .Acquire)
        #expect(cmpxchg.isWeak == false)
        #expect(cmpxchg.isAtomic)

        let gep = builder.buildGEP(ctx.int32, alloca, indices: [zero])
        #expect(gep.sourceElementType.ref == ctx.int32.ref)
        gep.noWrapFlags = [.InBounds]
        #expect(gep.noWrapFlags.contains(.InBounds))

        let ret = builder.buildRet(ctx.constantInt(0, type: i32))
        #expect(ret.previousInstruction?.ref == gep.ref)
        #expect(gep.nextInstruction?.ref == ret.ref)

        try module.verify()
    }

    @Test func invokeDestinations() throws {
        let ctx = Context()
        let module = Module(name: "invoke", in: ctx)
        let i32 = ctx.int32
        let voidFnType = ctx.functionType(returnType: ctx.void)
        let callee = module.addFunction("callee", type: voidFnType)
        let main = module.addFunction("main", type: ctx.functionType(returnType: i32))
        let personality = module.addFunction(
            "__gxx_personality_v0",
            type: ctx.functionType(returnType: ctx.int32, parameterTypes: [ctx.int32], isVariadic: true)
        )
        main.personality = personality
        let entry = main.appendBasicBlock("entry")
        let ok = main.appendBasicBlock("ok")
        let lpad = main.appendBasicBlock("lpad")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let invoke = builder.buildInvoke(callee, [], then: ok, catch: lpad)
        builder.positionAtEnd(of: ok)
        builder.buildRet(ctx.constantInt(0, type: i32))
        builder.positionAtEnd(of: lpad)
        let lpType = ctx.structType(elementTypes: [ctx.pointerType(), i32])
        let lp = builder.buildLandingPad(lpType, numClauses: 0)
        lp.isCleanup = true
        builder.buildResume(lp)

        #expect(invoke.normalDest?.ref == ok.ref)
        #expect(invoke.unwindDest?.ref == lpad.ref)
        try module.verify()
    }

    @Test func intrinsicAndInlineAsm() throws {
        let ctx = Context()
        let module = Module(name: "intrinsic", in: ctx)
        let i32 = ctx.int32

        let smaxID = ctx.lookupIntrinsicID("llvm.smax")
        #expect(smaxID != 0)
        #expect(ctx.intrinsicName(smaxID)?.contains("llvm.smax") == true)
        #expect(ctx.intrinsicType(smaxID, paramTypes: [i32, i32])?.isFunction == true)

        let decl = ctx.intrinsicDeclaration(smaxID, paramTypes: [i32, i32], in: module)
        #expect(decl != nil)
        #expect(decl!.isIntrinsic)
        #expect(decl!.intrinsicID == smaxID)
        #expect(decl!.name.contains("llvm.smax"))
        #expect(ctx.intrinsicOverloadedName(smaxID, paramTypes: [i32, i32], in: module)?.contains("i32") == true)

        let asmType = ctx.functionType(returnType: i32, parameterTypes: [ctx.pointerType()])
        let inlineAsm = ctx.constantInlineAsm(
            asmType, asmString: "movl $1, $0", constraints: "=r,r",
            hasSideEffects: false, isAlignStack: false
        )
        #expect(inlineAsm.asmString?.contains("movl") == true)
        #expect(inlineAsm.constraintString == "=r,r")
        #expect(inlineAsm.hasSideEffects == false)
        #expect(inlineAsm.needsAlignedStack == false)
        #expect(inlineAsm.dialect == .ATT)
        #expect(inlineAsm.functionType.isFunction)
    }

    @Test func constantFactoryExtensions() throws {
        let ctx = Context()
        let i32 = ctx.int32

        let big = ctx.constantInt(arbitraryPrecision: [0x0102_0304_0506_0708], type: ctx.int64)
        #expect(big.unsignedValue == 0x0102_0304_0506_0708)

        let three = ctx.constantFP(fromBits: [0x4008_0000_0000_0000], type: ctx.double)
        #expect(three.doubleValue == 3.0)

        let structType = ctx.namedStructType(name: "S", elementTypes: [i32, i32])
        let structConst = ctx.constantNamedStruct(
            structType,
            values: [ctx.constantInt(1, type: i32), ctx.constantInt(2, type: i32)]
        )
        #expect((structConst.aggregateElement(at: 1) as? ConstantInt)?.unsignedValue == 2)

        #expect((ctx.sizeOf(i32) as? ConstantExpr) != nil)
        #expect((ctx.alignOf(i32) as? ConstantExpr) != nil)
        #expect(ctx.sizeOf(i32).description.contains("4"))

        let ptr = ctx.pointerType()
        let gep = ctx.constantGEP(i32, ctx.constantPointerNull(ptr), indices: [ctx.constantInt(1, type: i32)])
        let expr = gep as? ConstantExpr
        #expect(expr != nil)
        #expect(expr!.opcode == .GetElementPtr)
        #expect(expr!.numIndices == 1)

        let inBoundsGEP = ctx.constantInBoundsGEP(
            i32,
            ctx.constantPointerNull(ptr),
            indices: [ctx.constantInt(1, type: i32)]
        )
        #expect(inBoundsGEP is ConstantExpr)
    }

    @Test func moduleFlagsAndTypeLookup() throws {
        let ctx = Context()
        let module = Module(name: "flags", in: ctx)

        let node = ctx.mdNode([])
        module.addModuleFlag(.Warning, key: "myflag", value: node)
        #expect(module.moduleFlag(key: "myflag") != nil)
        #expect(module.moduleFlags.count == 1)
        #expect(module.moduleFlags[0].key == "myflag")

        let named = ctx.namedStructType(name: "T", elementTypes: [ctx.int32])
        #expect(module.type(named: "T")?.ref == named.ref)
        #expect(module.type(named: "Missing") == nil)

        let i32 = ctx.int32
        #expect(i32.isSized)
        let funcType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
        #expect(funcType.numContainedTypes == 3)
        #expect(funcType.containedTypes.count == 3)

        let version = Context.version
        #expect(version.major >= 22)
        #expect(ctx.mdKindID("custom.kind") != 0)
        #expect(ctx.discardValueNames == false)

        #expect(ctx.half.isFloat)
        #expect(ctx.bfloat.isFloat)
        #expect(ctx.fp128.isFloat)
        #expect(ctx.x86FP80.isFloat)
        #expect(ctx.ppcFP128.isFloat)
        #expect(ctx.label.kind == .Label)
        #expect(ctx.token.kind == .Token)
    }

    @Test func targetMachineExtensions() throws {
        TargetMachine.initializeAllTargets()
        #expect(!Target.all.isEmpty)
        #expect(Target.named("x86-64") != nil)
        #expect(TargetMachine.normalizedTriple("x86_64-pc-linux-gnu").contains("x86_64"))
        #expect(!TargetMachine.hostCPUFeatures.isEmpty)

        let ctx = Context()
        let module = Module(name: "tm", in: ctx)
        let main = module.addFunction("main", type: ctx.functionType(returnType: ctx.int32))
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(ctx.constantInt(42, type: ctx.int32))

        let triple = TargetMachine.defaultTriple
        let target = try Target.fromTriple(triple)
        let options = TargetMachineOptions()
        options.setCPU(TargetMachine.hostCPUName)
        options.setCodeGenOptLevel(LLVMCodeGenLevelNone)
        let tm = TargetMachine(target: target, triple: triple, options: options)
        tm.setAsmVerbosity(true)
        tm.setFastISel(true)
        tm.setMachineOutliner(false)

        let buffer = try tm.emitToMemoryBuffer(module: module)
        #expect(!buffer.bytes.isEmpty)
        #expect(buffer.bytes[0] == 0x7F)
    }

    @Test func objectRelocations() throws {
        let ctx = Context()
        let module = Module(name: "reloc", in: ctx)
        let i32 = ctx.int32
        let funcType = ctx.functionType(returnType: i32)
        let main = module.addFunction("main", type: funcType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(ctx.constantInt(7, type: i32))

        TargetMachine.initializeAllTargets()
        let triple = TargetMachine.defaultTriple
        let target = try Target.fromTriple(triple)
        let tm = TargetMachine(target: target, triple: triple)
        let buffer = try tm.emitToMemoryBuffer(module: module)

        let binary = try Binary(buffer: buffer)
        let sections = binary.sections()
        #expect(!sections.isEmpty)
        let symbols = binary.symbols()
        #expect(symbols.contains { $0.name == "main" })
        let copied = binary.copyMemoryBuffer()
        #expect(!copied.bytes.isEmpty)
        let relocs = binary.relocations(ofSectionAt: 0)
        #expect(relocs.count >= 0)
        if let mainSymbol = symbols.first(where: { $0.name == "main" }) {
            #expect(binary.sectionContainsSymbol(mainSymbol))
        }
    }

    @Test func dbgRecordTraversal() throws {
        let ctx = Context()
        let module = Module(name: "dbgrec", in: ctx)
        module.isNewDbgInfoFormat = true
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)

        let dib = DIBuilder(module: module)
        let file = dib.createFile("main.c", directory: "/tmp")
        let cu = dib.createCompileUnit(language: LLVMDWARFSourceLanguageC, file: file, producer: "test")
        let subType = dib.createSubroutineType(file: file, returnTypes: [])
        let sub = dib.createFunction(
            scope: cu,
            name: "main",
            linkageName: "main",
            file: file,
            line: 1,
            subroutineType: subType,
            isLocalToUnit: false
        )
        main.setSubprogram(sub)

        let alloca = builder.buildAlloca(i32)
        let intType = dib.createBasicType(name: "int", sizeInBits: 32, encoding: 5)
        let varNode = dib.createAutoVariable(scope: sub, name: "x", file: file, line: 2, type: intType)
        let expr = dib.createExpression([])
        let loc = dib.createDebugLocation(line: 3, column: 1, scope: sub, inlinedAt: nil)
        builder.setCurrentDebugLocation(loc)
        builder.buildStore(main.parameter(at: 0), to: alloca)
        dib.insertDeclareAtEnd(alloca, diVar: varNode, expr: expr, location: loc, block: entry)
        dib.finalize()

        let store = entry.lastInstruction
        #expect(store != nil)
        if let first = store!.firstDbgRecord {
            #expect(!first.kindName.isEmpty)
        }
        _ = store!.dbgRecords

        let ret = builder.buildRet(ctx.constantInt(0, type: i32))
        builder.positionBeforeInstrAndDbgRecords(ret)
        builder.positionBeforeDbgRecords(in: entry, before: ret)
        try module.verify()
    }

    @Test func interpreterExecution() throws {
        let ctx = Context()
        let module = Module(name: "interp", in: ctx)
        let i32 = ctx.int32
        let main = module.addFunction("main", type: ctx.functionType(returnType: i32))
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRet(ctx.constantInt(42, type: i32))

        ExecutionEngine.linkInInterpreter()
        let engine = try ExecutionEngine(interpreterFor: module)
        let result = engine.runFunction(main)
        #expect(result?.toInt(isSigned: false) == 42)
    }

    @Test func valueMutationAndErase() throws {
        let ctx = Context()
        let module = Module(name: "mut", in: ctx)
        let i32 = ctx.int32
        let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
        let main = module.addFunction("main", type: mainType)
        let entry = main.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let add = builder.buildAdd(main.parameter(at: 0), main.parameter(at: 1))
        let other = ctx.constantInt(9, type: i32)
        add.setOperand(at: 1, other)
        #expect(add.operand(at: 1)?.ref == other.ref)
        builder.buildRet(add)

        let blockValue = entry.asValue
        #expect(blockValue.isBasicBlock)
        #expect(blockValue.asBasicBlock?.ref == entry.ref)

        let global = module.addGlobal("g", type: i32)
        global.isExternallyInitialized = true
        #expect(global.isExternallyInitialized)

        let tmp = module.addFunction("tmp", type: ctx.functionType(returnType: i32))
        let tmpEntry = tmp.appendBasicBlock("e")
        let tmpBuilder = Builder(in: ctx)
        tmpBuilder.positionAtEnd(of: tmpEntry)
        tmpBuilder.buildRet(ctx.constantInt(0, type: i32))
        #expect(module.functions.contains { $0.ref == tmp.ref })
        tmp.eraseFromParent()
        #expect(!module.functions.contains { $0.ref == tmp.ref })

        try module.verify()
    }

    @Test func supportAndErrorHelpers() {
        let error = LLVMError.createStringError("boom")
        #expect(LLVMError.isStringError(error))
        LLVMConsumeError(error)

        enablePrettyStackTrace()

        var symbolValue = 42
        LLVMSupport.addSymbol("my_test_symbol", value: &symbolValue)
        #expect(LLVMSupport.searchForAddressOfSymbol("my_test_symbol") != nil)
        #expect(LLVMSupport.loadLibraryPermanently("libc.so.6"))
    }

    @Test func functionTypeQuery() {
        let ctx = Context()
        let module = Module(name: "fn", in: ctx)
        let i32 = ctx.int32
        let fnType = ctx.functionType(returnType: i32, parameterTypes: [i32, ctx.double], isVariadic: true)
        let fn = module.addFunction("f", type: fnType)

        #expect(fn.functionType.isFunction)
        #expect(fn.functionType.returnType.ref == i32.ref)
        #expect(fn.functionType.parameterCount == 2)
        #expect(fn.functionType.parameterTypes[1].ref == ctx.double.ref)
        #expect(fn.functionType.isVariadic)
        #expect(fn.functionType.ref == fnType.ref)
        #expect(fn.type.kind == .Pointer)

        let global = module.addGlobal("g", type: i32)
        #expect(global.valueType.ref == i32.ref)

        let resolver = module.addFunction("resolver", type: ctx.functionType(returnType: i32))
        let ifunc = module.addIFunc("fptr", type: ctx.functionType(returnType: i32), resolver: resolver)
        #expect(ifunc.valueType.isFunction)
    }

    @Test func enumRoundTrips() throws {
        let ctx = Context()
        let module = Module(name: "enumrt", in: ctx)
        let i32 = ctx.int32
        let f = module.addFunction(
            "f",
            type: ctx.functionType(returnType: i32, parameterTypes: [i32, i32, ctx.double, ctx.double])
        )
        let entry = f.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)

        f.linkage = .LinkOnceODR
        #expect(f.linkage == .LinkOnceODR)
        f.linkage = .AvailableExternally
        #expect(f.linkage == .AvailableExternally)
        f.visibility = .Protected
        #expect(f.visibility == .Protected)
        f.dllStorageClass = .DLLExport
        #expect(f.dllStorageClass == .DLLExport)
        f.callConv = .Custom(42)
        #expect(f.callConv == .Custom(42))
        f.callConv = .Swift
        #expect(f.callConv == .Swift)

        let gv = module.addGlobal("g", type: i32)
        gv.unnamedAddress = .Local
        #expect(gv.unnamedAddress == .Local)
        gv.tlsModel = .InitialExec
        #expect(gv.tlsModel == .InitialExec)

        let icmp = builder.buildICmp(.ULE, f.parameter(at: 0), f.parameter(at: 1), name: "c")
        let fcmp = builder.buildFCmp(.UEQ, f.parameter(at: 2), f.parameter(at: 3), name: "c")
        builder.buildRet(ctx.constantInt(0, type: i32))
        #expect(icmp.predicate == .ULE)
        #expect(icmp.opcode == .ICmp)
        #expect(icmp.opcodeName == "icmp")
        #expect(fcmp.predicate == .UEQ)

        let comdat = module.getOrInsertComdat("c")
        comdat.selectionKind = .SameSize
        #expect(comdat.selectionKind == .SameSize)

        let dl = DataLayout(string: "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128")
        module.dataLayout = dl
        #expect(dl.byteOrder == .LittleEndian)

        try module.verify()
        try module.verify(action: .PrintMessage)
        _ = f.verify(action: .ReturnStatus)

        #expect(Linkage.External.llvm == LLVMExternalLinkage)
        #expect(Linkage.External.rawValue == 0)
        #expect(Linkage(llvm: LLVMInternalLinkage) == .Internal)
        #expect(Linkage.Common.rawValue == 14)
        #expect(Visibility.Hidden.rawValue == 1)
        #expect(UnnamedAddr.Global.rawValue == 2)
        #expect(ThreadLocalMode.NotThreadLocal.rawValue == 0)
        #expect(DLLStorageClass.Default.rawValue == 0)
        #expect(CallConv.C.llvm == 0)
        #expect(CallConv(llvm: 96) == .AMDGPUES)
        #expect(InlineAsmDialect.Intel.llvm == LLVMInlineAsmDialectIntel)
        #expect(IntPredicate.EQ.rawValue == 32)
        #expect(IntPredicate(llvm: LLVMIntSLE) == .SLE)
        #expect(RealPredicate.True.rawValue == 15)
        #expect(TailCallKind.MustTail.llvm == LLVMTailCallKindMustTail)
        #expect(AtomicOrdering.AcquireRelease.rawValue == 6)
        #expect(AtomicRMWBinOp.FMaximum.llvm == LLVMAtomicRMWBinOpFMaximum)
        #expect(ComdatSelectionKind.ExactMatch.llvm == LLVMExactMatchComdatSelectionKind)
        #expect(ModuleFlagBehavior.AppendUnique.rawValue == 5)
        #expect(ByteOrdering.BigEndian.rawValue == 0)
        #expect(VerifierFailureAction.ReturnStatus.llvm == LLVMReturnStatusAction)
        #expect(TypeKind.TargetExt.rawValue == 20)
        #expect(TypeKind(llvm: LLVMVoidTypeKind) == .Void)
        #expect(ValueKind.ConstantPtrAuth.rawValue == 27)
        #expect(ValueKind(llvm: LLVMPoisonValueValueKind) == .PoisonValue)
        #expect(Opcode.CatchSwitch.rawValue == 65)
        #expect(Opcode.PtrToAddr.rawValue == 69)
        #expect(Opcode.AddrSpaceCast.rawValue == 60)
        #expect(Opcode(llvm: LLVMGetElementPtr) == .GetElementPtr)
        #expect(Opcode.Ret.llvm == LLVMRet)
    }

    @Test func structTypeSetBody() throws {
        let ctx = Context()
        let module = Module(name: "structs", in: ctx)
        let i32 = ctx.int32
        let ptr = ctx.pointerType()

        let opaque = ctx.namedStructType(name: "S")
        #expect(opaque.isOpaque)
        #expect(opaque.elementCount == 0)
        opaque.setElementTypes([i32, ptr])
        #expect(!opaque.isOpaque)
        #expect(opaque.elementCount == 2)
        #expect(opaque.elementType(at: 0).ref == i32.ref)
        #expect(opaque.elementType(at: 1).ref == ptr.ref)
        #expect(opaque.elementTypes.map(\.ref) == [i32.ref, ptr.ref])

        let packed = ctx.namedStructType(name: "P")
        packed.setElementTypes([i32, i32], isPacked: true)
        #expect(packed.isPacked)

        _ = module.addGlobal("gs", type: opaque)
        _ = module.addGlobal("gp", type: packed)
        let fn = module.addFunction("use", type: ctx.functionType(returnType: ctx.void))
        let entry = fn.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRetVoid()
        try module.verify()
        let ir = module.irString
        #expect(ir.contains("%S = type { i32, ptr }"))
        #expect(ir.contains("%P = type <{ i32, i32 }>"))
    }

    @Test func gepIsInBoundsSetter() throws {
        let ctx = Context()
        let module = Module(name: "gep", in: ctx)
        let i32 = ctx.int32
        let fn = module.addFunction(
            "f", type: ctx.functionType(returnType: ctx.void, parameterTypes: [ctx.pointerType()])
        )
        let entry = fn.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let gep = builder.buildGEP(i32, fn.parameter(at: 0), indices: [ctx.constantInt(0, type: i32)], name: "g")
        #expect(!gep.isInBounds)
        gep.isInBounds = true
        #expect(gep.isInBounds)
        builder.buildRetVoid()
        try module.verify()
        #expect(module.irString.contains("getelementptr inbounds"))
    }

    @Test func functionTargetDependentAttribute() {
        let ctx = Context()
        let module = Module(name: "attr", in: ctx)
        let fn = module.addFunction("f", type: ctx.functionType(returnType: ctx.int32))
        fn.addTargetDependentAttribute(key: "foo", value: "bar")
        let attrs = fn.attributes(at: AttributeIndex.functionIndex)
        #expect(attrs.contains { $0.stringKind == "foo" && $0.stringValue == "bar" })
    }

    @Test func argumentSetAlignment() throws {
        let ctx = Context()
        let module = Module(name: "align", in: ctx)
        let fn = module.addFunction(
            "f", type: ctx.functionType(returnType: ctx.void, parameterTypes: [ctx.pointerType()])
        )
        fn.parameter(at: 0).setAlignment(8)
        let entry = fn.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        builder.buildRetVoid()
        try module.verify()
        #expect(module.irString.contains("align 8"))
    }

    @Test func moduleSetDataLayoutString() {
        let ctx = Context()
        let module = Module(name: "dl", in: ctx)
        module.setDataLayout("e-m:e-i64:64")
        #expect(module.dataLayout.string.contains("e-m:e"))
    }

    @Test func builderAddMetadataToInst() throws {
        let ctx = Context()
        let module = Module(name: "meta", in: ctx)
        let di = DIBuilder(module: module)
        let file = di.createFile("meta.swift", directory: "/tmp")
        let cu = di.createCompileUnit(
            language: LLVMDWARFSourceLanguageSwift,
            file: file,
            producer: "swiftc",
            isOptimized: false
        )
        let subType = di.createSubroutineType(file: file, returnTypes: [])
        let fn = module.addFunction("f", type: ctx.functionType(returnType: ctx.void))
        let entry = fn.appendBasicBlock("entry")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let sp = di.createFunction(
            scope: cu,
            name: "f",
            file: file,
            line: 1,
            subroutineType: subType,
            isLocalToUnit: true,
            isDefinition: true,
            scopeLine: 1
        )
        let loc = di.createDebugLocation(line: 42, column: 7, scope: sp)
        builder.setCurrentDebugLocation(loc)
        let alloca = builder.buildAlloca(ctx.int32, name: "x")
        builder.addMetadataToInst(alloca)
        builder.buildRetVoid()
        #expect(alloca.debugLocLine == 42)
        #expect(alloca.debugLocColumn == 7)
    }

    @Test func globalIFuncSetResolver() throws {
        let ctx = Context()
        let module = Module(name: "ifunc", in: ctx)
        let type = ctx.functionType(returnType: ctx.int32)
        let r1 = module.addFunction("r1", type: type)
        let r2 = module.addFunction("r2", type: type)
        let ifunc = module.addIFunc("fptr", type: type, resolver: r1)
        #expect(ifunc.resolver?.ref == r1.ref)
        ifunc.setResolver(r2)
        #expect(ifunc.resolver?.ref == r2.ref)
    }

    @Test func catchPadSetParentCatchSwitch() {
        let ctx = Context()
        let module = Module(name: "eh", in: ctx)
        let fn = module.addFunction("f", type: ctx.functionType(returnType: ctx.void))
        let entry = fn.appendBasicBlock("entry")
        let other = fn.appendBasicBlock("other")
        let eh = fn.appendBasicBlock("eh")
        let builder = Builder(in: ctx)
        builder.positionAtEnd(of: entry)
        let cs1 = builder.buildCatchSwitch(parentPad: nil, unwind: nil, numHandlers: 0, name: "cs1")
        builder.positionAtEnd(of: other)
        let cs2 = builder.buildCatchSwitch(parentPad: nil, unwind: nil, numHandlers: 0, name: "cs2")
        builder.positionAtEnd(of: eh)
        let cp = builder.buildCatchPad(parentPad: cs1, args: [], name: "cp")
        let irBefore = module.irString
        #expect(irBefore.contains("catchpad within %cs1"))
        cp.setParentCatchSwitch(cs2)
        let irAfter = module.irString
        #expect(irAfter.contains("catchpad within %cs2"))
        #expect(!irAfter.contains("catchpad within %cs1"))
    }
}
