//
//  SignupView.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/26/24.
//

import SwiftUI
import FirebaseAuth

@MainActor
final class SignupViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    @Published var isPasswordVisible = false
    @Published var errorMessage = ""

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password must not be empty."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        do {
            let returnedData = try await AuthenticationManager.shared.createUser(email: email, password: password)
            let user = DBUser(auth: returnedData, username: username)
            try await UserManager.shared.createNewUser(user: user)

            errorMessage = "Success"
            await sendEmailVerification()
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    func sendEmailVerification() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        do {
            try await currentUser.sendEmailVerification()
            errorMessage = "Verification email sent. Please check your email."
        } catch {
            errorMessage = "Error sending verification email: \(error.localizedDescription)"
        }
    }
}

struct SignupView: View {
    @StateObject private var viewModel = SignupViewModel()
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundBeige")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Spacer().frame(height: 30)
                    
                    Text("Sign up")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 10)
                    
                    Text("Create your account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    VStack(spacing: 15) {
                        TextField("Username", text: $viewModel.username)
                            .padding()
                            .background(Color("TextFieldBackground"))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .autocapitalization(.none)
                            .overlay(
                                HStack {
                                    Spacer()
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 10)
                                }
                            )
                        
                        TextField("Email", text: $viewModel.email)
                            .padding()
                            .background(Color("TextFieldBackground"))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .autocapitalization(.none)
                            .overlay(
                                HStack {
                                    Spacer()
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 10)
                                }
                            )
                        
                        Group {
                            if viewModel.isPasswordVisible {
                                TextField("Password", text: $viewModel.password)
                                    .padding()
                                    .background(Color("TextFieldBackground"))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            Image(systemName: "lock")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 10)
                                            Button(action: {
                                                viewModel.isPasswordVisible.toggle()
                                            }) {
                                                Image(systemName: "eye.slash")
                                                    .foregroundColor(.gray)
                                                    .padding(.trailing, 10)
                                            }
                                        }
                                    )
                                
                                TextField("Confirm Password", text: $viewModel.confirmPassword)
                                    .padding()
                                    .background(Color("TextFieldBackground"))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 10)
                                            Button(action: {
                                                viewModel.isPasswordVisible.toggle()
                                            }) {
                                                Image(systemName: "eye.slash")
                                                    .foregroundColor(.gray)
                                                    .padding(.trailing, 10)
                                            }
                                        }
                                    )
                            } else {
                                SecureField("Password", text: $viewModel.password)
                                    .padding()
                                    .background(Color("TextFieldBackground"))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            Image(systemName: "lock")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 10)
                                            Button(action: {
                                                viewModel.isPasswordVisible.toggle()
                                            }) {
                                                Image(systemName: "eye")
                                                    .foregroundColor(.gray)
                                                    .padding(.trailing, 10)
                                            }
                                        }
                                    )
                                
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                    .padding()
                                    .background(Color("TextFieldBackground"))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 10)
                                            Button(action: {
                                                viewModel.isPasswordVisible.toggle()
                                            }) {
                                                Image(systemName: "eye")
                                                    .foregroundColor(.gray)
                                                    .padding(.trailing, 10)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(viewModel.errorMessage == "Success" ? .green : .red)
                            .padding()
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.signUp()
                            if viewModel.errorMessage == "Success" {
                                showSignInView = false
                            }
                        }
                    }) {
                        Text("Sign up")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 50)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        NavigationLink(destination: LoginView(showSignInView: .constant(false), userStore: UserStore())) {
                            Text("Login")
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
    }
}

#Preview {
    SignupView(showSignInView: .constant(false))
}
