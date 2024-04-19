//
//  UserManager.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/19/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    func createNewUser(auth: AuthDataResultModel) async throws {
        var userData: [ String:Any] = [
            "user_id" : auth.uid,
            "date_created" : Timestamp(),
            "email" : auth.email,
        ]
        if let photoUrl = auth.photoUrl {
            userData["photo_url"] = photoUrl
        }
        
        try await Firestore.firestore().collection("users").document(auth.uid).setData(userData, merge: false)
    }
     
}
