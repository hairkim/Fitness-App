//
//  Login page.swift
//  fitness app
//
//  Created by Ryan Kim on 2/25/24.
//

import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    private let userStore: UserStore
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    
    init(userStore: UserStore) {
        self.userStore = userStore
    }
    
    func logIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter email and password."
            return
        }
        
        do {
            let authDataResult = try await AuthenticationManager.shared.logInUser(email: email, password: password)
            let dbUser = try await UserManager.shared.getUser(userId: authDataResult.uid)
            userStore.setCurrentUser(user: dbUser)
        } catch {
            errorMessage = "Login failed. Try again."
        }
    }
}

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject var userStore: UserStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var showSignInView: Bool
    
    init(showSignInView: Binding<Bool>, userStore: UserStore) {
        self._showSignInView = showSignInView
        self._viewModel = StateObject(wrappedValue: LoginViewModel(userStore: userStore))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    VStack {
                        Text("Plates")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.bottom, 20)
                        
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.black)
                            .padding(.bottom, 10)
                        
                        Image("plate_or_bowl")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 60) // Adjust the size as necessary
                            .foregroundColor(.black)
                            .padding(.bottom, 30)
                    }
                    
                    VStack(spacing: 15) {
                        TextField("Email", text: $viewModel.email)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $viewModel.password)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.logIn()
                                if viewModel.errorMessage == nil {
                                    showSignInView = false
                                    print("user logged in")
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
                    
                    HStack {
                        Spacer()
                        Text("Don't have an account?")
                            .foregroundColor(.black)
                        NavigationLink(destination: SignupView(showSignInView: .constant(false))) {
                            Text("Sign Up")
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                        .padding(.trailing, 53)
                    }
                    .padding(.bottom, 17)
                }
                .padding()
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .navigationBarBackButtonHidden(true)
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
            LoginView(showSignInView: .constant(false), userStore: UserStore())
                .environmentObject(UserStore())
        }
    }
}
