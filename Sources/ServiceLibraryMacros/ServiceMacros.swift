import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct ServiceMacro: MemberMacro, PeerMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argumentList = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }
        guard let baseURLExpr = argumentList.first(where: { $0.label?.text == "baseURL" })?.expression,
              let baseURLLiteral = baseURLExpr.as(StringLiteralExprSyntax.self)?.segments.first?.description
              .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        else {
            return []
        }

        var pathCases: [String] = []
        var methodCases: [String] = []
        var headerCases: [String] = []
        var queryCases: [String] = []
        var paramsCases: [String] = []
        var interceptorCases: [String] = []
        var parametersEncodingCases: [String] = []

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            for member in enumDecl.memberBlock.members {
                guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
                guard let caseName = caseDecl.elements.first?.name.text else { continue }
                for attr in caseDecl.attributes {
                    guard let attrSyntax = attr.as(AttributeSyntax.self) else { continue }
                    let name = attrSyntax.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    switch name {
                    case "Get":
                        pathCases.append("case .\(caseName): return Self.\(caseName)_path")
                        methodCases.append("case .\(caseName): return .get")
                    case "Post":
                        pathCases.append("case .\(caseName): return Self.\(caseName)_path")
                        methodCases.append("case .\(caseName): return .post")
                    case "Put":
                        pathCases.append("case .\(caseName): return Self.\(caseName)_path")
                        methodCases.append("case .\(caseName): return .put")
                    case "Delete":
                        pathCases.append("case .\(caseName): return Self.\(caseName)_path")
                        methodCases.append("case .\(caseName): return .delete")
                    case "Patch":
                        pathCases.append("case .\(caseName): return Self.\(caseName)_path")
                        methodCases.append("case .\(caseName): return .patch")
                    case "Header":
                        headerCases.append("case .\(caseName): return Self.\(caseName)_headers")
                    case "Query":
                        queryCases.append("case .\(caseName): return Self.\(caseName)_queryItems")
                    case "Params":
                        paramsCases.append("case .\(caseName): return Self.\(caseName)_parameters")
                        // Add this line for parameter encoding:
                        parametersEncodingCases.append("case .\(caseName): return Self.\(caseName)_parametersEncoding ?? .json")
                    case "Interceptor":
                        interceptorCases.append("case .\(caseName): return Self.\(caseName)_interceptors")
                    default:
                        continue
                    }
                }
            }
        }

        let baseURLMember: DeclSyntax = """
        public var baseURL: URL? { URL(string: \"\(raw: baseURLLiteral)\") }
        """

        let pathMember: DeclSyntax
        if pathCases.isEmpty {
            pathMember = "public var path: String? { nil }"
        } else {
            pathMember = """
            public var path: String? {
                switch self {
            \(raw: pathCases.joined(separator: "\n"))
                }
            }
            """
        }

        let methodMember: DeclSyntax
        if methodCases.isEmpty {
            methodMember = "public var httpMethod: HTTPMethod { .get }"
        } else {
            methodMember = """
            public var httpMethod: HTTPMethod {
                switch self {
            \(raw: methodCases.joined(separator: "\n"))
                }
            }
            """
        }

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

        let parametersEncodingMember: DeclSyntax
        if parametersEncodingCases.isEmpty {
            parametersEncodingMember = "public var parametersEncoding: BodyParameterEncoding? { nil }"
        } else {
            parametersEncodingMember = """
            public var parametersEncoding: BodyParameterEncoding? {
                switch self {
            \(raw: parametersEncodingCases.joined(separator: "\n"))
                default: return nil // Default for cases without @Params
                }
            }
            """
        }

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

    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        let enumName = enumDecl.name.text
        let extensionDecl: DeclSyntax = "extension \(raw: enumName): ServiceProtocol {}"
        return [extensionDecl]
    }
}

public struct GetMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let endpointExpr = argList.first?.expression
        else { return [] }

        let pathVar: DeclSyntax = "static var \(raw: caseName)_path: String { \(endpointExpr) }"
        return [pathVar]
    }
}

public struct PostMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let endpointExpr = argList.first?.expression
        else { return [] }

        let pathVar: DeclSyntax = "static var \(raw: caseName)_path: String { \(endpointExpr) }"
        return [pathVar]
    }
}

public struct PutMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let endpointExpr = argList.first?.expression
        else { return [] }

        let pathVar: DeclSyntax = "static var \(raw: caseName)_path: String { \(endpointExpr) }"
        return [pathVar]
    }
}

public struct DeleteMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let endpointExpr = argList.first?.expression
        else { return [] }

        let pathVar: DeclSyntax = "static var \(raw: caseName)_path: String { \(endpointExpr) }"
        return [pathVar]
    }
}

public struct PatchMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let endpointExpr = argList.first?.expression
        else { return [] }

        let pathVar: DeclSyntax = "static var \(raw: caseName)_path: String { \(endpointExpr) }"
        return [pathVar]
    }
}

public struct HeaderMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let valuesExpr = argList.first?.expression
        else { return [] }

        let headerVar: DeclSyntax = """
        static var \(raw: caseName)_headers: [String: String]? {
            Dictionary(uniqueKeysWithValues: \(valuesExpr).map { ($0.key, String(describing: $0.value)) })
        }
        """
        return [headerVar]
    }
}

public struct QueryMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let valuesExpr = argList.first?.expression
        else { return [] }

        let queryVar: DeclSyntax = """
        static var \(raw: caseName)_queryItems: [URLQueryItem]? {
            \(valuesExpr).map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        }
        """
        return [queryVar]
    }
}

public struct ParamsMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self)
        else { return [] }

        var declarations: [DeclSyntax] = []

        // Parameters variable
        if let valuesExpr = argList.first(where: { $0.label == nil || $0.label?.text == "_"})?.expression {
            let paramsVar: DeclSyntax = """
            static var \(raw: caseName)_parameters: [String: Any]? {
                Dictionary(uniqueKeysWithValues: \(valuesExpr).map { ($0.key, $0.value) })
            }
            """
            declarations.append(paramsVar)
        }

        // Parameters encoding variable
        let encodingExpr = argList.first(where: { $0.label?.text == "encoding" })?.expression
        let encodingVarValue = encodingExpr != nil ? "\(encodingExpr!)" : "nil"

        let encodingVar: DeclSyntax = """
        static var \(raw: caseName)_parametersEncoding: BodyParameterEncoding? {
            \(raw: encodingVarValue)
        }
        """
        declarations.append(encodingVar)

        return declarations
    }
}

public struct InterceptorMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self),
              let caseName = caseDecl.elements.first?.name.text,
              let argList = attribute.arguments?.as(LabeledExprListSyntax.self),
              let interceptorsArrayExpr = argList.first?.expression // This should be the array
        else { return [] }

        let interceptorVar: DeclSyntax = """
        static var \(raw: caseName)_interceptors: InterceptorsStorage? {
            InterceptorsStorage(interceptors: \(interceptorsArrayExpr)) // Pass the array directly
        }
        """
        return [interceptorVar]
    }
}
