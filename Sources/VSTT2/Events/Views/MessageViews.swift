//
//  MessageViews.swift
//
//
//  Created by Théodore Roos on 2024-03-27.
//

import Foundation
import UIKit
import AVFoundation

class CloseButton: UIView, NibLoadable {
  var onClose = {}
  override init(frame: CGRect) {
    super.init(frame: frame)
    loadFromNib()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    loadFromNib()
  }

  @IBAction func handleCloseButtonPressed(_ sender: UIButton) {
    onClose()
    superview?.removeFromSuperview()
  }
}

class MessageViews {
  static let shared = MessageViews()
  let imageView = UIImageView(frame: .zero)
  let button = CloseButton(frame: .zero)
  var type = TriggerEvent.DefaultMetaData.MessageSize.small
  var onClose = {}
  var presenting = false

  private init() {}

  //@objc func handleTap(_ gesture: UITapGestureRecognizer?) {
  //  print("Pressing background", gesture?.view)
  //  gesture?.view?.removeFromSuperview()
  //}

  func load(type: TriggerEvent.DefaultMetaData.MessageSize, imageUrl: String, view: UIView, completion: @escaping (Error?) -> ()) {
    guard !presenting else { return }
    self.type = type
    imageView.load(url: imageUrl) { (error) in
      if let error = error {
        print("Load image error", error)
        completion(error)
      } else {
        completion(nil)
        self.createMessage(view: view)
      }
    }
  }

  func createMessage(view: UIView) {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    presenting = true
    let background = UIView(frame: view.frame)
    background.backgroundColor = .black.withAlphaComponent(0.6)
    view.addSubview(background)
    background.addSubview(imageView)
    background.addSubview(button)
    //background.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))

    // Constraints
    imageView.translatesAutoresizingMaskIntoConstraints = false
    button.translatesAutoresizingMaskIntoConstraints = false
    imageView.addConstraint(item: imageView, attribute: .height, attribute: .width, multiplier: imageView.image!.size.height / imageView.image!.size.width)
    button.addConstraint(item: button, attribute: .width, attribute: .notAnAttribute, constant: 30)
    button.addConstraint(item: button, attribute: .height, attribute: .notAnAttribute, constant: 30)
    button.onClose = { [weak self] in
      self?.onClose()
      self?.presenting = false
    }
    switch type {
    case .small:
      background.addConstraint(item: imageView, attribute: .top, attribute: .topMargin)
      background.addConstraint(item: imageView, attribute: .bottom, relatedBy: .lessThanOrEqual, attribute: .bottomMargin)
      background.addConstraints(item: imageView, attributes: [.left, .right])

      background.addConstraint(item: button, attribute: .top, relatedBy: .lessThanOrEqual, toItem: imageView, attribute: .bottom, constant: 10)
      background.addConstraint(item: button, attribute: .bottom, relatedBy: .lessThanOrEqual, attribute: .bottomMargin, constant: -10)
      background.addConstraint(item: button, attribute: .centerX)
    case .big, .large:
      background.addConstraints(item: imageView, attributes: [.centerX, .centerY])
      imageView.addConstraint(item: imageView, attribute: .width, attribute: .notAnAttribute, constant: background.frame.width - 40)

      background.addConstraint(item: button, attribute: .top, relatedBy: .greaterThanOrEqual, attribute: .topMargin, constant: 10)
      background.addConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .top)
      background.addConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .right)
    }
  }
}

extension UIImageView {
  func load(url: URL, completion: @escaping (Error?) -> Void = { (_) in }) {
    DispatchQueue.global(qos: .background).async { [weak self] in
      do {
        let data = try Data(contentsOf: url)
        if let image = UIImage(data: data) {
          DispatchQueue.main.async {
            self?.image = image
            completion(nil)
          }
        }
      } catch {
        print(#function, error.localizedDescription)
        //DispatchQueue.main.async {
        //  self?.image = .noImage
        //}
        completion(error)
      }
    }
  }

  func load(url: String, completion: @escaping (Error?) -> Void = { (_) in }) {
    if let url = URL(string: url) {
      load(url: url, completion: completion)
    }
  }
}

protocol NibLoadable: AnyObject {
  var nibName: String { get }
  var nib: UINib { get }
}

extension NibLoadable {
  var nibName: String { String(describing: Self.self) }
  var nib: UINib { UINib(nibName: nibName, bundle: .module) }
}

extension NibLoadable where Self: UIView {
  func loadFromNib() {
    guard let view = nib.instantiate(withOwner: self).first as? UIView else { print("Error loading \(Self.nibName) from nib"); return }
    addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    addConstraints(item: view, attributes: [.top, .bottom, .left, .right])
  }
}

extension UIView {
  /// Make sure property translatesAutoresizingMaskIntoConstraints is set to false
  func addConstraint(item view1: UIView, attribute attr1: NSLayoutConstraint.Attribute, relatedBy: NSLayoutConstraint.Relation = .equal, toItem view2: UIView? = nil, attribute attr2: NSLayoutConstraint.Attribute? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0) {
    addConstraint(NSLayoutConstraint(item: view1, attribute: attr1, relatedBy: relatedBy, toItem: attr2 == .notAnAttribute ? nil : view2 ?? self, attribute: attr2 ?? attr1, multiplier: multiplier, constant: constant))
  }

  func addConstraints(item: UIView, attributes: [NSLayoutConstraint.Attribute]) {
    attributes.forEach { addConstraint(item: item, attribute: $0) }
  }
}
