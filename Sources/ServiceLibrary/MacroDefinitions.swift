#if canImport(ServiceLibraryMacros)
    import ServiceLibraryMacros
#endif

@attached(member, names: arbitrary)
public macro Service(baseURL: String) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "ServiceMacro"
)

@attached(member, names: arbitrary)
public macro Get(endpoint: String) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "GetMacro"
)

@attached(member, names: arbitrary)
public macro Post(endpoint: String) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "PostMacro"
)

@attached(member, names: arbitrary)
public macro Put(endpoint: String) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "PutMacro"
)

@attached(member, names: arbitrary)
public macro Delete(endpoint: String) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "DeleteMacro"
)

@attached(member, names: arbitrary)
public macro Patch(endpoint: String) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "PatchMacro"
)

@attached(member, names: arbitrary)
public macro Header(_ values: [String: Sendable]) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "HeaderMacro"
)

@attached(member, names: arbitrary)
public macro Query(_ values: [String: Sendable]) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "QueryMacro"
)

@attached(member, names: arbitrary)
public macro Params(_ values: [Parameter] = [], encoding: BodyParameterEncoding? = nil) = #externalMacro(
    module: "ServiceLibraryMacros",
    type: "ParamsMacro"
)

@attached(member, names: arbitrary)
public macro Interceptor(_ interceptors: [Interceptor]) = #externalMacro( // Changed to [Interceptor]
    module: "ServiceLibraryMacros",
    type: "InterceptorMacro"
)
