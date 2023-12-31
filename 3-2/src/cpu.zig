const std = @import("std");
const ArrayList = std.ArrayList;

/// https://bugzmanov.github.io/nes_ebook/chapter_3_1.html
pub const Cpu = struct {
    register_a: u8,
    register_x: u8,
    register_y: u8,
    status: u8,
    program_counter: u16, //指令指针 ip
    memory: [0xFFFF]u8,

    pub fn init() Cpu {
        return .{
            .register_a = 0,
            .register_x = 0,
            .register_y = 0,
            .status = 0,
            .program_counter = 0,
            .memory = undefined,
        };
    }

    //执行指令 (字节码)
    //取指->解码->执行
    pub fn interpret(cpu: *Cpu) void {
        const opcodes = Opcode.create();
        outer: while (true) {
            const code = cpu.memRead(cpu.program_counter);
            cpu.program_counter += 1;
            const program_counter_state = cpu.program_counter;

            const opcode: Opcode = opcodes.get(code).?;

            switch (code) {
                0xA9, 0xA5, 0xB5, 0xAD, 0xB9, 0xA1, 0xB1 => {
                    cpu.lda(opcode.addressing_mode);
                },
                0x85, 0x95, 0x8d, 0x9d, 0x99, 0x81, 0x91 => {
                    cpu.sta(opcode.addressing_mode);
                },
                0xAA => cpu.tax(),
                0xE8 => cpu.inx(),
                0x00 => break :outer,
                else => {},
            }

            if (program_counter_state == cpu.program_counter) {
                cpu.program_counter += opcode.bytes - 1;
            }
        }
    }

    fn tax(cpu: *Cpu) void {
        cpu.register_x = cpu.register_a;
        cpu.updateZeroAndNegativeFlags(cpu.register_x);
    }

    fn lda(cpu: *Cpu, mode: AddressingMode) void {
        const addr = cpu.getOperandAddress(mode);
        const value = cpu.memRead(addr);
        cpu.register_a = value;
        cpu.updateZeroAndNegativeFlags(cpu.register_a);
    }

    fn inx(cpu: *Cpu) void {
        cpu.register_x = cpu.register_x + 1;
        cpu.updateZeroAndNegativeFlags(cpu.register_x);
    }

    fn updateZeroAndNegativeFlags(cpu: *Cpu, result: u8) void {
        if (result == 0) {
            cpu.status = cpu.status | 0b0000_0010;
        } else {
            cpu.status = cpu.status & 0b1111_1101;
        }

        if (result & 0b1000_0000 != 0) {
            cpu.status = cpu.status | 0b1000_0000;
        } else {
            cpu.status = cpu.status & 0b0111_1111;
        }
    }

    fn memRead(cpu: *Cpu, addr: u16) u8 {
        return cpu.memory[addr];
    }

    fn memWrite(cpu: *Cpu, addr: u16, data: u8) void {
        cpu.memory[addr] = data;
    }

    pub fn load(cpu: *Cpu, program: ArrayList(u8)) void {
        @memcpy(cpu.memory[0x8000..(program.items.len + 0x8000)], program.items[0..]);
        cpu.memWriteU16(0xFFFC, 0x8000);
    }

    pub fn loadAndRun(cpu: *Cpu, program: ArrayList(u8)) void {
        cpu.load(program);
        cpu.reset();
        cpu.interpret();
    }

    fn memReadU16(cpu: *Cpu, pos: u16) u16 {
        const low: u16 = cpu.memRead(pos);
        const high: u16 = cpu.memRead(pos + 1);
        return (high << 8) | (low);
    }

    //little-endian
    fn memWriteU16(cpu: *Cpu, pos: u16, data: u16) void {
        const high: u8 = @intCast(data >> 8);
        const low: u8 = @intCast(data & 0xff);
        cpu.memWrite(pos, low);
        cpu.memWrite(pos + 1, high);
    }

    pub fn reset(cpu: *Cpu) void {
        cpu.register_a = 0;
        cpu.register_x = 0;
        cpu.register_y = 0;
        cpu.status = 0;
        cpu.program_counter = cpu.memReadU16(0xFFFC);
    }

    fn getOperandAddress(cpu: *Cpu, mode: AddressingMode) u16 {
        return switch (mode) {
            .immediate => cpu.program_counter,
            .zero_page => @intCast(cpu.memRead(cpu.program_counter)),
            .absolute => cpu.memReadU16(cpu.program_counter),
            .zero_page_x => blk: {
                const pos = cpu.memRead(cpu.program_counter);
                const addr = cpu.register_x + pos;
                break :blk @intCast(addr);
            },
            .zero_page_y => blk: {
                const pos = cpu.memRead(cpu.program_counter);
                const addr = cpu.register_y + pos;
                break :blk @intCast(addr);
            },
            .absolute_x => blk: {
                const base = cpu.memReadU16(cpu.program_counter);
                const addr = @as(u16, @intCast(cpu.register_x)) + base;
                break :blk @intCast(addr);
            },
            .absolute_y => blk: {
                const base = cpu.memReadU16(cpu.program_counter);
                const addr = @as(u16, @intCast(cpu.register_y)) + base;
                break :blk @intCast(addr);
            },
            .indirect_x => blk: {
                const base = cpu.memRead(cpu.program_counter);
                const ptr = cpu.register_x + base;
                const low: u16 = @intCast(cpu.memRead(@intCast(ptr)));
                const high: u16 = @intCast(cpu.memRead(@intCast(ptr + 1)));
                break :blk @intCast((high << 8) | low);
            },
            .indirect_y => blk: {
                const base = cpu.memRead(cpu.program_counter);
                const ptr = cpu.register_x + base;
                const low: u16 = @intCast(cpu.memRead(@intCast(ptr)));
                const high: u16 = @intCast(cpu.memRead(@intCast(ptr + 1)));
                const deref_base = (high << 8) | low;
                break :blk @intCast(deref_base + cpu.register_y);
            },
            else => |m| @panic("mode" ++ @typeName(@TypeOf(m)) ++ "is not supported!"),
        };
    }

    fn sta(cpu: *Cpu, mode: AddressingMode) void {
        const addr = cpu.getOperandAddress(mode);
        cpu.memWrite(addr, cpu.register_a);
    }
};

const AddressingMode = @import("mode.zig").AddressingMode;
const Opcode = @import("opcode.zig").Opcode;

test Cpu {
    try test_0xa9_lda_immediate_loda_data();
    try test_0xa9_lda_zero_flag();
    try test_0xaa_tax_move_a_to_x();
    try test_5_opscode_working();
    try test_inx_overflow();
    try testLdaFromMemory();
}

//test fn
fn test_0xa9_lda_immediate_loda_data() !void {
    var cpu: Cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa9, 0x05, 0x00 });
    defer program.deinit();
    cpu.loadAndRun(program);

    try std.testing.expectEqual(@as(u8, cpu.register_a), 0x05);
    try std.testing.expect(cpu.status & 0b0000_0010 == 0);
    try std.testing.expect(cpu.status & 0b1000_0000 == 0);
}

fn test_0xa9_lda_zero_flag() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa9, 0x00, 0x00 });
    defer program.deinit();

    cpu.loadAndRun(program);

    try std.testing.expect(cpu.status & 0b0000_0010 == 0b10);
}

fn test_0xaa_tax_move_a_to_x() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xaa, 0x00 });
    defer program.deinit();
    cpu.loadAndRun(program);
    cpu.register_x = 10;

    try std.testing.expectEqual(@as(u8, cpu.register_x), 10);
}

fn test_5_opscode_working() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa9, 0xc0, 0xaa, 0xe8, 0x00 });
    defer program.deinit();
    cpu.loadAndRun(program);

    try std.testing.expectEqual(@as(u8, cpu.register_x), 0xc1);
}

fn test_inx_overflow() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xe8, 0xe8, 0x00 });
    defer program.deinit();
    cpu.loadAndRun(program);
    try std.testing.expectEqual(@as(u8, cpu.register_x), 2);
}

fn testLdaFromMemory() !void {
    var cpu = Cpu.init();
    cpu.memWrite(0x10, 0x55);
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa5, 0x10, 0x00 });
    defer program.deinit();
    cpu.loadAndRun(program);

    try std.testing.expectEqual(cpu.register_a, 0x55);
}
