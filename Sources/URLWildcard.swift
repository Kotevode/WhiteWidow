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
    
    static func ~=(url: URL, wildcard: URLWildcard) -> Bool {
        return wildcard.match(url: url)
    }
    
}

fileprivate enum AutomatoState {
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
    
}

fileprivate class State {
    
    var value: String
    var match: AutomatoState
    var unmatch: AutomatoState
    
    init(value: String,
         match: AutomatoState = .success,
         unmatch: AutomatoState = .error) {
        self.value = value
        self.match = match
        self.unmatch = unmatch
    }
    
    func nextState(key: String) -> AutomatoState {
        return value == key ? match : unmatch
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
            state.unmatch = .state(state)
            return .state(state)
        default:
            return next
        }
    } else {
        return .state(State(value: part,
                            match: makeAutomato(iterator: &iterator)))
    }
}

class URLWildcard {
    
    fileprivate var automato: AutomatoState
    var url: URL
    
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

extension Collection where Self.Iterator.Element == URLWildcard {
    
    
    
}
