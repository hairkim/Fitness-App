//
//  SignupView.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/26/24.
//

import SwiftUI

@MainActor
final class SignupViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        
        Task {
            do {
                let returnedData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                print("success")
                print(returnedData)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

struct SignupView: View {
    @StateObject private var viewModel = SignupViewModel()
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color("BackgroundTop"), Color("BackgroundBottom")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                
                TextField("Username", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color("TextFieldBackground"))
                    .cornerRadius(10)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color("TextFieldBackground"))
                    .cornerRadius(10)
                
                
                Button(action: {
                    // Handle sign up button action
                    // Add your sign up logic here
                    print("signup successful")
                    Task {
                        do {
                            try await viewModel.logIn()
                        } catch {
                            print("Login error: \(error)")
                        }
                    }
                }) {
                    Text("Sign Up")
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("LoginButtonBackground"))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 50)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.8))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 5)
        }
        .onTapGesture {
            // Dismiss keyboard
            UIApplication.shared.endEditing()
        }
    }
}


#Preview {
    SignupView()
}
