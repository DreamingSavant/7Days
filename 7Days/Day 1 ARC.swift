//
//  ViewController.swift
//  7Days
//
//  Created by Roderick Presswood on 6/20/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    /*What is ARC?
    •    ARC automatically manages memory in Swift by tracking how many strong references exist to a class instance.
    •    When no strong references remain, the object is deallocated.
    */
    
    /*
    ✅ 2. Strong Reference
        •    The default reference type.
        •    Increments the retain count.
        •    If two objects hold strong references to each other → retain cycle.
     */
    /* Ex */ var person: Person? = Person()
    
    /*
     •    Happens when two objects strongly reference each other, so neither gets deallocated.
     •    Common in:
     •    Delegates (delegate should never be strong)
     •    Closures capturing self
     */
    class A {
        var b: B?
    }
    class B {
        var a: A? // <- if this is strong, retain cycle
    }
    
    
    
    /*
     4. Weak Reference
        •    Doesn’t increase retain count.
        •    Automatically set to nil when the referenced object deallocates.
        •    Must be optional.
        •    Perfect for delegates and parent references.
     */
    /*Ex*/ weak var delegate: MyDelegate?
    
    /*
     5. Unowned Reference
         •    Like weak but:
         •    Non-optional
         •    Crashes if accessed after deallocation
         •    Use only if you’re sure the reference will always exist while being used.
     */
    /*Ex*/ unowned let owner: Owner! = nil
    
    /*
     6. ARC in Closures
         •    Closures capture variables strongly by default.
         •    If self is captured strongly → retain cycle.
     */
    /* Ex*/
    class ViewModel {
        var onUpdate: (() -> Void)?
        
        func doSomething() {}
        func load() {
            onUpdate = {
                self.doSomething() // Captures self strongly
            }
        }
        // Fix with capture list
        func loadWithoutStrongSelf() {
            onUpdate = { [weak self] in
                self?.doSomething()
            }
        }
    }
    
    /*
     7. Deinit
         •    Special method called when an object is deallocated.
         •    Great for logging object lifetime during debugging.
     */
    deinit {
        person = nil
        print("Object deinitilized")
    }
    
    /*
     8. Tools to Debug ARC
         •    Instruments > Leaks
         •    Xcode memory graph debugger
         •    print("deinit") in classes to verify release
     */
}

class Person {}
protocol MyDelegate: AnyObject { func helloWorld()}
class Owner {}
