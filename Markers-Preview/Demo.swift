//
//  Demo.swift
//  SMARTMarkers Instruments
//
//  Created by Raheel Sayeed on 9/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMARTMarkers
import ResearchKit
import SMART

extension SMART.Server {
    
    class func Demo() -> Server {
        let srv = Server(baseURL: URL(string: "https://r4.smarthealthit.org/")!)
        srv.name = "SMART Health IT"
        return srv
    }
}


extension Date {
    
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }

}
