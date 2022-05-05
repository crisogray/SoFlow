//
//  MapTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 14/09/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapTableViewCell: UITableViewCell, MKMapViewDelegate {

    @IBOutlet var map: MKMapView!
    var del: CellDelegate!
    var location: Location!
    
    override func awakeFromNib() {
        self.contentView.userInteractionEnabled = false
    }
    
    func setLocation(location: Location) {
        self.location = location
        Utility.setMapLocation(self.location, map: self.map)
        self.map.delegate = self
        self.map.userInteractionEnabled = false
        self.map.scrollEnabled = false
        self.map.zoomEnabled = false
        self.map.addTap(self, action: "showMap")
    }

    func showMap() {
        let mapViewController = MapViewController()
        self.del.pushViewController(mapViewController)
        mapViewController.setLocation(location)
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if self.map.annotations.count > 0 {
            self.map.selectAnnotation(self.map.annotations.first!, animated: false)
        }
    }
    
}
