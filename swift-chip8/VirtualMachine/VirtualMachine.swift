//
//  VirtualMachine.swift
//  swift-chip8
//
//  Created by Andrew Carter on 7/28/18.
//  Copyright © 2018 Andrew Carter. All rights reserved.
//

import Foundation

protocol VirtualMachineScreenRenderer: class {
    func render(screen: [UInt8], for machine: VirtualMachine)
}

final class VirtualMachine {
    
    // MARK: - Properties
    
    let screenWidth: UInt16 = 64
    let screenHeight: UInt16 = 32
    
    weak var screenRenderer: VirtualMachineScreenRenderer?
    
    private var ram = Data(count: 4096)
    private var index: Address = 0x000000
    private var stack: Address = 0x000EA0
    private var programCounter: Address = 0x000200
    private var soundTimer: Constant = 0
    private var delayCounter: Constant = 0
    private var registers: [Register] = .init(repeating: 0, count: 16)
    private var screen: [UInt8] = .init(repeating: 0, count: 2048)
    private var queue = DispatchQueue(label: "com.VirtualMachine", qos: DispatchQoS.userInteractive)
    private var delayTimer: Timer?
    private var isRunning = false
    private var pressedKeys = Set<Key>()

    // MARK: - Init
    
    init(rom: Rom) {
        ram.replaceSubrange(512 ... 512 + rom.count, with: rom)
    }
    
    // MARK: - Instance Methods

    func press(key: Key) {
        pressedKeys.insert(key)
    }

    func unpress(key: Key) {
        pressedKeys.remove(key)
    }

    func start() {
        isRunning = true
        startTimers()

        queue.async { [weak self] in
            repeat {
                self?.runNextOpcode()
                usleep(1000)
            } while self?.isRunning ?? false
        }
    }

    func stop() {
        isRunning = false
        stopTimers()
    }

    private func startTimers() {
        delayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            self?.decrementDelayTimer()
            self?.decrementSoundTimer()
        }
    }

    private func stopTimers() {
        delayTimer?.invalidate()
        delayTimer = nil
    }

    private func decrementDelayTimer() {
        if delayCounter > 0 {
            delayCounter = delayCounter - 1
        }
    }

    private func decrementSoundTimer() {
        if soundTimer > 0 {
            soundTimer = soundTimer - 1
        }
    }
    
    private func runNextOpcode() {
        if let opcode = try? nextOpcode() {
            if run(opcode: opcode) {
                incrementProgramCounter()
            }
        } else {
            fatalError()
        }
    }
    
    private func incrementProgramCounter() {
        programCounter += 2
    }
    
    private func nextOpcode() throws -> Opcode {
        let firstByte = ram[Int(programCounter)]
        let secondByte = ram[Int(programCounter) + 1]
        let rawOpcode = UInt16(UInt16(firstByte) << 8) | UInt16(secondByte)
        
        return try Opcode(rawOpcode)
    }
    
    private func run(opcode: Opcode) -> Bool {
        var shouldIncrementProgramCounter = true
        
        switch opcode {
        case .awaitKeyPress(let register):
            if let key = Key(rawValue: registers[Int(register)]) {
                shouldIncrementProgramCounter = pressedKeys.contains(key)
            }

        case .clearScreen:
            screen = .init(repeating: 0, count: 2048)
            
        case .setIndex(let address):
            index = address
            
        case .setToConstant(let register, let constant):
            registers[Int(register)] = constant
            
        case .addConstant(let register, let constant):
            registers[Int(register)] = registers[Int(register)] &+ constant
            
        case .skipIfNotEqualToConstant(let register, let constant):
            if registers[Int(register)] != constant {
                incrementProgramCounter()
            }
            
        case .jump(let address):
            shouldIncrementProgramCounter = false
            programCounter = address
            
        case .addToIndex(let register):
            let value = UInt16(registers[Int(register)])
            registers[0xF] = ((value + index) > UInt16(0xFFF)) ? 1 : 0
            index += value
            
        case .drawSprite(let x, let y, let height):
            draw(spriteX: registers[Int(x)], spriteY: registers[Int(y)], height: height)
            screenRenderer?.render(screen: screen, for: self)
            
        case .skipIfEqualToConstant(let register, let constant):
            if registers[Int(register)] == constant {
                incrementProgramCounter()
            }
            
        case .setByRandomAndConstant(let register, let constant):
            registers[Int(register)] = UInt8(arc4random() % UInt32(UInt8.max)) & constant
            
        case .skipIfEqual(let lhsRegister, let rhsRegister):
            if registers[Int(lhsRegister)] == registers[Int(rhsRegister)] {
                incrementProgramCounter()
            }
            
        case .setDelayTimer(let register):
            delayCounter = registers[Int(register)]
            
        case .add(let lhsRegister, let rhsRegister):
            let lhsValue = registers[Int(lhsRegister)]
            let rhsValue = registers[Int(rhsRegister)]
            registers[0x0F] = Int(lhsValue) + Int(rhsValue) > Int(UInt8.max) ? 1 : 0
            registers[Int(lhsRegister)] = lhsValue &+ rhsValue
            
        case .set(let lhsRegister, let rhsRegister):
            registers[Int(lhsRegister)] = registers[Int(rhsRegister)]
            
        case .storeToIndexUpToIncluding(let lastRegister):
            for register in 0 ... lastRegister {
                ram[Int(index + UInt16(register))] = registers[Int(register)]
            }
            
        case .fillFromIndexUpToIncluding(let lastRegister):
            for register in 0 ... lastRegister {
                registers[Int(register)] = ram[Int(index + UInt16(register))]
            }
            
        case .subtract(let lhsRegister, let rhsRegister):
            let lhsValue = registers[Int(lhsRegister)]
            let rhsValue = registers[Int(rhsRegister)]
            registers[0x0F] = lhsValue < rhsValue ? 0 : 1
            registers[Int(lhsRegister)] = lhsValue &- rhsValue
            
        case .skipIfNotEqual(let lhsRegister, let rhsRegister):
            let lhsValue = registers[Int(lhsRegister)]
            let rhsValue = registers[Int(rhsRegister)]
            if lhsValue != rhsValue {
                incrementProgramCounter()
            }
            
        case .setToDelayTimer(let register):
            registers[Int(register)] = delayCounter
            
        case .and(let lhsRegister, let rhsRegister):
            let lhsValue = registers[Int(lhsRegister)]
            let rhsValue = registers[Int(rhsRegister)]
            registers[Int(lhsRegister)] = lhsValue & rhsValue

        case .skipNextIfKeyPressed(let register):
            if let key = Key(rawValue: registers[Int(register)]),
                pressedKeys.contains(key) {
                incrementProgramCounter()
            }

        case .skipNextIfKeyNotPressed(let register):
            if let key = Key(rawValue: registers[Int(register)]),
                !pressedKeys.contains(key) {
                incrementProgramCounter()
            }

        case .setSoundTimer(let register):
            soundTimer = registers[Int(register)]

        case .xor(let lhsRegister, let rhsRegister):
            let lhsValue = registers[Int(lhsRegister)]
            let rhsValue = registers[Int(rhsRegister)]
            registers[Int(lhsRegister)] = lhsValue ^ rhsValue

        case .or(let lhsRegister, let rhsRegister):
            let lhsValue = registers[Int(lhsRegister)]
            let rhsValue = registers[Int(rhsRegister)]
            registers[Int(lhsRegister)] = lhsValue | rhsValue

        default:
            print("\(opcode) not implemented")
        }
        
        return shouldIncrementProgramCounter
    }
    
    private func draw(spriteX: UInt8, spriteY: UInt8, height: Constant) {
        registers[0x0F] = 0
        
        for y in 0 ..< height {
            var row = ram[Int(index + UInt16(y))]
            
            for x in 0 ..< 8 {
                if row & 0x80 != 0 {
                    let screenY = (UInt16(spriteY) + UInt16(y)) % UInt16(screenHeight)
                    let screenX = (UInt16(spriteX) + UInt16(x)) % UInt16(screenWidth)
                    let screenIndex = (UInt16(screenY) * UInt16(screenWidth)) + UInt16(screenX)
                    
                    if screen[Int(screenIndex)] == 1 {
                        registers[0x0F] = 1
                    }
                    
                    screen[Int(screenIndex)] ^= 1
                }
                
                row <<= 1
            }
        }
    }
    
}
