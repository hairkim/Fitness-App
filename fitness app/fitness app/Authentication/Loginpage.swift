//
//  Login page.swift
//  fitness app
//
//  Created by Ryan Kim on 2/25/24.
//


import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @EnvironmentObject var userStore: UserStore
    @Published var email = ""
    @Published var password = ""
    
    func logIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        
        do {
            let authDataResult = try await AuthenticationManager.shared.logInUser(email: email, password: password)
            let dbUser = try await UserManager.shared.getUser(userId: authDataResult.uid)
            userStore.setCurrentUser(user: dbUser)
        } catch {
            print("Failed to sign in: \(error.localizedDescription)")
        }
        
        
    }
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var userStore: UserStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("BackgroundTop"), Color("BackgroundBottom")]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Not Kimothy's Gym") // Title
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                    
                    Image("gym_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 50)
                    
                    VStack(spacing: 20) {
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .foregroundColor(.black)
                            .background(Color("TextFieldBackground"))
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .foregroundColor(.black)
                            .background(Color("TextFieldBackground"))
                            .cornerRadius(10)
                        
                        Button(action: {
                            // Handle login button action
                            Task {
                                do {
                                    try await viewModel.logIn()
                                    showSignInView = false
                                    print("login successful")
                                } catch {
                                    print("Login error: \(error)")
                                }
                            }
                        }) {
                            Text("Login")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("LoginButtonBackground"))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 50)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 5)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("Don't have an account?")
                            .foregroundColor(.black)
                        NavigationLink(destination:
                                        SignupView(showSignInView: .constant(false))) {
                            Text("Sign Up")
                                .padding()
                                .background(Color("LoginButtonBackground"))
                                .cornerRadius(10)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, 17)
                }
                .padding()
            }
            .onTapGesture {
                // Dismiss keyboard
                UIApplication.shared.endEditing()
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView(showSignInView: .constant(false))
        }
    }
}
