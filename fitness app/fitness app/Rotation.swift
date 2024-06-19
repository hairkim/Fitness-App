//
//  Rotation.swift
//  fitnessapp
//
//  Created by Ryan Kim on 6/18/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            InstructionsView()
        }
    }
}

struct InstructionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to the Workout Scheduler")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("To stay consistent and not skip a day at the gym, please select the days you would like to work out each week.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            NavigationLink(destination: WorkoutCalendarView()) {
                Text("Choose Workout Days")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
    }
}

struct WorkoutCalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDates: [Date] = []
    @State private var showConfirmDialog = false
    @State private var numberOfDaysSelected = 0
    @State private var showFinalConfirmationView = false

    private var currentMonthAndYear: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: currentDate)
    }

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let range = calendar.range(of: .day, in: .month, for: currentDate) else {
            return []
        }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        var weeks: [[Date?]] = [[]]
        guard let firstDay = daysInMonth.first else { return weeks }

        let firstWeekday = calendar.component(.weekday, from: firstDay)

        for _ in 1..<firstWeekday {
            weeks[0].append(nil)
        }

        for date in daysInMonth {
            if weeks[weeks.count - 1].count == 7 {
                weeks.append([date])
            } else {
                weeks[weeks.count - 1].append(date)
            }
        }

        while weeks[weeks.count - 1].count < 7 {
            weeks[weeks.count - 1].append(nil)
        }

        return weeks
    }

    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }

    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }

    private func dateTapped(_ date: Date) {
        if selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
            selectedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
        } else {
            if selectedDates.count >= 7 {
                selectedDates.removeFirst()
            }
            selectedDates.append(date)
        }
        print("Selected dates: \(selectedDates)")
    }

    private func confirmSelection() {
        numberOfDaysSelected = selectedDates.count
        showConfirmDialog = true
    }

    var body: some View {
        VStack {
            header
            daysOfWeek
            calendarGrid
            confirmButton
            Spacer()
        }
        .padding()
        .alert(isPresented: $showConfirmDialog) {
            Alert(
                title: Text("Confirm Selection"),
                message: Text("You have selected \(numberOfDaysSelected) days within the week. Do you want to proceed?"),
                primaryButton: .default(Text("Yes"), action: {
                    showFinalConfirmationView = true
                }),
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showFinalConfirmationView) {
            FinalConfirmationView(numberOfDaysSelected: numberOfDaysSelected, selectedDates: selectedDates)
        }
    }

    private var header: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .padding()
            }
            Spacer()
            Text(currentMonthAndYear)
                .font(.title)
                .padding()
            Spacer()
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .padding()
            }
        }
    }

    private var daysOfWeek: some View {
        HStack {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 5) {
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 5) {
                    ForEach(week, id: \.self) { date in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isDateSelected(date) ? Color.blue.opacity(0.2) : Color.white)
                                )
                                .frame(height: 50)

                            if let date = date {
                                Button(action: {
                                    dateTapped(date)
                                }) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.clear)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func isDateSelected(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        let selectedWeekdays = Set(selectedDates.map { calendar.component(.weekday, from: $0) })
        return selectedWeekdays.contains(calendar.component(.weekday, from: date))
    }

    private var confirmButton: some View {
        Button(action: confirmSelection) {
            Text("Confirm")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

struct FinalConfirmationView: View {
    let numberOfDaysSelected: Int
    let selectedDates: [Date]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Final Confirmation")
                .font(.largeTitle)
                .padding()

            Text("You have selected \(numberOfDaysSelected) days to work out each week.")
                .font(.title2)

            List {
                ForEach(selectedDates, id: \.self) { date in
                    Text("\(formattedDate(date))")
                }
            }
            .frame(height: 200)

            Button(action: {
                // Add action for the final confirmation
                print("Final confirmation complete")
            }) {
                Text("Confirm")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter.string(from: date)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
