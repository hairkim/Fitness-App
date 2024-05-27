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
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    VStack {
                        Text("Plates")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        Image("plate_or_bowl")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 60) // Adjust the size as necessary
                            .foregroundColor(.white)
                            .padding(.bottom, 30)
                    }
                    
                    VStack(spacing: 15) {
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
    
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .cornerRadius(10)
                        
                        Button(action: {
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
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 50)
                    }
                   
                    
                    Spacer()
                    
                    Text("Dont be like Harris gay boy.")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.bottom, 20)
                    
                    HStack {
                        Spacer()
                        Text("Don't have an account?")
                            .foregroundColor(.white)
                        NavigationLink(destination: SignupView(showSignInView: .constant(false))) {
                            Text("Sign Up")
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, 17)
                }
                .padding()
            }
            .onTapGesture {
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
                .environmentObject(UserStore())
        }
    }
}



