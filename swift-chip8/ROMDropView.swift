//
//  ROMDropView.swift
//  swift-chip8
//
//  Created by Andrew Carter on 7/29/18.
//  Copyright © 2018 Andrew Carter. All rights reserved.
//

import Cocoa

@objc protocol ROMDropViewDelegate: class {
    func didReceive(_ url: URL, in view: ROMDropView)
}

final class ROMDropView: NSView {
    
    // MARK: - Properties
    
    @IBOutlet weak var delegate: ROMDropViewDelegate?
    private let pasteboardType = NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")
    private let fileExtension = "ch8"
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL,
                                 NSPasteboard.PasteboardType.fileURL])
    }
    
    // MARK: - Overrides
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) {
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard().propertyList(forType: pasteboardType) as? NSArray,
            let path = pasteboard.firstObject as? String else {
                return false
                
        }
        
        delegate?.didReceive(URL(fileURLWithPath: path), in: self)
        
        return true
    }
    
    // MARK: - Instance Methods
    
    private func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard().propertyList(forType: pasteboardType) as? NSArray,
            let path = board.firstObject as? String else {
                return false
                
        }
        
        let suffix = URL(fileURLWithPath: path).pathExtension
        return suffix.lowercased() == fileExtension
    }
    
}
