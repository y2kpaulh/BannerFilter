import UIKit
import Combine
//import PlaygroundSupport

extension UIControl {
    
    class InteractionSubscription<S: Subscriber>: Subscription where S.Input == Void {
        
        private let subscriber: S?
        private let control: UIControl
        private let event: UIControl.Event
        
        init(subscriber: S,
             control: UIControl,
             event: UIControl.Event) {
            
            self.subscriber = subscriber
            self.control = control
            self.event = event
            
            self.control.addTarget(self, action: #selector(handleEvent), for: event)
        }
        
        @objc func handleEvent(_ sender: UIControl) {
            _ = self.subscriber?.receive(())
        }
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() {}
    }
    
    struct InteractionPublisher: Publisher {
        
        typealias Output = Void
        typealias Failure = Never
        
        private let control: UIControl
        private let event: UIControl.Event
        
        init(control: UIControl, event: UIControl.Event) {
            self.control = control
            self.event = event
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
            
            let subscription = InteractionSubscription(
                subscriber: subscriber,
                control: control,
                event: event
            )
            
            subscriber.receive(subscription: subscription)
        }
    }
    
    func publisher(for event: UIControl.Event) -> UIControl.InteractionPublisher {
        
        return InteractionPublisher(control: self, event: event)
    }
    
}

//class MyViewController : UIViewController {
//    var cancellables = Set<AnyCancellable>()
//    
//    lazy var button: UIButton = {
//        let button = UIButton()
//        button.setTitle("Tap!", for: .normal)
//        button.setTitleColor(.black, for: .normal)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private func observeButtonTaps() {
//        button
//            .publisher(for: .touchUpInside)
//            .sink { _ in
//                print("Tapped")
//            }
//            .store(in: &cancellables)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.observeButtonTaps()
//    }
//    
//    override func loadView() {
//        let view = UIView()
//        view.backgroundColor = .white
//        
//        view.addSubview(button)
//        
//        NSLayoutConstraint.activate([
//            button.centerXAnchor
//                .constraint(equalTo: view.centerXAnchor),
//            button.centerYAnchor
//                .constraint(equalTo: view.centerYAnchor)
//        ])
//        
//        self.view = view
//    }
//}
//
//// Present the view controller in the Live View window
//PlaygroundPage.current.liveView = MyViewController()
