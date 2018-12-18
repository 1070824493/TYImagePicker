//
//  DetailViewController.swift
//  ImagePickerProject
//
//  Created by ty on 2018/9/12.
//

import UIKit

class DetailViewController: UIViewController {

    var img: UIImage?
    
    @IBOutlet weak var imgView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imgView.image = img
        let tap =  UITapGestureRecognizer(target: self, action: #selector(hide))
        view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }

    @objc func hide() {
        self.dismiss(animated: true, completion: nil)
    }
    


}
