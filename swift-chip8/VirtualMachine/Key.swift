//
//  Key.swift
//  swift-chip8
//
//  Created by Andrew Carter on 7/31/18.
//  Copyright © 2018 Andrew Carter. All rights reserved.
//

import Foundation

enum Key: UInt8 {

    case zero
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case A
    case B
    case C
    case D
    case E
    case F

    init?(rawValue: UInt8) {
        switch rawValue {
        case 0x0:
            self = .zero

        case 0x1:
            self = .one

        case 0x2:
            self = .two

        case 0x3:
            self = .three

        case 0x4:
            self = .four

        case 0x5:
            self = .five

        case 0x6:
            self = .six

        case 0x7:
            self = .seven

        case 0x8:
            self = .eight

        case 0x9:
            self = .nine

        case 0xA:
            self = .A

        case 0xB:
            self = .B

        case 0xC:
            self = .C

        case 0xD:
            self = .D

        case 0xE:
            self = .E

        case 0xF:
            self = .F

        default:
            return nil
        }
    }
    init?(string: String) {
        switch string {
        case "1":
            self = .one

        case "2":
            self = .two

        case "3":
            self = .three

        case "4":
            self = .C

        case "q":
            self = .four

        case "w":
            self = .five

        case "e":
            self = .six

        case "r":
            self = .D

        case "a":
            self = .seven

        case "s":
            self = .eight

        case "d":
            self = .nine

        case "f":
            self = .E

        case "z":
            self = .A

        case "x":
            self = .zero

        case "c":
            self = .B

        case "v":
            self = .F

        default:
            return nil
        }
    }
    
}
