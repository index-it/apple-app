//
//  AddItemIntentHandler.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import Intents
import IxCoreKit
import SwiftData

class AddItemIntentHandler: INExtension, INCreateNoteIntentHandling {
    
    func resolveTitle(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult {
        if let title = intent.title {
            return INSpeakableStringResolutionResult.success(with: title)
        } else {
            return INSpeakableStringResolutionResult.needsValue()
        }
    }
    
    func resolveGroupName(for intent: INCreateNoteIntent) async -> INSpeakableStringResolutionResult {
        if let groupName = intent.groupName {
            return INSpeakableStringResolutionResult.success(with: groupName)
        } else {
            return INSpeakableStringResolutionResult.needsValue()
        }
    }
    
    func handle(intent: INCreateNoteIntent) async -> INCreateNoteIntentResponse {
        let ixApiClient = IxApiClient { _ in }
        guard let itemName = intent.title?.spokenPhrase else {
            return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }
        let itemNote = (intent.content as? INTextNoteContent)?.text
        
        guard let listName = intent.groupName?.spokenPhrase else {
            return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }
        
        do {
            let lists = try await MainActor.run {
                let modelContext = ModelContainerProvider.shared.mainContext
                return try modelContext.fetch(FetchDescriptor<IxList>())
            }
            
            var bestScore = 0.0
            var bestTrackIndex = -1
            
            for (i, list) in lists.enumerated() {
                let similarityScore = StringHelper.stringSimilarity(listName, list.name)
                if similarityScore > bestScore {
                    bestScore = similarityScore
                    bestTrackIndex = i
                }
            }
            
            guard let list = bestTrackIndex >= 0 ? lists[bestTrackIndex] : nil else {
                return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
            }
            
            let newItem = try await ixApiClient.createListItem(
                listId: list.id,
                categoryId: nil,
                name: itemName,
                link: nil,
                note: itemNote
            )
            
            await MainActor.run {
                let modelContext = ModelContainerProvider.shared.mainContext
                try? modelContext.transaction {
                    modelContext.insert(newItem)
                }
            }
            
            try? await IxSystemIntegration.handleNewEntity(IxListItemEntity(item: newItem))
            
            let response = INCreateNoteIntentResponse(code: .success, userActivity: nil)
            response.createdNote = INNote(
                title: INSpeakableString(spokenPhrase: itemName),
                contents: itemNote.map { [INTextNoteContent(text: $0)] } ?? [],
                groupName: INSpeakableString(spokenPhrase: list.name),
                createdDateComponents: DateHelper.localCalendar().dateComponents([.day, .month, .year, .hour, .minute], from: Date.now),
                modifiedDateComponents: nil,
                identifier: newItem.id
            )
            return response
        } catch {
            return INCreateNoteIntentResponse(code: .failure, userActivity: nil)
        }
    }
}
