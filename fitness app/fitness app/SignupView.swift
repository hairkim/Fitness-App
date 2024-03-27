//
//  SignupView.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/26/24.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
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
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color("TextFieldBackground"))
                    .cornerRadius(10)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color("TextFieldBackground"))
                    .cornerRadius(10)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color("TextFieldBackground"))
                    .cornerRadius(10)
                
                Button(action: {
                    // Handle sign up button action
                    // Add your sign up logic here
                    print("signup successful")
                    PersistenceController.shared.CreateUser(username: username, password: password, context: managedObjectContext)
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
