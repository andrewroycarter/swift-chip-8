//
//  ViewController.swift
//  swift-chip8
//
//  Created by Andrew Carter on 7/28/18.
//  Copyright © 2018 Andrew Carter. All rights reserved.
//

import Cocoa

final class ViewController: NSViewController, ROMDropViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet private var dropView: ROMDropView!
    private var machine: VirtualMachine?
    private let renderLayer = VMScreenRenderLayer()

    override var acceptsFirstResponder: Bool {
        return true
    }

    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        embedRenderLayer()
        addEventListeners()
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        guard let character = event.charactersIgnoringModifiers?.first.map(String.init),
        let key = Key(string: character) else {
            return
        }

        machine?.press(key: key)
    }

    override func keyUp(with event: NSEvent) {
        super.keyUp(with: event)

        guard let character = event.charactersIgnoringModifiers?.first.map(String.init),
            let key = Key(string: character) else {
                return
        }

        machine?.unpress(key: key)
    }
    
    // MARK: - Instance Methods

    private func addEventListeners() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event -> NSEvent? in
            self.keyDown(with: event)
            return event
        }

        NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { event -> NSEvent? in
            self.keyUp(with: event)
            return event
        }
    }

    private func setupVirtualMachine(rom: URL) {
        do {
            let data = try Data(contentsOf: rom)
            
            let machine = VirtualMachine(rom: data)
            machine.screenRenderer = renderLayer
            self.machine = machine
        } catch {
            print("Failed to load rom: \(error.localizedDescription)")
        }
    }
    
    private func startEmulation() {
        machine?.start()
    }
    
    private func embedRenderLayer() {
        renderLayer.shouldDrawPixelOutline = false
        view.layer = renderLayer
        view.wantsLayer = true
    }
    
    // MARK: - ROMDropViewDelegate Methods
    
    func didReceive(_ url: URL, in view: ROMDropView) {
        self.machine?.stop()
        self.machine = nil
        setupVirtualMachine(rom: url)
        startEmulation()
    }
    
}

