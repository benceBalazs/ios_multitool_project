//
//  CustomTableViewCell.swift
//  multitoolProject
//
//  Created by Bence Balazs on 06.02.23.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var customImage: UIImageView!
    var newImage = UIImage()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
}
