//
//  HealthDataModelProfile.swift
//  fitnessapp
//
//  Created by Joshua Kim on 6/11/24.
//

import Foundation

struct HealthDataProfile: Codable {
    var heightFeet: Int?
    var heightInches: Int?
    var weightPounds: Double?
    var age: Int?
    var gender: String
    var activityLevel: String
    var dailyCalories: [String: Int]
    var calorieHistory: [[String: Int]] = []
    
    var heightCm: Double? {
        guard let heightFeet = heightFeet, let heightInches = heightInches else { return nil }
        let totalInches = Double(heightFeet * 12 + heightInches)
        return totalInches * 2.54
    }
    
    var weightKg: Double? {
        guard let weightPounds = weightPounds else { return nil }
        return weightPounds * 0.453592
    }
    
    var bmi: Double {
        guard let heightCm = heightCm, let weightKg = weightKg, heightCm > 0 else {
            return 0.0
        }
        let heightInMeters = heightCm / 100
        return weightKg / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<24.9:
            return "Normal weight"
        case 25..<29.9:
            return "Overweight"
        default:
            return "Obesity"
        }
    }
    
    var maintenanceCalories: Double {
        guard let weightKg = weightKg, let heightCm = heightCm, let age = age else {
            return 0.0
        }
        
        let bmr: Double
        if gender == "Male" {
            bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(age))
        }
        
        let activityMultiplier: Double
        switch activityLevel {
        case "Sedentary": activityMultiplier = 1.2
        case "Lightly active": activityMultiplier = 1.375
        case "Moderately active": activityMultiplier = 1.55
        case "Very active": activityMultiplier = 1.725
        case "Super active": activityMultiplier = 1.9
        default: activityMultiplier = 1.2
        }
        
        return bmr * activityMultiplier
    }
    
    var calorieDeficit: Double {
        return maintenanceCalories - 500
    }
}

class HealthDataModelProfile: ObservableObject {
    @Published var data: HealthDataProfile
    
    init() {
        if let savedData = UserDefaults.standard.data(forKey: "healthDataProfile"),
           let decodedData = try? JSONDecoder().decode(HealthDataProfile.self, from: savedData) {
            self.data = decodedData
        } else {
            self.data = HealthDataProfile(heightFeet: nil, heightInches: nil, weightPounds: nil, age: nil, gender: "Male", activityLevel: "Sedentary", dailyCalories: [:])
        }
    }
    
    func save() {
        if let encodedData = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encodedData, forKey: "healthDataProfile")
        }
    }
    
    func addToHistory() {
        data.calorieHistory.append(data.dailyCalories)
        data.dailyCalories = [:]
        save()
    }
}
