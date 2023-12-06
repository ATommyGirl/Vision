//
//  BCAnimationButton.swift
//  YYVision
//
//  Created by YYLittleCat on 2023/12/4.
//

import UIKit

class BCAnimationButton: UIButton {

    var payload: String?
    var circle: UIImageView!
    var originalPosition: CGPoint = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        circle = UIImageView(image: UIImage(named: "arrow_icon"))
        circle.backgroundColor = .white
        circle.layer.masksToBounds = true
        setCircleStatusBeforeAnimate()
        addSubview(circle)
        setAnimation(delayTime: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        originalPosition = circle.center
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setAnimation(delayTime: Int) {
        UIView.animate(withDuration: 0.8, delay: TimeInterval(delayTime), options: .repeat, animations: {
            self.setCircleStatusAfterAnimate()
        }) { _ in
            self.setCircleStatusBeforeAnimate()
        }
    }

    func setCircleStatusBeforeAnimate() {
        circle.frame = beforeAnimateFrame()
        circle.layer.cornerRadius = circle.frame.height / 2
    }

    func setCircleStatusAfterAnimate() {
        circle.frame = afterAnimateFrame()
        circle.layer.cornerRadius = circle.frame.height / 2
    }

    func beforeAnimateFrame() -> CGRect {
        return frame
    }

    func afterAnimateFrame() -> CGRect {
        return CGRect(x: 3, y: 3, width: frame.width - 6, height: frame.height - 6)
    }

    @objc func applicationDidEnterBackground() {
        circle.layer.removeAllAnimations()
    }

    @objc func applicationWillEnterForeground() {
        circle.center = originalPosition
        setAnimation(delayTime: 0)
    }
}

