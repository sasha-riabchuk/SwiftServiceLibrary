import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ServiceLibraryPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServiceMacro.self,
        GetMacro.self,
        PostMacro.self,
        PutMacro.self,
        DeleteMacro.self,
        PatchMacro.self,
        HeaderMacro.self,
        QueryMacro.self,
        ParamsMacro.self,
        InterceptorMacro.self
    ]
}
