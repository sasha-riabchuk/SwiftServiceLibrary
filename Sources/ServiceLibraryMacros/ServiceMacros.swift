import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ServiceMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argumentList = attribute.argument?.as(LabeledExprListSyntax.self) else {
            return []
        }
        guard let baseURLExpr = argumentList.first(where: { $0.label?.text == "baseURL" })?.expression,
              let baseURLLiteral = baseURLExpr.as(StringLiteralExprSyntax.self)?.segments.first?.description.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        else {
            return []
        }

        var pathCases: [String] = []
        var methodCases: [String] = []
        var headerCases: [String] = []
        var queryCases: [String] = []
        var paramsCases: [String] = []
        var interceptorCases: [String] = []

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            for member in enumDecl.memberBlock.members {
                guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
                for element in caseDecl.elements {
                    let caseName = element.identifier.text
                    guard let attrs = element.attributes else { continue }
                    for attr in attrs {
                        guard let attrSyntax = attr.as(AttributeSyntax.self) else { continue }
                        let name = attrSyntax.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        switch name {
                        case "Get", "Post", "Put", "Delete", "Patch":
                            guard let argList = attrSyntax.argument?.as(LabeledExprListSyntax.self),
                                  let endpointExpr = argList.first?.expression,
                                  let endpointLiteral = endpointExpr.as(StringLiteralExprSyntax.self)?.segments.first?.description.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                            else { continue }
                            pathCases.append("case .\\(caseName): return \\\"\\(endpointLiteral)\\\"")
                            let method: String
                            switch name {
                            case "Get": method = ".get"
                            case "Post": method = ".post"
                            case "Put": method = ".put"
                            case "Delete": method = ".delete"
                            default: method = ".patch"
                            }
                            methodCases.append("case .\\(caseName): return \(method)")
                        case "Header":
                            if let arg = attrSyntax.argument?.as(LabeledExprListSyntax.self)?.first?.expression {
                                headerCases.append("case .\\(caseName): return \(arg)")
                            }
                        case "Query":
                            if let arg = attrSyntax.argument?.as(LabeledExprListSyntax.self)?.first?.expression {
                                queryCases.append("case .\\(caseName): return \(arg)")
                            }
                        case "Params":
                            if let arg = attrSyntax.argument?.as(LabeledExprListSyntax.self)?.first?.expression {
                                paramsCases.append("case .\\(caseName): return \(arg)")
                            }
                        case "Interceptor":
                            if let arg = attrSyntax.argument?.as(LabeledExprListSyntax.self)?.first?.expression {
                                interceptorCases.append("case .\\(caseName): return \(arg)")
                            }
                        default:
                            continue
                        }
                    }
                }
            }
        }

        let baseURLMember: DeclSyntax = "public var baseURL: URL? { URL(string: \\\"\\(baseURLLiteral)\\\") }"

        let pathMember: DeclSyntax = """
        public var path: String? {
            switch self {
        \(raw: pathCases.joined(separator: "\n"))
            }
        }
        """

        let methodMember: DeclSyntax = """
        public var httpMethod: HTTPMethod {
            switch self {
        \(raw: methodCases.joined(separator: "\n"))
            }
        }
        """

        let headersMember: DeclSyntax
        if headerCases.isEmpty {
            headersMember = "public var headers: [String: String]? { nil }"
        } else {
            headersMember = """
            public var headers: [String: String]? {
                switch self {
            \(raw: headerCases.joined(separator: "\n"))
                }
            }
            """
        }

        let queryItemsMember: DeclSyntax
        if queryCases.isEmpty {
            queryItemsMember = "public var queryItems: [URLQueryItem]? { nil }"
        } else {
            queryItemsMember = """
            public var queryItems: [URLQueryItem]? {
                switch self {
            \(raw: queryCases.joined(separator: "\n"))
                }
            }
            """
        }

        let parametersMember: DeclSyntax
        if paramsCases.isEmpty {
            parametersMember = "public var parameters: [String: Any]? { nil }"
        } else {
            parametersMember = """
            public var parameters: [String: Any]? {
                switch self {
            \(raw: paramsCases.joined(separator: "\n"))
                }
            }
            """
        }

        let parametersEncodingMember: DeclSyntax = "public var parametersEncoding: BodyParameterEncoding? { nil }"

        let interceptorsMember: DeclSyntax
        if interceptorCases.isEmpty {
            interceptorsMember = "public var interceptors: InterceptorsStorage? { nil }"
        } else {
            interceptorsMember = """
            public var interceptors: InterceptorsStorage? {
                switch self {
            \(raw: interceptorCases.joined(separator: "\n"))
                }
            }
            """
        }

        return [
            baseURLMember,
            pathMember,
            methodMember,
            headersMember,
            queryItemsMember,
            parametersMember,
            parametersEncodingMember,
            interceptorsMember
        ]
    }
}

public struct GetMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

public struct PostMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct PutMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct DeleteMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct PatchMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct HeaderMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct QueryMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct ParamsMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}

public struct InterceptorMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}
