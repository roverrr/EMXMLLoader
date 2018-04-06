//
//  ViewController.swift
//  EMXMLLoader
//
//  Created by Evgeny Smirnov on 23.03.2018.
//  Copyright © 2018 Evgeny Smirnov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  
    private let latesProgramsURL = URL(string: "https://echo.msk.ru/interview/rss-audio.xml")!

    
    var _parser: ProgramsListXMLParser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        if let path = Bundle.main.path(forResource: "echo", ofType:"xml") {
//            let data =  try! Data.init(contentsOf: URL(fileURLWithPath: path))
//            let parser = ProgramsListXMLParser(delegate: self)
//            _parser = parser
//            parser.parse(data: data)
//        }
        
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: latesProgramsURL) { (data, response, error) in
            if data != nil {
                if let httpResponse = response as? HTTPURLResponse{
                    print(httpResponse.statusCode)
                }
                print(data!)
            }
        }.resume()
    }
        
    
    @IBAction func tap1(_ sender: Any) {
        
        let loadManager = ProgramsListLoadManager.shared
        loadManager.loadProgramsListFrom(xmlLink: latesProgramsURL) { (programsList, error) in
            
            assert(error == nil, error!.localizedDescription) // Change to UI message
            
            for program in programsList!.programs {
                print(program)
                print("---------")
            }
            
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


