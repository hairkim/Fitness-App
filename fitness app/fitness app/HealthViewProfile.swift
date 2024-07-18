//
//  HealthViewProfile.swift
//  fitnessapp
//
//  Created by Joshua Kim on 6/11/24.
//
import SwiftUI
import Charts
import Combine
import HealthKit


struct HealthViewProfile: View {
    @ObservedObject var healthDataModel: HealthDataModelProfile
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
        .accentColor(.red)
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
                        .imageScale(.large)
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Personal Info").font(.title2).fontWeight(.bold)) {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Gender:")
                            Spacer()
                            Picker("", selection: $healthDataModel.data.gender) {
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                        
                        HStack {
                            Text("Height:")
                            Spacer()
                            TextField("Feet", text: Binding(
                                get: { healthDataModel.data.heightFeet?.description ?? "" },
                                set: { healthDataModel.data.heightFeet = Int($0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            
                            TextField("Inches", text: Binding(
                                get: { healthDataModel.data.heightInches?.description ?? "" },
                                set: { healthDataModel.data.heightInches = Int($0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                        }
                        
                        HStack {
                            Text("Weight (lb):")
                            Spacer()
                            TextField("N/A", text: Binding(
                                get: { healthDataModel.data.weightPounds?.description ?? "" },
                                set: { healthDataModel.data.weightPounds = Double($0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Age:")
                            Spacer()
                            TextField("N/A", text: Binding(
                                get: { healthDataModel.data.age?.description ?? "" },
                                set: { healthDataModel.data.age = Int($0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                
                Section(header: Text("Activity Level").font(.title2).fontWeight(.bold)) {
                    Picker("Select Activity Level", selection: $healthDataModel.data.activityLevel) {
                        ForEach(["Sedentary", "Lightly active", "Moderately active", "Very active", "Super active"], id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                
                Section(header: Text("Health Metrics").font(.title2).fontWeight(.bold)) {
                    VStack(spacing: 10) {
                        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                            GridRow {
                                Text("BMI:")
                                    .fontWeight(.bold)
                                Text("\(healthDataModel.data.bmi, specifier: "%.2f")")
                            }
                            GridRow {
                                Text("Category:")
                                    .fontWeight(.bold)
                                Text(healthDataModel.data.bmiCategory)
                            }
                            GridRow {
                                Text("Maintenance Calories:")
                                    .fontWeight(.bold)
                                Text("\(healthDataModel.data.maintenanceCalories, specifier: "%.0f") kcal/day")
                            }
                            GridRow {
                                Text("Calorie Deficit:")
                                    .fontWeight(.bold)
                                Text("\(healthDataModel.data.calorieDeficit, specifier: "%.0f") kcal/day")
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                
                Section(header: Text("Calorie Intake").font(.title2).fontWeight(.bold)) {
                    VStack(spacing: 10) {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        HStack {
                            Text("Calories:")
                            Spacer()
                            TextField("N/A", text: $calorieIntake)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(width: 100)
                        }
                        
                        Button(action: addCalorieIntake) {
                            Text("Add")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
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
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
    }
    
    var calorieHistoryView: some View {
        List {
            ForEach(healthDataModel.data.calorieHistory.indices, id: \.self) { weekIndex in
                Section(header: Text("Week \(weekIndex + 1)").font(.title2).fontWeight(.bold)) {
                    WeekGraphViewProfile(weekData: healthDataModel.data.calorieHistory[weekIndex], maintenanceCalories: healthDataModel.data.maintenanceCalories)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
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

struct WeekGraphViewProfile: View {
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

struct HealthViewProfile_Previews: PreviewProvider {
    static var previews: some View {
        HealthViewProfile(healthDataModel: HealthDataModelProfile())
    }
}

class HealthViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var errorMessage: String? = nil
    @Published var stepCount: String = "0"
    @Published var caloriesBurned: String = "0"
    
    private var healthStore = HealthKitManager.shared.healthStore

    func requestAuthorization() {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAuthorized = success
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    Task {
                        await self.fetchStepCount()
                        await self.fetchCaloriesBurned()
                    }
                }
            }
        }
    }
    
    func fetchStepCount() async {
        do {
            let steps = try await getStepCount()
            DispatchQueue.main.async {
                self.stepCount = String(Int(steps))
                print("health step count: \(steps)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchCaloriesBurned() async {
        do {
            let calories = try await getCaloriesBurned()
            DispatchQueue.main.async { [weak self] in
                self?.caloriesBurned = String(format: "%.2f", calories)
                print("calories burned: \(calories)")
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    private func getStepCount() async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
                continuation.resume(throwing: NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Step Count Type is no longer available in HealthKit"]))
                return
            }

            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Date()
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let steps = sum.doubleValue(for: HKUnit.count())
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }

            healthStore.execute(query)
        }
    }
    
    private func getCaloriesBurned() async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            guard let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
                continuation.resume(throwing: NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Active Energy Burned Type is no longer available in HealthKit"]))
                return
            }

            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Date()
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("Error fetching calories burned: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let result = result, let sum = result.sumQuantity() {
                    let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    print("Calories burned: \(calories)")
                    continuation.resume(returning: calories)
                } else {
                    print("No data found for calories burned")
                    continuation.resume(returning: 0)
                }
            }

            healthStore.execute(query)
        }
    }

}



struct HealthTrackerView: View {
    @StateObject private var viewModel = HealthViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            if(viewModel.isAuthorized) {
                HStack {
                    Text("Steps")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.stepCount + " / 10,000")
                        .font(.subheadline)
                }
                .padding(.bottom, 5)
                
                Divider()
                
                HStack {
                    Text("Weight")
                        .font(.headline)
                    Spacer()
                    Text("210 lbs")
                        .font(.subheadline)
                }
                .padding(.bottom, 5)
                
                Divider()
                
                HStack {
                    Text("Exercise")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.caloriesBurned + " cal")
                        .font(.subheadline)
                }
            } else {
                Button("Request HealthKit Authorization") {
                    viewModel.requestAuthorization()
                }
            }
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            viewModel.requestAuthorization()
        }
    }
}
