//
//  H6_HTMLTagName.swift
//  
//
//  Created by https://zhgchg.li on 2023/2/2.
//

import Foundation

public struct H6_HTMLTagName: HTMLTagName {
    public let string: String = WC3HTMLTagName.h6.rawValue

    public init() {
        
    }
    
    public func accept<V>(_ visitor: V) -> V.Result where V : HTMLTagNameVisitor {
        return visitor.visit(self)
    }
}
