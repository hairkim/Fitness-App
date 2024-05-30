//
//  Healthpage.swift
//  fitnessapp
//
//  Created by Ryan Kim on 5/23/24.
//
import SwiftUI
import Charts

struct HealthData: Codable {
    var height: Double?
    var weight: Double?
    var age: Int?
    var gender: String
    var activityLevel: String
    var dailyCalories: [String: Int]
    var calorieHistory: [[String: Int]] = []
    
    var bmi: Double {
        guard let height = height, let weight = weight, height > 0 else {
            return 0.0
        }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
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
        guard let weight = weight, let height = height, let age = age else {
            return 0.0
        }
        
        let bmr: Double
        if gender == "Male" {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
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

class HealthDataModel: ObservableObject {
    @Published var data: HealthData
    
    init() {
        if let savedData = UserDefaults.standard.data(forKey: "healthData"),
           let decodedData = try? JSONDecoder().decode(HealthData.self, from: savedData) {
            self.data = decodedData
        } else {
            self.data = HealthData(height: nil, weight: nil, age: nil, gender: "Male", activityLevel: "Sedentary", dailyCalories: [:])
        }
    }
    
    func save() {
        if let encodedData = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encodedData, forKey: "healthData")
        }
    }
    
    func addToHistory() {
        data.calorieHistory.append(data.dailyCalories)
        data.dailyCalories = [:]
        save()
    }
}

struct HealthView: View {
    @StateObject private var healthDataModel = HealthDataModel()
    @State private var calorieIntake: String = ""
    @State private var date = Date()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            currentWeekView
                .tabItem {
                    Label("Current Week", systemImage: "chart.bar")
                }
                .tag(0)
            
            calorieHistoryView
                .tabItem {
                    Label("Calorie History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
        }
    }
    
    var currentWeekView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Health Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
                .padding(.bottom, 10)
                
                Group {
                    Text("Personal Info")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Gender:")
                        Picker("", selection: $healthDataModel.data.gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Height (cm):")
                        TextField("N/A", text: Binding(
                            get: { healthDataModel.data.height?.description ?? "N/A" },
                            set: {
                                healthDataModel.data.height = Double($0)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Weight (kg):")
                        TextField("N/A", text: Binding(
                            get: { healthDataModel.data.weight?.description ?? "N/A" },
                            set: {
                                healthDataModel.data.weight = Double($0)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Age:")
                        TextField("N/A", text: Binding(
                            get: { healthDataModel.data.age?.description ?? "N/A" },
                            set: {
                                healthDataModel.data.age = Int($0)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    }
                }
                
                Group {
                    Text("Activity Level")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Picker("Select Activity Level", selection: $healthDataModel.data.activityLevel) {
                        ForEach(["Sedentary", "Lightly active", "Moderately active", "Very active", "Super active"], id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Group {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BMI Calculator")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("BMI: \(healthDataModel.data.bmi, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Category: \(healthDataModel.data.bmiCategory)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                }
                
                Group {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Maintenance Calories")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Calories: \(healthDataModel.data.maintenanceCalories, specifier: "%.0f") kcal/day")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                }
                
                Group {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calorie Deficit")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Deficit: \(healthDataModel.data.calorieDeficit, specifier: "%.0f") kcal/day")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                }
                
                Group {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calorie Intake")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        
                        HStack {
                            Text("Calories:")
                            TextField("N/A", text: $calorieIntake)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        Button(action: addCalorieIntake) {
                            Text("Add")
                        }
                        
                        let sortedCalories = healthDataModel.data.dailyCalories.sorted(by: { $0.key < $1.key })
                        let last7DaysCalories = sortedCalories.filter { dateString, _ in
                            if let date = dateFromString(dateString) {
                                return date >= Calendar.current.date(byAdding: .day, value: -6, to: Date())!
                            }
                            return false
                        }
                        
                        if !last7DaysCalories.isEmpty {
                            Chart {
                                ForEach(last7DaysCalories, id: \.key) { date, intake in
                                    BarMark(
                                        x: .value("Date", date),
                                        y: .value("Calories", intake)
                                    )
                                    .foregroundStyle(Color.blue)
                                }
                                
                                RuleMark(
                                    y: .value("Maintenance Calories", healthDataModel.data.maintenanceCalories)
                                )
                                .foregroundStyle(Color.red)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Maintenance: \(healthDataModel.data.maintenanceCalories, specifier: "%.0f") kcal/day")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(height: 300)
                        }
                        
                        ForEach(last7DaysCalories, id: \.key) { date, intake in
                            HStack {
                                Text(date)
                                Spacer()
                                Text("\(intake) kcal")
                                Button(action: {
                                    deleteCalorieIntake(for: date)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                }
            }
            .padding()
        }
    }
    
    var calorieHistoryView: some View {
        List {
            ForEach(healthDataModel.data.calorieHistory.indices, id: \.self) { weekIndex in
                Section(header: Text("Week \(weekIndex + 1)")) {
                    WeekGraphView(weekData: healthDataModel.data.calorieHistory[weekIndex], maintenanceCalories: healthDataModel.data.maintenanceCalories)
                }
            }
        }
    }
    
    func addCalorieIntake() {
        guard let intake = Int(calorieIntake) else {
            print("Invalid calorie intake")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none // Ensure only date is formatted
        let dateString = formatter.string(from: date)
        
        healthDataModel.data.dailyCalories[dateString] = intake
        calorieIntake = ""
        
        // Move to history if 7 days have been entered
        if healthDataModel.data.dailyCalories.count == 7 {
            healthDataModel.addToHistory()
        }
        
        healthDataModel.save()
        // Trigger view update
        healthDataModel.objectWillChange.send()
    }
    
    func deleteCalorieIntake(for date: String) {
        healthDataModel.data.dailyCalories.removeValue(forKey: date)
        healthDataModel.save()
        // Trigger view update
        healthDataModel.objectWillChange.send()
    }
    
    func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.date(from: dateString)
    }
}

struct WeekGraphView: View {
    let weekData: [String: Int]
    let maintenanceCalories: Double
    
    var body: some View {
        let sortedWeekData = weekData.sorted(by: { $0.key < $1.key })
        
        Chart {
            ForEach(sortedWeekData, id: \.key) { date, intake in
                BarMark(
                    x: .value("Date", date),
                    y: .value("Calories", intake)
                )
                .foregroundStyle(Color.blue)
            }
            
            RuleMark(
                y: .value("Maintenance Calories", maintenanceCalories)
            )
            .foregroundStyle(Color.red)
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .annotation(position: .top, alignment: .leading) {
                Text("Maintenance: \(maintenanceCalories, specifier: "%.0f") kcal/day")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(height: 300)
    }
}

struct HealthView_Previews: PreviewProvider {
    static var previews: some View {
        HealthView()
    }
}
