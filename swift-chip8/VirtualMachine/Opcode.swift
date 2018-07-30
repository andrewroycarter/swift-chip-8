//
//  Opcode.swift
//  swift-chip8
//
//  Created by Andrew Carter on 7/28/18.
//  Copyright © 2018 Andrew Carter. All rights reserved.
//

import Foundation

enum OpcodeError: Error {
    case counterOutOfBounds
    case unknownCode
}

enum Opcode {
    
    case clearScreen
    case `return`
    case jump(Address)
    case callSubroutine(Address)
    case skipIfEqualToConstant(Register, Constant)
    case skipIfNotEqualToConstant(Register, Constant)
    case skipIfEqual(Register, Register)
    case setToConstant(Register, Constant)
    case addConstant(Register, Constant)
    case set(Register, Register)
    case or(Register, Register)
    case and(Register, Register)
    case xor(Register, Register)
    case add(Register, Register)
    case subtract(Register, Register)
    case setShiftingRight(Register, Register)
    case setRegister(Register, subractingFromRegister: Register)
    case setShiftingLeft(Register, Register)
    case skipIfNotEqual(Register, Register)
    case setIndex(Address)
    case jumpRelative(Address)
    case setByRandomAndConstant(Register, Constant)
    case drawSprite(x: Register, y: Register, height: Constant)
    case skipNextIfKeyPressed(Register)
    case skipNextIfKeyNotPressed(Register)
    case setToDelayTimer(Register)
    case awaitKeyPress(Register)
    case setDelayTimer(Register)
    case setSoundTimer(Register)
    case addToIndex(Register)
    case setIndexToCharactor(Register)
    case storeBCDToIndex(Register)
    case storeToIndexUpToIncluding(Register)
    case fillFromIndexUpToIncluding(Register)
    
    init(_ rawOpcode: UInt16) throws {
        let nib1 = UInt8((rawOpcode & 0xF000) >> 12)
        let nib2 = UInt8((rawOpcode & 0x0F00) >> 8)
        let nib3 = UInt8((rawOpcode & 0x00F0) >> 4)
        let nib4 = UInt8(rawOpcode & 0x000F)
        
        /*
         NNN: address
         NN: 8-bit constant
         N: 4-bit constant
         X and Y: 4-bit register identifier
         PC : Program Counter
         I : 16bit register (For memory address) (Similar to void pointer)
         */
        
        switch (nib1, nib2, nib3, nib4) {
        // 00E0    Display    disp_clear()    Clears the screen.
        case (0x0, 0x0, 0xE, 0x0):
            self = .clearScreen
            
        // 00EE    Flow    return;    Returns from a subroutine.
        case (0x0, 0x0, 0xE, 0xE):
            self = .return
            
        // 1NNN    Flow    goto NNN;    Jumps to address NNN.
        case (0x1, _, _ ,_):
            self = .jump(rawOpcode & 0x0FFF)
            
        //  2NNN    Flow    *(0xNNN)()    Calls subroutine at NNN.
        case (0x2, _, _, _):
            self = .callSubroutine(rawOpcode & 0x0FFF)
            
        //  3XNN    Cond    if(Vx==NN)    Skips the next instruction if VX equals NN. (Usually the next instruction is a jump to skip a code block)
        case (0x3, let x, _, _):
            self = .skipIfEqualToConstant(x, UInt8(rawOpcode & 0x00FF))
            
        //  4XNN    Cond    if(Vx!=NN)    Skips the next instruction if VX doesn't equal NN. (Usually the next instruction is a jump to skip a code block)
        case (0x4, let x, _, _):
            self = .skipIfNotEqualToConstant(x, UInt8(rawOpcode & 0x00FF))
            
        //  5XY0    Cond    if(Vx==Vy)    Skips the next instruction if VX equals VY. (Usually the next instruction is a jump to skip a code block)
        case (0x5, let x, let y, 0x0):
            self = .skipIfEqual(x, y)
            
        //  6XNN    Const    Vx = NN    Sets VX to NN.
        case (0x6, let x, _, _):
            self = .setToConstant(x, UInt8(rawOpcode & 0x00FF))
            
        //  7XNN    Const    Vx += NN    Adds NN to VX. (Carry flag is not changed)
        case (0x7, let x, _, _):
            self = .addConstant(x, UInt8(rawOpcode & 0x00FF))
            
        //  8XY0    Assign    Vx=Vy    Sets VX to the value of VY.
        case (0x8, let x, let y, 0x0):
            self = .set(x, y)
            
        //  8XY1    BitOp    Vx=Vx|Vy    Sets VX to VX or VY. (Bitwise OR operation)
        case (0x8, let x, let y, 0x1):
            self = .or(x, y)
            
        //  8XY2    BitOp    Vx=Vx&Vy    Sets VX to VX and VY. (Bitwise AND operation)
        case (0x8, let x, let y, 0x2):
            self = .and(x, y)
            
        //  8XY3    BitOp    Vx=Vx^Vy    Sets VX to VX xor VY.
        case (0x8, let x, let y, 0x3):
            self = .xor(x, y)
            
        //  8XY4    Math    Vx += Vy    Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
        case (0x8, let x, let y, 0x4):
            self = .add(x, y)
            
        //  8XY5    Math    Vx -= Vy    VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
        case (0x8, let x, let y, 0x5):
            self = .subtract(x, y)
            
        //  8XY6    BitOp    Vx=Vy>>1    Shifts VY right by one and stores the result to VX (VY remains unchanged). VF is set to the value of the least significant bit of VY before the shift.[2]
        case (0x8, let x, let y, 0x6):
            self = .setShiftingRight(x, y)
            
        //  8XY7    Math    Vx=Vy-Vx    Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
        case (0x8, let x, let y, 0x7):
            self = .setRegister(x, subractingFromRegister: y)
            
        //  8XYE    BitOp    Vx=Vy=Vy<<1    Shifts VY left by one and copies the result to VX. VF is set to the value of the most significant bit of VY before the shift.[2]
        case (0x8, let x, let y, 0xE):
            self = .setShiftingLeft(x, y)
            
        //  9XY0    Cond    if(Vx!=Vy)    Skips the next instruction if VX doesn't equal VY. (Usually the next instruction is a jump to skip a code block)
        case (0x9, let x, let y, 0x0):
            self = .skipIfNotEqual(x, y)
            
        //  ANNN    MEM    I = NNN    Sets I to the address NNN.
        case (0xA, _, _, _):
            self = .setIndex(rawOpcode & 0x0FFF)
            
        //  BNNN    Flow    PC=V0+NNN    Jumps to the address NNN plus V0.
        case (0xB, _, _, _):
            self = .jumpRelative(rawOpcode & 0x0FFF)
            
        //  CXNN    Rand    Vx=rand()&NN    Sets VX to the result of a bitwise and operation on a random number (Typically: 0 to 255) and NN.
        case (0xC, let x, _, _):
            self = .setByRandomAndConstant(x, UInt8(rawOpcode & 0x00FF))
            
            /*
             DXYN    Disp    draw(Vx,Vy,N)    Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels.
             Each row of 8 pixels is read as bit-coded starting from memory location I; I value doesn’t change after the execution of this instruction.
             As described above, VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn, and to 0 if that doesn’t happen
             */
        case (0xD, let x, let y, let n):
            self = .drawSprite(x: x, y: y, height: n)
            
        //  EX9E    KeyOp    if(key()==Vx)    Skips the next instruction if the key stored in VX is pressed. (Usually the next instruction is a jump to skip a code block)
        case (0xE, let x, 0x9, 0xE):
            self = .skipNextIfKeyPressed(x)
            
        //  EXA1    KeyOp    if(key()!=Vx)    Skips the next instruction if the key stored in VX isn't pressed. (Usually the next instruction is a jump to skip a code block)
        case (0xE, let x, 0xA, 0x1):
            self = .skipNextIfKeyNotPressed(x)
            
        //  FX07    Timer    Vx = get_delay()    Sets VX to the value of the delay timer.
        case (0xF, let x, 0x0, 0x7):
            self = .setToDelayTimer(x)
            
        //  FX0A    KeyOp    Vx = get_key()    A key press is awaited, and then stored in VX. (Blocking Operation. All instruction halted until next key event)
        case (0xF, let x, 0x0, 0xA):
            self = .awaitKeyPress(x)
            
        //  FX15    Timer    delay_timer(Vx)    Sets the delay timer to VX.
        case (0xF, let x, 0x1, 0x5):
            self = .setDelayTimer(x)
            
        //  FX18    Sound    sound_timer(Vx)    Sets the sound timer to VX.
        case (0xF, let x, 0x1, 0x8):
            self = .setSoundTimer(x)
            
        //  FX1E    MEM    I +=Vx    Adds VX to I.[3]
        case (0xF, let x, 0x1, 0xE):
            self = .addToIndex(x)
            
        //  FX29    MEM    I=sprite_addr[Vx]    Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font.
        case (0xF, let x, 0x2, 0x9):
            self = .setIndexToCharactor(x)
            
            //  FX33    BCD    set_BCD(Vx);
            //  *(I+0)=BCD(3);
            //
            //  *(I+1)=BCD(2);
            //
            //  *(I+2)=BCD(1);
            //
        //  Stores the binary-coded decimal representation of VX, with the most significant of three digits at the address in I, the middle digit at I plus 1, and the least significant digit at I plus 2. (In other words, take the decimal representation of VX, place the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.)
        case (0xF, let x, 0x3, 0x3):
            self = .storeBCDToIndex(x)
            
        //  FX55    MEM    reg_dump(Vx,&I)    Stores V0 to VX (including VX) in memory starting at address I. The offset from I is increased by 1 for each value written, but I itself is left unmodified.
        case (0xF, let x, 0x5, 0x5):
            self = .storeToIndexUpToIncluding(x)
            
        //  FX65    MEM    reg_load(Vx,&I)    Fills V0 to VX (including VX) with values from memory starting at address I. The offset from I is increased by 1 for each value written, but I itself is left unmodified.
        case (0xF, let x, 0x6, 0x5):
            self = .fillFromIndexUpToIncluding(x)
            
        default:
            throw OpcodeError.unknownCode
        }
    }
        
}


