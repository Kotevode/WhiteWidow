//
//  URL+Wildcards.swift
//  WhiteWidow
//
//  Created by Mark on 02.02.17.
//
//

import Foundation

extension URL {

    var absolutePathComponents: [String] {
        var fullPath = [String]()
        if let scheme = self.scheme {
            fullPath += [scheme]
        }
        if let host = self.host {
            fullPath += [host]
        }
        if let port = self.port {
            fullPath += ["\(port)"]
        }
        return fullPath + self.pathComponents
    }

    static func ~= (url: URL, wildcard: URLWildcard) -> Bool {
        return wildcard.match(url: url)
    }

}

fileprivate enum AutomatoState: Equatable {

    case state(State)
    case success
    case error

    func nextState(key: String) -> AutomatoState {
        switch self {
        case .state(let state):
            return state.nextState(key: key)
        case .success:
            return .error
        case .error:
            return .error
        }
    }

    static func == (lhs: AutomatoState, rhs: AutomatoState) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success):
            fallthrough
        case (.error, .error):
            return true
        case (.state(let lstate), .state(let rstate)):
            return lstate == rstate
        default:
            return false
        }
    }

}

fileprivate class State: Equatable {

    var routes = [String: AutomatoState]()
    var defaultRoute: AutomatoState

    init(routes: [String: AutomatoState],
         defaultRoute: AutomatoState = .error) {
        self.routes = routes
        self.defaultRoute = defaultRoute
    }

    init(value: String,
         match: AutomatoState = .success,
         unmatch: AutomatoState = .error) {
        self.routes[value] = match
        self.defaultRoute = unmatch
    }

    func nextState(key: String) -> AutomatoState {
        guard let value = routes[key] else {
            return defaultRoute
        }
        return value
    }

    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.routes == rhs.routes &&
        lhs.defaultRoute == rhs.defaultRoute
    }

}

fileprivate func makeAutomato(wildcard: URL) -> AutomatoState {
    let fullPath = wildcard.absolutePathComponents + [""]
    var iterator = fullPath.makeIterator()
    return makeAutomato(iterator: &iterator)
}

fileprivate func makeAutomato(iterator: inout IndexingIterator<Array<String>>) -> AutomatoState {
    guard let part = iterator.next() else {
        return .success
    }
    if part == "*" {
        let next = makeAutomato(iterator: &iterator)
        switch next {
        case .state(let state):
            state.defaultRoute = .state(state)
            return .state(state)
        default:
            return next
        }
    } else {
        return .state(State(value: part,
                            match: makeAutomato(iterator: &iterator)))
    }
}

public class URLWildcard: CustomStringConvertible, Hashable {

    fileprivate var automato: AutomatoState
    var url: URL
    public var description: String {
        return url.absoluteString
    }
    public var hashValue: Int {
        return description.hashValue
    }

    public static func == (lhs: URLWildcard, rhs: URLWildcard) -> Bool {
        return lhs.automato == rhs.automato
    }

    init(url: URL) {
        self.url = url
        automato = makeAutomato(wildcard: url)
    }

    func match(url: URL) -> Bool {
        var automato = self.automato
        for p in url.absolutePathComponents + [""] {
            automato = automato.nextState(key: p)
        }
        switch automato {
        case .success:
            return true
        default:
            return false
        }
    }

}
