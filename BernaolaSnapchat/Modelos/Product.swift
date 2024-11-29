//
//  Product.swift
//  BernaolaSnapchat
//
//  Created by Frank Bernaola on 15/11/24.
//

import Foundation

class Product {
    var documentId: String
    var name: String
    var price: Double
    var stock: Int
    var imageUrl: String?

    init(name: String, price: Double, stock: Int, imageUrl: String? = nil, documentId: String) {
        self.name = name
        self.price = price
        self.stock = stock
        self.imageUrl = imageUrl
        self.documentId = documentId
    }
}
