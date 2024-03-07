//
//  Created by Greg DeJong on 5/20/21.
//

import XCTest
import FirebaseFirestore
import FirebaseStorage
import Photos
//@testable import Play_Sheet

class Unit_StorageTests: Unit_FirestoreTests_Base {
    
    //MARK: - Private Functions
    public func download(_ storageRef: StorageReference, expectSuccess: Bool) {
        let downloadExpectation = self.expectation(description: "Download Success")
        var downloadError:Error? = nil
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            downloadError = error
            downloadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        if expectSuccess {
            XCTAssertTrue(downloadError == nil, "Storage download error: \(downloadError!.localizedDescription)")
        } else {
            XCTAssertFalse(downloadError == nil, "Storage item incorrectly allowed to get download.")
        }
    }
    
    public func getMetadata(_ storageRef: StorageReference, expectSuccess: Bool) {
        let metadataExpectation = self.expectation(description: "Metadata Get Success")
        var metadataError:Error? = nil
        
        storageRef.getMetadata(completion: { metadata, error in
            metadataError = error
            metadataExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 10)
        if expectSuccess {
            XCTAssertTrue(metadataError == nil, "Storage metadata GET error.")
        } else {
            XCTAssertFalse(metadataError == nil, "Storage item incorrectly allowed to get metadata.")
        }
    }
    
    public func upload(_ storageRef: StorageReference, metadata:StorageMetadata? = nil, expectSuccess: Bool) {
        guard let testImage = UIImage(named: "basic_football"), let testData = testImage.jpegData(compressionQuality: 0.9) else {
            return
        }
        
        let uploadExpectation = self.expectation(description: "Upload Success")
        var uploadDidFail = false
        
        let uploadTask:StorageUploadTask = storageRef.putData(testData, metadata: metadata)
        
        uploadTask.observe(.success, handler: { (snapshot) in
            uploadExpectation.fulfill()
        })
        uploadTask.observe(.failure) { snapshot in
            uploadDidFail = true
            uploadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 15)
        if expectSuccess {
            XCTAssertTrue(uploadDidFail == false, "Storage upload error.")
        } else {
            XCTAssertFalse(uploadDidFail == false, "Storage item incorrectly allowed to upload.")
        }
    }
    
    public func delete(_ storageRef: StorageReference, expectSuccess: Bool) {
        let deleteExpectation = self.expectation(description: "Delete Success")
        var deleteError:Error? = nil
        storageRef.delete { error in
            deleteError = error
            deleteExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 15)
        if expectSuccess {
            XCTAssertTrue(deleteError == nil, "Storage delete error.")
        } else {
            XCTAssertFalse(deleteError == nil, "Incorrectly allowed to delete storage item")
        }
    }
}
