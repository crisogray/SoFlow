//
//  MapViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 15/09/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var map: MKMapView!
    var location: Location!

    func setLocation(location: Location) {
        self.location = location
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.map = MKMapView(frame: self.view.frame)
        self.map.frame.size.height -= self.navigationController!.navigationBar.frame.height + self.tabBarController!.tabBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        self.view.addSubview(self.map)
        Utility.setMapLocation(location, map: self.map)
        if location.name != nil {
            self.navigationItem.title = location.name!
        } else {
            self.navigationItem.title = "Location"
        }
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

}
