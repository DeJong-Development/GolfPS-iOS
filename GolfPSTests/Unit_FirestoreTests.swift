//
//  Created by Greg DeJong on 5/20/21.
//

import XCTest
import Firebase
import FirebaseFirestore

enum UserType {
    case headCoachTeamA, assistantCoachTeamA, headCoachTeamB, assistantCoachTeamB, anonymous, noTeam
    
    var userId:String {
        switch self {
            case .noTeam:
                return "vRgDRKZCzqA87NXwxJ7XH3WdJuSK"
            case .headCoachTeamA:
                return "cpZxHuLlSBfirWnwkKsJnAjLjuLD"
            case .assistantCoachTeamA:
                return "Rye2DrJgzWTtyJLswCk410eCBfaD"
            case .headCoachTeamB:
                return "ZIdSPdnEPeYEEcqCOaZ2UyTEkFPm"
            case .assistantCoachTeamB:
                return "3KXYhkiB7lGWWxH2gJP868DW8hAa"
            case .anonymous:
                return "PqqBbX1OziLhm518TDmj0ZRNT6vm"
        }
    }
    var email:String {
        switch self {
            case .headCoachTeamA:
                return "headcoach@teama.com"
            case .assistantCoachTeamA:
                return "assistant@teama.com"
            case .headCoachTeamB:
                return "headcoach@teamb.com"
            case .assistantCoachTeamB:
                return "assistant@teamb.com"
            case .anonymous:
                return ""
            case .noTeam:
                return "coach@noteam.com"
        }
    }
    var password:String {
        return "testtest"
    }
    
    var teamId:String {
        switch self {
            case .headCoachTeamA, .assistantCoachTeamA:
                return "aJGBl6dZIEA1dDLrNrfl"
            case .headCoachTeamB, .assistantCoachTeamB:
                return "MTBfmfCGY9Tjj15FZXEz"
            case .anonymous, .noTeam:
                return ""
        }
    }
    var userDoc:DocumentReference {
        return Firestore.firestore().collection("users").document(userId)
    }
}

class Unit_FirestoreTests_Base: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        //can we make sure the emulator is started? trigger a script?
        
        //Launch arguments are passed in via the scheme
        //app.launchArguments = ["testing", "NoAnimations"]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    //MARK: - Public Functions
    
    func signIn(withUserType userType: UserType) {
        signIn(withEmail: userType.email, withPassword: userType.password)
        
        guard let userId = Auth.auth().currentUser?.uid, userId == userType.userId else {
            return
        }
    }
    
    func register(withEmail email: String, withPassword password: String) -> String? {
        let registerExpectation = self.expectation(description: "Registration Success")
        
        var registerError:Error? = nil
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            registerError = error
            registerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        XCTAssertTrue(registerError == nil, "User registration error.")
        
        return Auth.auth().currentUser?.uid
    }
    
    func signIn(withEmail email: String, withPassword password: String) {
        let signInExpectation = self.expectation(description: "Sign In Success")
        
        var signInError:Error? = nil
        Auth.auth().signIn(withEmail: email, password: password) {(authResult, error) in
            signInError = error
            signInExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        XCTAssertTrue(signInError == nil, "User sign in error.")
        
        guard (Auth.auth().currentUser?.uid) != nil else {
            return
        }
    }
    
    func createDoc(_ documentRef: DocumentReference, data: [String: Any] = ["test": "Create"], doesExpectSuccess: Bool) {
        let creationExpectation = self.expectation(description: "Creation Success")
        var createError:Error? = nil
        documentRef.setData(data) { error in
            createError = error
            creationExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(createError == nil, "Incorrectly blocked from creating doc")
        } else {
            XCTAssertFalse(createError == nil, "Incorrectly allowed to create doc")
        }
    }
    
    func createDocInCollection(_ collectionRef: CollectionReference, data: [String: Any] = ["test": "Create"], doesExpectSuccess: Bool) -> DocumentReference? {
        let creationExpectation = self.expectation(description: "Creation Success")
        var createError:Error? = nil
        let createdDoc = collectionRef.addDocument(data: data) { error in
            createError = error
            creationExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(createError == nil, "Incorrectly blocked from creating doc")
            return createdDoc
        } else {
            XCTAssertFalse(createError == nil, "Incorrectly allowed to create doc")
            return nil
        }
    }
    
    func readDoc(_ docRef: DocumentReference, doesExpectSuccess: Bool) {
        let readExpectation = self.expectation(description: "Read Success")
        var readError:Error? = nil
        docRef.getDocument { snapshot, error in
            readError = error
            readExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(readError == nil, "Incorrectly blocked from reading doc")
        } else {
            XCTAssertFalse(readError == nil, "Incorrectly allowed to read doc")
        }
    }
    
    func getDoc(_ docRef: DocumentReference, doesExpectSuccess: Bool) -> [String:Any]? {
        let readExpectation = self.expectation(description: "Get Success")
        var readData:[String:Any]!
        var readError:Error? = nil
        docRef.getDocument { snapshot, error in
            readError = error
            readData = snapshot?.data()
            readExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(readError == nil, "Incorrectly blocked from reading doc")
        } else {
            XCTAssertFalse(readError == nil, "Incorrectly allowed to read doc")
        }
        return readData
    }
    
    func editDoc(_ docRef: DocumentReference, data: [String: Any]? = nil, doesExpectSuccess: Bool) {
        let editExpectation = self.expectation(description: "Edit Success")
        var editError:Error? = nil
        let editData = data ?? ["updatedAt": Timestamp()]
        docRef.updateData(editData) { error in
            editError = error
            editExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(editError == nil, "Incorrectly blocked from editing doc")
        } else {
            XCTAssertFalse(editError == nil, "Incorrectly allowed to edit doc")
        }
    }
    
    func setDoc(_ docRef: DocumentReference, data: [String: Any]? = nil, doesExpectSuccess: Bool) {
        let setExpectation = self.expectation(description: "Set Success")
        var setError:Error? = nil
        let setData = data ?? ["updatedAt": Timestamp()]
        docRef.setData(setData) { error in
            setError = error
            setExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(setError == nil, "Incorrectly blocked from setting doc")
        } else {
            XCTAssertFalse(setError == nil, "Incorrectly allowed to set doc")
        }
    }
    
    func listDocs(_ query: Query, doesExpectSuccess: Bool) -> [QueryDocumentSnapshot]? {
        let listExpectation = self.expectation(description: "List Success")
        var listError:Error? = nil
        var discoveredDocuments:[QueryDocumentSnapshot]?
        query.getDocuments { snapshot, error in
            discoveredDocuments = snapshot?.documents
            listError = error
            listExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(listError == nil, "Incorrectly blocked from listing docs in collection")
        } else {
            XCTAssertFalse(listError == nil, "Incorrectly allowed to list docs in collection")
        }
        return discoveredDocuments
    }
    
    func deleteDoc(_ docRef: DocumentReference, doesExpectSuccess: Bool) {
        let deleteExpectation = self.expectation(description: "Delete Success")
        var deleteError:Error? = nil
        docRef.delete(completion: { error in
            deleteError = error
            deleteExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5)
        if doesExpectSuccess {
            XCTAssertTrue(deleteError == nil, "Incorrectly blocked from deleting doc")
        } else {
            XCTAssertFalse(deleteError == nil, "Incorrectly allowed to delete doc")
        }
    }
    
    func deleteCurrentUser() {
        let deleteExpectation = self.expectation(description: "Delete Auth User Success")
        var deleteError:Error? = nil
        Auth.auth().currentUser!.delete { error in
            deleteError = error
            deleteExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        XCTAssertTrue(deleteError == nil, "Incorrectly blocked from deleting auth user")
    }
}
