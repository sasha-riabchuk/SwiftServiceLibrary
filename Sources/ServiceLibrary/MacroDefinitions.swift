#if canImport(ServiceLibraryMacros)
import ServiceLibraryMacros
#endif

@attached(member)
public macro Service(baseURL: String) = #externalMacro(module: "ServiceLibraryMacros", type: "ServiceMacro")

@attached(peer)
public macro Get(endpoint: String) = #externalMacro(module: "ServiceLibraryMacros", type: "GetMacro")

@attached(peer)
public macro Post(endpoint: String) = #externalMacro(module: "ServiceLibraryMacros", type: "PostMacro")

@attached(peer)
public macro Put(endpoint: String) = #externalMacro(module: "ServiceLibraryMacros", type: "PutMacro")

@attached(peer)
public macro Delete(endpoint: String) = #externalMacro(module: "ServiceLibraryMacros", type: "DeleteMacro")

@attached(peer)
public macro Patch(endpoint: String) = #externalMacro(module: "ServiceLibraryMacros", type: "PatchMacro")

@attached(peer)
public macro Header(_ value: String) = #externalMacro(module: "ServiceLibraryMacros", type: "HeaderMacro")

@attached(peer)
public macro Query(_ value: String) = #externalMacro(module: "ServiceLibraryMacros", type: "QueryMacro")

@attached(peer)
public macro Params(_ value: String) = #externalMacro(module: "ServiceLibraryMacros", type: "ParamsMacro")

@attached(peer)
public macro Interceptor(_ value: String) = #externalMacro(module: "ServiceLibraryMacros", type: "InterceptorMacro")
