//
//  Persistence.swift
//  fitnessapp
//
//  Created by Harris Kim on 2/26/24.
//

import Foundation
import CoreData
import CommonCrypto

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "UserData")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error.localizedDescription)")
            }
        }
    }
    
    func save(context: NSManagedObjectContext){
        do {
            try context.save()
            print("User added")
        } catch {
            print("User could not be created")
        }
    }
    
    func hashPassword(_ input: String) -> String {
        let data = Data(input.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func CreateUser(username: String, password: String, context: NSManagedObjectContext) {
        //create the user
        let user = User(context: context)
        let hashedPassword = hashPassword(password)
        user.username = username
        user.password = hashedPassword
        
        save(context: context)
    }
    
    func UserLogin(username: String, password: String, context: NSManagedObjectContext) -> Bool {
        let hashedPassword = hashPassword(password)
        
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username == %@" , username)
        
        do {
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                if user.password == hashedPassword {
                    print("User logged in")
                    return true
                } else {
                    print("Incorrect password")
                }
            } else {
                print("User does not exist")
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
        
        return false
    }
}
