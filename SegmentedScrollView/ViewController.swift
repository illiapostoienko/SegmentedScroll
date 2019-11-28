//
//  ViewController.swift
//  SegmentedScrollView
//
//  Created by Illia Postoienko on 11/26/19.
//  Copyright © 2019 Illia Postoienko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private var container: SegmentedScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstPage = ColorViewController(nibName: "ColorViewController", bundle: nil)
        firstPage.setupWith(color: UIColor.brown)
        firstPage.loadViewIfNeeded()
        let secondPage = ColorViewController(nibName: "ColorViewController", bundle: nil)
        secondPage.setupWith(color: UIColor.blue)
        secondPage.loadViewIfNeeded()
        let thirdPage = ColorViewController(nibName: "ColorViewController", bundle: nil)
        thirdPage.setupWith(color: UIColor.darkGray)
        thirdPage.loadViewIfNeeded()
        let fourthPage = ColorViewController(nibName: "ColorViewController", bundle: nil)
        fourthPage.setupWith(color: UIColor.purple)
        fourthPage.loadViewIfNeeded()
        let fifthPage = ColorViewController(nibName: "ColorViewController", bundle: nil)
        fifthPage.setupWith(color: UIColor.white)
        fifthPage.loadViewIfNeeded()
        
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.setup(with: ["First": firstPage.view,
                               "Second": secondPage.view,
                               "Third": thirdPage.view,
                               "Last" : fourthPage.view,
                               "Last" : fifthPage.view],
                        normalColor: UIColor.green,
                        selectedColor: UIColor.red)
    }
}

