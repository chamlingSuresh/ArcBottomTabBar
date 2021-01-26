//
//  ArcBottomTabBar.swift
//  ArcBottomTabBar
//
//  Created by Suresh Chamling on 1/26/21.
//  Copyright © 2021 Suresh Chamling. All rights reserved.

import UIKit

protocol ArcTabBarButtonTapDelegate{
    func didSelectButtonAt(_ tabBarView: UIView, index: Int )
}

public class ArcTabBarController: UITabBarController{
    
    private var centerViewController: UIViewController?
    
    lazy var arcTabBar: ArcTabBar = {
        let tabBar = ArcTabBar(frame: self.tabBar.frame)
        return tabBar
    }()
    
    var centerButtonAction: ((_ presenter: UIViewController) -> ())?
    
    public var circleViewControllerTransitionType: centerViewControllerTransitionType = .default
    
    open override var viewControllers: [UIViewController]? {
        didSet {
            if arcTabBar.barItemTitleCollection == nil && arcTabBar.iconList == nil{
                arcTabBar.barItemTitleCollection = viewControllers?.map({$0.tabBarItem.title ?? ""})
                arcTabBar.iconList = viewControllers?.map({$0.tabBarItem.image?.scaled(to: CGSize(width: 25, height: 25)) ?? UIImage()})
                if viewControllers?.count ?? 0 >= 2 && centerViewController == nil{
                    centerViewController = viewControllers?[2]
                }
            }
        }
    }
    
    public override var selectedIndex: Int{
        didSet{
            guard selectedIndex != 0 else { return }
            arcTabBar.animatePressedButton(buttonTag: selectedIndex )
        }
    }
    
    public enum centerViewControllerTransitionType {
        case `default`
        case modal
    }
    
    public override func viewDidLoad() {
        super .viewDidLoad()
        tabBar.alpha = 0
        view.addSubview(arcTabBar)
        arcTabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arcTabBar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            arcTabBar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            arcTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor),
            arcTabBar.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor)
        ])
        arcTabBar.delegate = self
        self.view.layoutIfNeeded()
    }
}

extension ArcTabBarController: ArcTabBarButtonTapDelegate {
    func didSelectButtonAt(_ tabBarView: UIView, index: Int) {
        if index == 2 {
            switch self.circleViewControllerTransitionType {
            case .modal:
                let temporaryVC = UIViewController()
                viewControllers?[index] = temporaryVC
                self.centerButtonAction?(self)
            default:
                selectedIndex = index
            }
        } else {
            selectedIndex = index
        }
    }
}

//
// Custom TabBar View
//

class ArcTabBar: UIView{
    var delegate: ArcTabBarButtonTapDelegate?
    var barTintColor: UIColor? = .white
    var itemTintColor: UIColor? = .systemBlue
    var unselectedItemTintColor: UIColor? = .lightGray
    var centerButtonBackgroundColor: UIColor?
    
    fileprivate var maxButtonLimit = 5
    fileprivate var tabButtonViewList: [UIImageView] = []
    fileprivate var itemTitleLabelList: [UILabel] = []
    fileprivate var shapeLayer: CALayer?
    
    fileprivate var centerButtonView: UIView?
    
    var barItemTitleCollection: [String]?{
        didSet{
            
        }
    }
    
    var iconList: [UIImage]?{
        didSet{
            configureButtons()
            animatePressedButton(buttonTag: 0)
        }
    }
    
    fileprivate var buttonItemWidth: CGFloat{
        return bounds.width / CGFloat(maxButtonLimit)
    }
    fileprivate lazy var maskLayer: CAShapeLayer = {
        let maskLayer = CAShapeLayer()
        return maskLayer
    }()
    
    override init(frame: CGRect) {
        super .init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        self.addShape(in: 2, tabWidth: buttonItemWidth)
    }
    
    func addShape(in index: Int, tabWidth: CGFloat) {
        let bezierPath = UIBezierPath()
        
        bezierPath.addArc(withCenter: CGPoint(x: (tabWidth * CGFloat(index)) + tabWidth / 2, y: 0), radius: 25 + 5.0, startAngle: .pi, endAngle: 0, clockwise: false)
        
        bezierPath.append(UIBezierPath(rect: self.bounds))
        
        bezierPath.close()
        
        maskLayer.path = bezierPath.cgPath
        maskLayer.shadowOpacity = 0
        maskLayer.shadowOffset = CGSize(width:0, height:0)
        maskLayer.shadowRadius = 10
        maskLayer.shadowColor = UIColor.lightGray.cgColor
        maskLayer.shadowOpacity = 0.5
        
        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.fillColor = barTintColor?.cgColor
        maskLayer.lineWidth = 1.0
        maskLayer.backgroundColor = UIColor.clear.cgColor
        
        if layer.sublayers?.contains(maskLayer) == true {
            maskLayer.removeFromSuperlayer()
            layer.insertSublayer(maskLayer, at: 0)
        } else {
            layer.insertSublayer(maskLayer, at: 0)
        }
    }
    
    //MARK:- configure Buttons
    private func configureButtons() {
        self.clipsToBounds = false
        for (index, image) in iconList!.enumerated() {
            
            if index < maxButtonLimit{
                var minimumFrame: CGRect{
                    if index == 2{
                        return CGRect(x: (self.bounds.width / 2)-25, y:  self.bounds.origin.y - 25, width: 50, height: 50)
                    } else{
                        return CGRect(x: 0, y: 0, width: 75, height: 75)
                    }
                }
                
                let containerView = UIView(frame: minimumFrame)
                containerView.backgroundColor = .clear
                containerView.tag = index
                
                let iconView = UIImageView(image: image)
                iconView.tag = index
                iconView.image = iconView.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                iconView.contentMode = .scaleAspectFill
                
                let button = UIButton()
                button.frame = containerView.bounds
                button.tag = index
                button.translatesAutoresizingMaskIntoConstraints = false
                button.addTarget(self, action: #selector(handleButtonPress(_:)), for: .touchUpInside)
                containerView.addSubview(button)
                
                let titleLabel = UILabel()
                titleLabel.tag = index
                titleLabel.font = UIFont.systemFont(ofSize: 10)
                titleLabel.textAlignment = .center
                titleLabel.textColor = unselectedItemTintColor
                titleLabel.text = barItemTitleCollection?[index]
                
                containerView.addSubview(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    button.topAnchor.constraint(equalTo: containerView.topAnchor),
                    button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                    
                ])
                
                if index == 2 {
                    centerButtonView = containerView
                    containerView.backgroundColor = centerButtonBackgroundColor == nil ? itemTintColor : centerButtonBackgroundColor
                    iconView.tintColor = .white
                    containerView.layer.cornerRadius = ArcTabBarBaseDimension.circleViewCornerRadius
                    
                    containerView.addSubview(iconView)
                    iconView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        iconView.widthAnchor.constraint(equalToConstant: 25),
                        iconView.heightAnchor.constraint(equalToConstant: 25),
                        iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                        iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                    ])
                    
                    addSubview(titleLabel)
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        titleLabel.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -2),
                        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: buttonItemWidth * CGFloat(index)),
                        titleLabel.widthAnchor.constraint(equalToConstant: buttonItemWidth),
                    ])
                    
                    addSubview(containerView)
                    NSLayoutConstraint.activate([
                        containerView.heightAnchor.constraint(equalToConstant: ArcTabBarBaseDimension.circleViewSize.height),
                        containerView.widthAnchor.constraint(equalToConstant: ArcTabBarBaseDimension.circleViewSize.width)
                    ])
                    itemTitleLabelList.append(titleLabel)
                    tabButtonViewList.append(iconView)
                    self.layoutIfNeeded()
                    
                } else {
                    iconView.tintColor = unselectedItemTintColor
                    
                    containerView.addSubview(iconView)
                    iconView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        iconView.widthAnchor.constraint(equalToConstant: 25),
                        iconView.heightAnchor.constraint(equalToConstant: 25),
                        iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                        iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -5)
                    ])
                    
                    containerView.addSubview(titleLabel)
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -2),
                        titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                        titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
                    ])
                    
                    addSubview(containerView)
                    containerView.translatesAutoresizingMaskIntoConstraints = false
                    let leadingConstant = CGFloat(index) * buttonItemWidth
                    NSLayoutConstraint.activate([
                        containerView.widthAnchor.constraint(equalToConstant: buttonItemWidth),
                        containerView.heightAnchor.constraint(equalToConstant: ArcTabBarBaseDimension.tabBarHeight),
                        containerView.topAnchor.constraint(equalTo: topAnchor),
                        containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingConstant)
                    ])
                    
                    itemTitleLabelList.append(titleLabel)
                    tabButtonViewList.append(iconView)
                }
            }
        }
    }
    
    //MARK: - Button Action
    @objc func handleButtonPress(_ sender: UIButton){
        delegate?.didSelectButtonAt(sender, index: sender.tag)
        guard sender.tag == 0 else { return }
        animatePressedButton(buttonTag: sender.tag)
    }
    
    //MARK: - Handles button action beyond superview bounds
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let subView = centerButtonView{
            guard let translatedPoint = centerButtonView?.convert(point, from: self) else { return nil}
            
            if (subView.bounds.contains(translatedPoint)) {
                return subView.hitTest(translatedPoint, with: event)
            }
            return super.hitTest(point, with: event)
        } else { return nil }
    }
    
}

extension ArcTabBar{
    func animatePressedButton(buttonTag index: Int) {
        if index != 2{
            tabButtonViewList.forEach {
                if $0.tag != 2{
                    $0.tintColor = unselectedItemTintColor
                }
                $0.transform = .identity
            }
            itemTitleLabelList.forEach{
                if $0.tag != 2{ $0.textColor = unselectedItemTintColor }
                $0.transform = .identity
            }
        }
        
        let selectedIConView = tabButtonViewList[index]
        let selectedTitle = itemTitleLabelList[index]
        
        UIView.animate(withDuration: 0.3, animations: {
            selectedIConView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            selectedTitle.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            //            self.rotationAnimation(forView: selectedIConView)
            if index != 2{
                selectedIConView.tintColor = self.itemTintColor
                selectedTitle.textColor = self.itemTintColor
            }
        })
    }
    
    private func rotationAnimation(forView: UIView) {
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = 360 * CGFloat(Double.pi/180)
        let innerAnimationDuration : CGFloat = 0.3
        rotationAnimation.duration = Double(innerAnimationDuration)
        rotationAnimation.repeatCount = 0
        forView.layer.add(rotationAnimation, forKey: "rotateInner")
    }
}

fileprivate struct ArcTabBarBaseDimension {
    static var tabBarHeight: CGFloat {
        return 49
    }
    static var circleViewSize: CGSize {
        return CGSize(width: 50, height: 50)
    }
    static var circleViewCornerRadius: CGFloat {
        return ArcTabBarBaseDimension.circleViewSize.height / 2
    }
    static var circleViewHalfSize: CGSize {
        return CGSize(width: ArcTabBarBaseDimension.circleViewSize.width / 2, height: ArcTabBarBaseDimension
                        .circleViewSize.height / 2)
    }
}

fileprivate extension UIImage {
    func scaled(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, _: false, _: 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

