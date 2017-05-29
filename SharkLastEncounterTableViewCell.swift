//
//  SharkLastEncounterTableViewCell.swift
//  MaldivesWhaleSharkResearch
//
//  Created by mac on 5/9/17.
//  Copyright © 2017 dooddevelopments. All rights reserved.
//

import UIKit
import MapKit

class SharkLastEncounterTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var lastEncounterDateLabel: UILabel!
    @IBOutlet weak var lastEncounterLengthLabel: UILabel!
    @IBOutlet weak var lastEncounterSeenByLabel: UILabel!
    @IBOutlet weak var lastEncounterMapView: MKMapView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
