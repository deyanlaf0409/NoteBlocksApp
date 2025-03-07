//
//  Note.swift
//  Late-Night Notes
//
//  Created by Deyan on 5.10.24.
//

import Foundation

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
}


struct Note: Identifiable, Codable {
    var id: UUID
    var text: String
    
    var body: String
    var media: [String]
    
    var dateCreated: Date
    var dateModified: Date
    var highlighted: Bool
    var isArchived: Bool
    var reminderDate: Date? // Optional reminder date
        var hasReminder: Bool {
            reminderDate != nil
        }
    var folderID: UUID? = nil
    var locked: Bool = false

    // Default initializer for creating new notes
    init(text: String, body: String = "", media: [String] = []) {
            self.id = UUID()
            self.text = text
            self.body = body
            self.media = media
            self.dateCreated = Date()
            self.dateModified = Date()
            self.highlighted = false
            self.isArchived = false
            self.folderID = nil
            self.locked = false
        }

    // Custom initializer for decoding notes from deep links
    init(id: UUID, text: String, body: String, media: [String], dateCreated: Date, dateModified: Date, highlighted: Bool, folderId: UUID?, locked: Bool) {
        self.id = id
        self.text = text
        
        self.body = body
        self.media = media
        
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.highlighted = highlighted
        self.isArchived = false
        self.folderID = folderId
        self.locked = locked
    }
}



