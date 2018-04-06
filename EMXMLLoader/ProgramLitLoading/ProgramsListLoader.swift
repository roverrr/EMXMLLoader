//
//  ProgramsListLoader.swift
//  EMXMLLoader
//
//  Created by Evgeny Smirnov on 30.03.2018.
//  Copyright © 2018 Evgeny Smirnov. All rights reserved.
//

import Foundation



protocol ProgramsListLoaderDelegate: AnyObject {
    
    func loader(_ loader: ProgramsListLoader, loadingErrorOccurred error: ProgramsListLoadError) -> Void
    func loader(_ loader: ProgramsListLoader, didFinishLoading programsList: ProgramsList) -> Void

}

class ProgramsListLoader: NSObject {
    
    let id: Int
    unowned let session: URLSession
    weak var delegate: ProgramsListLoaderDelegate?
    private var parsedBuildDate: String = ""
    

    
    init(id: Int, session: URLSession, delegate: ProgramsListLoaderDelegate?) {
        self.id = id
        self.session = session
        self.delegate = delegate
    }
    
    func startLoading(fromUrl url: URL){
        
        parsedBuildDate = ""
        session.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                self.delegate?.loader(self, loadingErrorOccurred: ProgramsListLoadError.sessionError(error: error))
            } else if let httpResponse = response as? HTTPURLResponse{
                if httpResponse.statusCode == 200{
                    if data != nil {
                        let parser = ProgramsListXMLParser(delegate: self)
                        parser.parse(data: data!)
                    } else{
                        self.delegate?.loader(self, loadingErrorOccurred: ProgramsListLoadError.noDataReceived)
                    }
                } else {
                    self.delegate?.loader(self, loadingErrorOccurred: ProgramsListLoadError.invalidResponseCode(code: httpResponse.statusCode))
                }
            } else {
                self.delegate?.loader(self, loadingErrorOccurred: ProgramsListLoadError.unknownResponse)
            }
        }.resume()
    }
}

extension ProgramsListLoader: ProgramsListXMLParserDelegate {
    
    func parser(_ parser: ProgramsListXMLParser, didParseBuildDate buildDate: String) {
        //Check Cache
        parsedBuildDate = buildDate
        print("BuildDate: \(parsedBuildDate)")
    }
    
    func parser(_ parser: ProgramsListXMLParser, didFinishParsing programs: [Program]) {
        delegate?.loader(self, didFinishLoading: (programs: programs, buildDate: parsedBuildDate))
    }
    
    func parser(_ parser: ProgramsListXMLParser, parseErrorOccurred parseError: Error) {
        //
        print("error:" + parseError.localizedDescription)

    }
}



