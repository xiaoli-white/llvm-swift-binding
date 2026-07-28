import Testing
@testable import LLVMSwiftBinding

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
