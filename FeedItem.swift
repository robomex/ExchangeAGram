//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Tony Morales on 11/4/14.
//  Copyright (c) 2014 Tony Morales. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)


class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbnail: NSData
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber

}
