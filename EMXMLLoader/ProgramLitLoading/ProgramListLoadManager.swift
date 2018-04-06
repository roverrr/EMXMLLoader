//
//  ProgramListLoadManager.swift
//  EMXMLLoader
//
//  Created by Evgeny Smirnov on 28.03.2018.
//  Copyright © 2018 Evgeny Smirnov. All rights reserved.
//

import Foundation


typealias ProgramsList = (programs: [Program], buildDate: String)

typealias loaderCallback = (_ programs: ProgramsList?, _ error: ProgramsListLoadError?) -> Void

enum ProgramsListLoadError: Error{
    case invalidResponseCode(code: Int)
    case sessionError(error: Error)
    case noDataReceived
    case unknownResponse
}


class ProgramsListLoadManager {

    static let shared = ProgramsListLoadManager()
    
    lazy private var xmlSession: URLSession = {
        return URLSession(configuration: .ephemeral)
    }()
    
    private var activeLoadTasks = [Int: (loader: ProgramsListLoader, callback: loaderCallback)]()
    private init(){
        
    }
    
    
    func loadProgramsListFrom(xmlLink url: URL, completionHandler: @escaping (_ programs: ProgramsList?, _ error: ProgramsListLoadError?)->Void){
        
        let id = url.hashValue
        if var activeLoadTask = activeLoadTasks[id]{
            activeLoadTask.callback = completionHandler
            activeLoadTasks[id] = activeLoadTask
        } else {
            let loader = ProgramsListLoader(id: id,
                                            session: xmlSession,
                                            delegate: self)
            activeLoadTasks[id] = (loader, completionHandler)
            loader.startLoading(fromUrl: url)
        }
        
    }
    
    private func finishTask(id: Int, programs: ProgramsList?, error: ProgramsListLoadError?){
        
        DispatchQueue.main.async {
            
            if let callback = self.activeLoadTasks[id]?.callback {
                callback(programs, error)
                self.activeLoadTasks[id] = nil
            }
        }
    }
}

  extension ProgramsListLoadManager: ProgramsListLoaderDelegate {
    
    func loader(_ loader: ProgramsListLoader, loadingErrorOccurred error: ProgramsListLoadError) {
        
        finishTask(id: loader.id, programs: nil, error: error)
    }
    
    func loader(_ loader: ProgramsListLoader, didFinishLoading programsList: ProgramsList) {
        finishTask(id: loader.id, programs: programsList, error: nil)
    }
}












