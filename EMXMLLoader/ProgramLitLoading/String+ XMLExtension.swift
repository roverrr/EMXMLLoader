//
//  String+ XMLExtension.swift
//  XMLParser
//
//  Created by Evgeny Smirnov on 03.03.2018.
//  Copyright © 2018 Evgeny Smirnov. All rights reserved.
//

import Foundation

extension String {
    
    func formatXMLElement() -> String {
       return  self.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
