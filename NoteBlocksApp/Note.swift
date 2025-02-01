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
    var dateCreated: Date
    var dateModified: Date
    var highlighted: Bool
    var isArchived: Bool
    var reminderDate: Date? // Optional reminder date
        var hasReminder: Bool {
            reminderDate != nil
        }
    var folderID: UUID? = nil

    // Default initializer for creating new notes
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.dateCreated = Date()
        self.dateModified = Date()
        self.highlighted = false
        self.isArchived = false
        self.folderID = nil
    }

    // Custom initializer for decoding notes from deep links
    init(id: UUID, text: String, dateCreated: Date, dateModified: Date, highlighted: Bool, folderId: UUID?) {
        self.id = id
        self.text = text
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.highlighted = highlighted
        self.isArchived = false
        self.folderID = folderId
    }
}



