//
//  day 3.swift
//  7Days
//
//  Created by Roderick Presswood on 6/23/25.
//

import UIKit
import Combine

class ViewController3: UIViewController {
    
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This is URLSession + Codable
        let url = URL(string: "example url")
        let urlSession = URLSession.shared
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            if let data = data {
                let user = try? JSONDecoder().decode(User.self, from: data)
                print(user)
            }
        }
        task.resume()
        
        // Combine + URLSession with error handling in sink
        URLSession.shared.dataTaskPublisher(for: url!)
            .map(\.data)
            .decode(type: User.self, decoder: JSONDecoder())
            .catch { error in // error handling in combine
                Just(User(id: 0, name: "N/A"))
                
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error: \(error)") // another source of error handling
                }
            } receiveValue: { user in
                print(user)
            }
            .store(in: &cancellables)
        
        // async/await + URLSession with error handling
        Task {
            do {
                try await getUser(url: url!)
            } catch {
                print(error)
            }
            
        }
        

    }
    
    // we wouldn't use ! for try! but this is an exmple
    func getUser(url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let user = try JSONDecoder().decode(User.self, from: data)
        print(user)
    }
    
    
}


struct User: Codable {
    let id: Int
    let name: String
}
