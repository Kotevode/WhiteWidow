//
//  String+RemovingFragment.swift
//  WhiteWidow
//
//  Created by Mark on 09.02.17.
//
//

import Foundation

extension String {
    
    var deletingFragment: String {
        return self.components(separatedBy: "#").first!
    }
    
}
