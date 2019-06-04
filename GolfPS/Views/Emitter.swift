//
//  Emitter.swift
//  Instinct
//
//  Created by Greg DeJong on 11/19/18.
//  Copyright © 2018 AxonSports. All rights reserved.
//

import UIKit

class Emitter {
    static func get(with image: UIImage, scale:CGFloat) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
//        emitter.emitterShape = CAEmitterLayerEmitterShape.point
        emitter.emitterCells = generateEmitterCells(with: image, at: scale)
        return emitter
    }
    
    static func generateEmitterCells(with image:UIImage, at scale:CGFloat) -> [CAEmitterCell] {
        var cells:[CAEmitterCell] = [CAEmitterCell]()
        let cell = CAEmitterCell()
        cell.contents = image.cgImage
        cell.birthRate = 25
        cell.lifetime = 8
        cell.velocity = 150
        cell.velocityRange = 25
        cell.emissionRange = .pi * 2
//        cell.spin = 5
        cell.scale = scale
        cell.scaleRange = 0.1
        cells.append(cell)
        return cells
    }
}
