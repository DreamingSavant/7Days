//
//  Day2.swift
//  7Days
//
//  Created by Roderick Presswood on 6/22/25.
//
import UIKit
import Combine

class MVVMController: UIViewController {
    var value: String = ""
    var viewModel = ViewModel()
//    var can = ""
    // AmyCancellables - Combine substriptions must be stored or they will cancel right away
    var cancellables = Set<AnyCancellable>()
    var label = UILabel()
    
   override func viewDidLoad() {
       super.viewDidLoad()
       let publisher = Just("Hello")
       // subscriber - a thing that receives values from a publisher
       publisher.sink { value in
           print(value)
       }
       // sink - a method you use to subscribe to a publisher and handle its values
       viewModel.somePublisher
           .sink { [weak self] value in
               self?.updateUI(with: value)
           }
           .store(in: &cancellables)
       
       // assign - Automatically assigns the published value to a property
       viewModel.$name
           .map { Optional($0) }
           .assign(to: \.text, on: label)
           .store(in: &cancellables)
    }
    
    func updateUI(with text: String) {
        value = text
    }
    
    // Proper viewModel with safe closures preventing retain cycles
    class ViewModel {
        var onUpdate: (() -> Void)?
        var onFinish: (() -> Void)?
        var somePublisher = Just("Hello")
        @Published var name = ""
        @Published var text: String = ""
        
        func loadData() {
            onUpdate = { [weak self] in
                self?.doSomething()  // 🔥 Captures self strongly → potential retain cycle
            }
        }

        func doSomething() {
            print("Updating view")
        }
        
        func cleanup() {
            print("cleaned up")
        }
        
        
        // eraseToAnyPublisher - hides the exact publisher type for abstration
        func namePublisher() -> AnyPublisher<String, Never> {
            Just("Me").eraseToAnyPublisher()
        }
    }
    
    // Constructor injection DI Constructor vs Property Injection
    class UserService {
        let network: NetworkService
        
        init(network: NetworkService) {
            self.network = network
        }
    }

    // Property injection
    class ProfileViewModel {
        var userService: UserService?
    }
    class NetworkService {}
    
    //Coordinator + ViewModel Memory Trap
    class Coordinator {
        var viewModel: ViewModel?

        func start() {
            viewModel = ViewModel()
            viewModel?.onFinish = { [weak self] in
                self?.cleanup()  // 🔥 Coordinator captured in closure → cycle
            }
        }

        func cleanup() {
            print("Cleaning up")
        }
    }
    
    
}

