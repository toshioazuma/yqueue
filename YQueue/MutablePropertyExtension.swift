//
//  MutablePropertyExtension.swift
//  YQueue
//
//  Created by Aleksandr on 10/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ReactiveSwift
import Result

extension MutableProperty {
    func consumeCurrent() {
        consume(value)
    }
}
