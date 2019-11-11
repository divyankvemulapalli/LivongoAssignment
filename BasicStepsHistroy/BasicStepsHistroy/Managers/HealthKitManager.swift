//
//  HealthKitManager.swift
//  BasicStepsHistroy
//
//  Created by Divyank Vemulapalli on 11/9/19.
//  Copyright © 2019 Divyank Vemulapalli. All rights reserved.
//

import Foundation

import HealthKit

class HealthKitManager {
    
    class var sharedInstance: HealthKitManager {
        struct Singleton {
            static let instance = HealthKitManager()
        }
        
        return Singleton.instance
    }
    
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
    
    let stepsUnit = HKUnit.count()
}

