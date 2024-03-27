//
//  Login page.swift
//  fitness app
//
//  Created by Ryan Kim on 2/25/24.
//


import SwiftUI

struct LoginView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("BackgroundTop"), Color("BackgroundBottom")]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Ryan's Gym") // Title
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
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .foregroundColor(.black)
                            .background(Color("TextFieldBackground"))
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .foregroundColor(.black)
                            .background(Color("TextFieldBackground"))
                            .cornerRadius(10)
                        
                        Button(action: {
                            // Handle login button action
                            let success = PersistenceController.shared.UserLogin(username: username, password: password, context: managedObjectContext)
                            if success {
                                // Handle successful login
                                print("Login successful")
                                UserManager.shared.login(username: username)
                                //go to content view
                            } else {
                                // Handle failed login
                                print("Login failed")
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
                        NavigationLink(destination: SignupView().environment(\.managedObjectContext, managedObjectContext)) {
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
        LoginView()
    }
}
