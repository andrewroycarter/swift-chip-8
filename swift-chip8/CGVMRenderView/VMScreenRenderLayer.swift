//
//  VMScreenRenderLayer.swift
//  swift-chip8
//
//  Created by Andrew Carter on 7/29/18.
//  Copyright © 2018 Andrew Carter. All rights reserved.
//

import Cocoa

final class VMScreenRenderLayer: CALayer, VirtualMachineScreenRenderer {
    
    // MARK: - Properties
    
    private var screen: [UInt8]?
    private var screenWidth: UInt16?
    private var screenHeight: UInt16?
    var shouldDrawPixelOutline = true
    var onColor = NSColor.black
    var offColor = NSColor.white
    
    override var bounds: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Instance Methods
    
    override func draw(in ctx: CGContext) {
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setShouldAntialias(false)
        
        guard let screen = screen,
            let screenWidth = screenWidth,
            let screenHeight = screenHeight else {
                return
        }
        
        let layerWidth = bounds.width
        let layerHeight = bounds.height
        let pixelWidth = layerWidth / CGFloat(screenWidth)
        let pixelHeight = layerHeight / CGFloat(screenHeight)
        
        for y in 0 ..< screenHeight {
            for x in 0 ..< screenWidth {
                let index = (y * screenWidth) + x
                let pixel = screen[Int(index)]
                let color = pixel == 1 ? onColor : offColor
                ctx.setFillColor(color.cgColor)

                ctx.addRect(CGRect(x: CGFloat(x) * pixelWidth,
                                   y: (CGFloat(screenHeight - 1) * pixelHeight) - CGFloat(y) * pixelHeight,
                                   width: pixelWidth,
                                   height: pixelHeight))
                ctx.drawPath(using: shouldDrawPixelOutline ? .fillStroke : .fill)
            }
        }
    }
    
    // MARK: - VirtualMachineScreenRenderer
    
    func render(screen: [UInt8], for machine: VirtualMachine) {
        DispatchQueue.main.async {
            self.screen = screen
            self.screenWidth = machine.screenWidth
            self.screenHeight = machine.screenHeight
            self.setNeedsDisplay()
        }
    }
    
    
}
