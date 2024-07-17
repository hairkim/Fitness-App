////
////  CalendarView.swift
////  fitnessapp
////
////  Created by Joshua Kim on 7/17/24.
////
//
//import SwiftUI
//
//struct CalendarView: View {
//    let posts: [Post]
//    @State private var currentDate = Date()
//    
//    private var dates: [Date] {
//        var dates: [Date] = []
//        let calendar = Calendar.current
//        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
//        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
//        for day in range {
//            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
//                dates.append(date)
//            }
//        }
//        return dates
//    }
//    
//    private func postForDate(_ date: Date) -> [Post] {
//        return posts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
//    }
//    
//    private func changeMonth(by offset: Int) {
//        let calendar = Calendar.current
//        if let newDate = calendar.date(byAdding: .month, value: offset, to: currentDate) {
//            currentDate = newDate
//        }
//    }
//    
//    private var monthYearFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM yyyy"
//        return formatter
//    }
//    
//    private var daysOfWeek: [String] {
//        let formatter = DateFormatter()
//        return formatter.shortWeekdaySymbols
//    }
//    
//    private var startDayOffset: Int {
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.year, .month], from: currentDate)
//        let firstDayOfMonth = calendar.date(from: components)!
//        return calendar.component(.weekday, from: firstDayOfMonth) - calendar.firstWeekday
//    }
//    
//    var body: some View {
//        VStack {
//            HStack {
//                Button(action: {
//                    changeMonth(by: -1)
//                }) {
//                    Image(systemName: "chevron.left")
//                }
//                Spacer()
//                Text(monthYearFormatter.string(from: currentDate))
//                    .font(.headline)
//                Spacer()
//                Button(action: {
//                    changeMonth(by: 1)
//                }) {
//                    Image(systemName: "chevron.right")
//                }
//            }
//            .padding()
//            
//            HStack {
//                ForEach(daysOfWeek, id: \.self) { day in
//                    Text(day)
//                        .font(.subheadline)
//                        .frame(maxWidth: .infinity)
//                }
//            }
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
//                ForEach(0..<startDayOffset, id: \.self) { _ in
//                    Rectangle()
//                        .fill(Color.clear)
//                        .frame(height: 50)
//                }
//                
//                ForEach(dates, id: \.self) { date in
//                    VStack {
//                        if let post = postForDate(date).first {
//                            NavigationLink(destination: SeshView(post: post)) {
//                                AsyncImage(url: URL(string: post.imageName)) { phase in
//                                    switch phase {
//                                    case .empty:
//                                        Rectangle()
//                                            .fill(Color.gray.opacity(0.5))
//                                    case .success(let image):
//                                        image
//                                            .resizable()
//                                            .aspectRatio(contentMode: .fill)
//                                            .frame(width: 40, height: 50) // Set fixed size for image
//                                            .clipped()
//                                    case .failure:
//                                        Rectangle()
//                                            .fill(Color.red.opacity(0.5))
//                                    @unknown default:
//                                        Rectangle()
//                                            .fill(Color.gray.opacity(0.5))
//                                    }
//                                }
//                                .frame(width: 40, height: 50) // Set fixed size for image container
//                                .cornerRadius(10)
//                            }
//                        } else {
//                            Text("\(Calendar.current.component(.day, from: date))")
//                                .font(.system(size: 14, weight: .medium))
//                                .frame(width: 40, height: 50) // Set fixed size for text container
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(10)
//                        }
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//}
//
