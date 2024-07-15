//
//  ReportView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/2/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var postId: String
    var reason: String
    var additionalDetails: String?
    var timestamp: Date = Date()
}

class FirestoreService {
    private let db = Firestore.firestore()
    
    func submitReport(report: Report, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let _ = try db.collection("reports").addDocument(from: report) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }
}

struct ReportView: View {
    let post: Post
    @Binding var showReportSheet: Bool
    @State private var selectedReason: String = ""
    @State private var additionalDetails: String = ""
    
    let reasons = ["Spam", "Harassment", "Inappropriate Content", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason for Report")) {
                    Picker("Select a reason", selection: $selectedReason) {
                        ForEach(reasons, id: \.self) { reason in
                            Text(reason)
                        }
                    }
                }
                
                Section(header: Text("Additional Details")) {
                    TextField("Enter additional details (optional)", text: $additionalDetails)
                }
                
                Section {
                    Button(action: {
                        submitReport()
                    }) {
                        Text("Submit Report")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Report Post", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showReportSheet = false
            })
        }
    }
    
    private func submitReport() {
        // Submit the report to the backend
        // ...
        
        // Close the sheet
        showReportSheet = false
    }
}
