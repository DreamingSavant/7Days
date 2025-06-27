//
//  Day5 + 1.swift
//  7Days
//
//  Created by Roderick Presswood on 6/26/25.
//

import CoreData
import UIKit
import SwiftData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager() // singleton instance
    // Setup Core Data stack (normally in AppDelegate or a CoreDataManager)
    let persistentContainer: NSPersistentContainer
    
    private init() {
        // Initalize Core Data stack with NotesModel.xcdatamodelId
        persistentContainer = NSPersistentContainer(name: "NotesModel")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Cpre Data load failed: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // CRUD Operations
    // Create
    func addNote(title: String) {
        let context = persistentContainer.viewContext
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue(title, forKey: "title")
        note.setValue(Date(), forKey: "createdAt")
        try? context.save()
    }


    // Read
    func fetchNotes() -> [NSManagedObject] {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return(try? context.fetch(request)) ?? []
    }

    //Update
    func updateNote(note: NSManagedObject, newTitle: String) {
        note.setValue(newTitle, forKey: "title")
        try? persistentContainer.viewContext.save()
    }

    // Delete
    func deleteNote(note: NSManagedObject) {
        let context = persistentContainer.viewContext
        context.delete(note)
        try? context.save()
    }
}



@Model
class SwiftUINote {
    var title: String
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.createdAt = Date()
    }
}

struct NotesView: View {
    @Query(sort: \SwiftUINote.createdAt, order: .reverse) var notes: [SwiftUINote]
    @Environment(\.modelContext) private var modelContext
    @State private var newTitle: String = ""
    
    var body: some View {
        VStack {
            TextField("New note", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Add Note") {
                let note = SwiftUINote(title: newTitle)
                modelContext.insert(note)
                newTitle = ""
            }
            
            List {
                ForEach(notes) { note in
                    Text(note.title)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(notes[index])
                    }
                }
            }
        }
    }
}

#Preview {
    NotesView()
}
