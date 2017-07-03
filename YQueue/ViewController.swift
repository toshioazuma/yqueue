import UIKit

class ViewController: UIViewController {
    @IBOutlet var Rest: UIButton!
    @IBOutlet var start: UIButton!
    @IBOutlet var dx: UILabel!
    
    var timer: Timer?
    var isRunning: Bool {
        get {
            // if you ever pressed the button, then after everytime the timer will be present
            return timer != nil
        }
    }
    var counter = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dx.text = String(format: "%.1f", counter)
        
        // enable only if you disabled it in XIB/Storyboard, otherwise just remove the line below
        start.isEnabled = true
    }
    
    @IBAction func play(_ sender: Any) {
        if isRunning {
            return
        }
        
        refreshTimer()
    }
    
    @IBAction func disaper(_ sender: Any) {
        // hide button when it's clicked
        Rest.isHidden = true
        
        // refresh timer/game/whatever
        refreshTimer()
        
        // setup this block to fire after 10 seconds from now
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            // only use self as weak reference for cases if user would like to go back from screen
            // or this won't deallocate the screen
            if let `self` = self {
                // return button's vision
                self.Rest.isHidden = false
            }
        }
    }
    
    func refreshTimer() {
        // invalidate timer if it exists
        if let timer: Timer = timer {
            timer.invalidate()
        }
        
        // setup new timer
        timer = Timer.scheduledTimer(timeInterval: 0.1,
                                     target: self,
                                     selector: #selector(updateTimer),
                                     userInfo: nil, repeats: true)
        
        start.isEnabled = false
    }
    
    func updateTimer() {
        counter += 0.1
        dx.text = String(format: "%.1f", counter)
    }
}
