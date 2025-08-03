//
//  SummaryTemplate.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 18.04.2024.
//

import Foundation

class SummaryTemplate: NSObject, Codable {
    
    let name: String
    let intro: String
    let ending: String
    
    init(name: String, intro: String, ending: String) {
        self.name = name
        self.intro = intro
        self.ending = ending
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SummaryTemplate else {
            return false
        }
        
        return name == object.name && intro == object.intro && ending == object.ending
    }
}

extension SummaryTemplate {
    
    static func empty() -> SummaryTemplate {
        return SummaryTemplate(name: "Empty Post", intro: "", ending: "")
    }
}
