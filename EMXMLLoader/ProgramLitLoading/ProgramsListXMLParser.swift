//
//  ProgramsListXMLParser.swift
//  EMXMLLoader
//
//  Created by Evgeny Smirnov on 31.03.2018.
//  Copyright © 2018 Evgeny Smirnov. All rights reserved.
//

import UIKit

class ProgramsListXMLParser: NSObject, XMLParserDelegate{
    
    enum Tags: String {
        case buildDate = "lastBuildDate"
        case program = "item"
        case title = "title"
        case webPage = "link"
        case description = "description"
        case sound = "guid"
        case pubDate = "pubDate"

    }
    
    unowned var delegate: ProgramsListXMLParserDelegate
    
    var isReadingElement = false
    var isReadingProgram = false
    var readingElement = ""
    
    let programBuilder = ProgramBuilder()
    var parsedPrograms = [Program]()
    
    weak var parser: XMLParser?
    
    init(delegate: ProgramsListXMLParserDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    func parse(data: Data) {
        let parser = XMLParser(data: data)
        self.parser = parser
        parser.delegate = self
        parser.parse()
    }
    
    func cancelParsing(){
        parser?.abortParsing()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        guard let elementTag = Tags.init(rawValue: elementName) else {
            return
        }
        
        switch elementTag {
        case .buildDate:
            isReadingElement = true
        case .program:
            programBuilder.reload()
            isReadingProgram = true
        default:
            if isReadingProgram {
                isReadingElement = true
            }
        }
    }
    
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if isReadingElement {
            readingElement += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        guard let elementTag = Tags.init(rawValue: elementName) else {
            return
        }
        
        switch elementTag {
        case .buildDate:
            delegate.parser(self, didParseBuildDate: readingElement.formatXMLElement())
            endReadingElement()
        case .program:
            isReadingProgram = false
            parsedPrograms.append(programBuilder.build())
            programBuilder.reload()
        case .title:
            if isReadingProgram {
                programBuilder.title = readingElement.formatXMLElement()
                endReadingElement()
            }
        case .webPage:
            if isReadingProgram{
                programBuilder.webPage = readingElement.formatXMLElement()
                endReadingElement()
            }
        case .description:
            if isReadingProgram{
                programBuilder.description = readingElement.formatXMLElement()
                endReadingElement()
            }
        case .sound:
            if isReadingProgram{
                programBuilder.sound = readingElement.formatXMLElement()
                endReadingElement()
            }
        case .pubDate:
            if isReadingProgram {
                programBuilder.pubDate = readingElement.formatXMLElement()
                endReadingElement()
            }
        }
        
    }
    
    private func endReadingElement(){
        isReadingElement = false
        readingElement = ""
    }
    
    
    func parserDidEndDocument(_ parser: XMLParser) {
        delegate.parser(self, didFinishParsing: parsedPrograms)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        delegate.parser(self, parseErrorOccurred: parseError)
    }
}



protocol  ProgramsListXMLParserDelegate: AnyObject {
    
    func parser(_ parser:ProgramsListXMLParser, didFinishParsing programs: [Program])
    
    func parser(_ parser:ProgramsListXMLParser, didParseBuildDate buildDate: String)
    
    func parser(_ parser: ProgramsListXMLParser, parseErrorOccurred parseError: Error)
}


typealias Person = (name: String, rss: URL?)

class ProgramBuilder {
    var title = ""
    var webPage: String = ""
    var description = ""
    var avatar: String = ""
    var guests = [Person]()
    var hosts = [Person]()
    var annotation: String = ""
    var sound: String = ""
    var pubDate: String = ""
    
    func reload() {
        title = ""
        webPage = ""
        description = ""
        avatar = ""
        guests.removeAll()
        hosts.removeAll()
        annotation = ""
        sound = ""
        pubDate = ""
    }
    
    func build() -> Program{
        parseDescription()
        parsePubDate()
        
        return Program(title: title,
                              webPage: webPage,
                              avatar: avatar,
                              guests: guests,
                              hosts: hosts,
                              annotation: annotation,
                              sound: sound,
                              pubDate: pubDate)
    }
    
    
    private func parseDescription() {
        if description.isEmpty { return }
        let echoURL = "https://echo.msk.ru/"

        let startIndex = description.startIndex
        let endIndex = description.endIndex
        var currentCharacterPosition = 1
        var currentCharacter: Character = "1" //placeHolder
        
        
        
        func syncCurrentCharacterValueAndPosition(){
            currentCharacter = description[description.index(startIndex, offsetBy: currentCharacterPosition)]
        }
        
        func substringHtmlStringFromCurrentCharacterTo(character: Character) -> Substring{
            
            let _startIndex = description.index(startIndex, offsetBy: currentCharacterPosition)
            let newSub =  description[_startIndex..<endIndex]
            let output = newSub.prefix(while: { (char) -> Bool in
                if (char == character){
                    return false
                }
                currentCharacterPosition += 1
                return true
            })
            return output
        }
        
        func readPersons(buffer: inout [Person]){
            let url = echoURL + String(substringHtmlStringFromCurrentCharacterTo(character: "\""))
            currentCharacterPosition += 2 // ">
            buffer.append((name: String(substringHtmlStringFromCurrentCharacterTo(character: "<")), rss: URL(string: url)))
            currentCharacterPosition += 6 // "<" or " "
            if (description[description.index(startIndex, offsetBy: currentCharacterPosition)] == " ") {
                currentCharacterPosition += 37
                readPersons(buffer: &buffer)
            }
        }
        
        //StartParsing
        syncCurrentCharacterValueAndPosition()
        
        // If there is avatar image, description starts with <img
        if currentCharacter == "i" {
            // In 99% "src=" will be at index 57
            currentCharacterPosition = 57
            
            let start = description.index(description.startIndex, offsetBy: currentCharacterPosition)
            let end = description.index(description.startIndex, offsetBy: currentCharacterPosition + 3)
            
            if description[start...end] == "src="{
                // 62 index of h in https
                currentCharacterPosition = 62
            } else {
                // Handle that strange 1%, by searching for "src="
                if let srcRange = description.range(of: "src=") {
                    currentCharacterPosition = srcRange.upperBound.encodedOffset + 1
                } else {
                    //TODO: Add ErrorHAndling found i but not found src= error
                }
            }
            
            //Found URL for avatar image. In description URL ends with " character
            avatar = String(substringHtmlStringFromCurrentCharacterTo(character: "\""))
            currentCharacterPosition += 9
        } else {
            // No Avatar image
            //Description starts with <p>
            currentCharacterPosition = 3
        }
        
        syncCurrentCharacterValueAndPosition() // currentChar is "Г"(guests) or "В"(hosts)
        
        if currentCharacter == "Г" {
            //Guests
            currentCharacterPosition += 43
            readPersons(buffer: &guests)
            currentCharacterPosition += 9 // move to "В"
            syncCurrentCharacterValueAndPosition()
        }
        
        if currentCharacter == "В" {
            //Hosts
            currentCharacterPosition += 43
            readPersons(buffer: &hosts)
        }
        
        currentCharacterPosition += 7 //"<" if there is no annotation or first letter of annotation
        syncCurrentCharacterValueAndPosition()
        
        if currentCharacter != "<"{
            let _startIndex = description.index(startIndex, offsetBy: currentCharacterPosition)
            let _endIndex = description.index(endIndex, offsetBy: -4)
            annotation = String(description[_startIndex..._endIndex])
        }
    }
    
    private func parsePubDate(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss +zzzz"
        if let date = dateFormatter.date(from: pubDate){
            dateFormatter.locale = Locale(identifier: "ru_RU")
            dateFormatter.timeZone = TimeZone.init(identifier: "UTC")
            dateFormatter.dateFormat = "EEEE, dd MMMM yyyy HH:mm"
            pubDate = dateFormatter.string(from: date)
        }
    }
}

class Program {
    
    let title: String
    let webPage: URL?
    let avatar: URL?
    let guests: [Person]
    let hosts: [Person]
    let annotation: String
    let sound: URL?
    let pubDate: String
    
    init(title: String,
         webPage: String,
         avatar: String,
         guests: [Person],
         hosts: [Person],
         annotation: String,
         sound: String,
         pubDate: String) {
        self.title = title
        self.webPage = URL(string: webPage)
        self.avatar = URL(string: avatar)
        self.guests = guests
        self.hosts = hosts
        self.annotation = annotation
        self.sound = URL(string: sound)
        self.pubDate = pubDate
    }
    
  
    
}

extension Program: CustomStringConvertible{
    var description: String {
        var str = title + "\n"
        str.append("WebPage: \(String(describing: webPage))\n")
        str.append("Avatart: \(String(describing: avatar))\n")
        str.append("Гости\n")
        for g in guests{
            str.append(g.name + "\n" + String(describing: g.rss) + "\n")
        }
        str.append("Ведущие\n")
        for h in hosts{
            str.append(h.name + "\n" + String(describing: h.rss) + "\n")
        }
        str.append("Annotation\n")
        str.append(annotation)
        str.append("Sound\n")
        str.append(String(describing: sound) + "\n")
        str.append(pubDate)
        return str
    }
    
    func printHosts(){
        var str = "Ведущие\n"
        for h in hosts{
            str.append(h.name + "\n" + String(describing: h.rss) + "\n")
        }
        print(str)
    }
    func printGuests(){
        var str = "Гости\n"
        for g in guests{
            str.append(g.name + "\n" + String(describing: g.rss) + "\n")
        }
        print(str)
    }
}


