const std = @import("std");

pub const Opcode = struct {
    op: u8,
    addressing_mode: AddressingMode,
    bytes: u8,
    cycles: u8,
    operate: []const u8,

    pub const cpu_ops_codes = [18]Opcode{
        Opcode.init(0x00, "BRK", 1, 7, .none_addressing),
        Opcode.init(0xaa, "TAX", 1, 2, .none_addressing),
        Opcode.init(0xe8, "INX", 1, 2, .none_addressing),

        Opcode.init(0xa9, "LDA", 2, 2, .immediate),
        Opcode.init(0xa5, "LDA", 2, 3, .zero_page),
        Opcode.init(0xb5, "LDA", 2, 4, .zero_page_x),
        Opcode.init(0xad, "LDA", 3, 4, .absolute),
        Opcode.init(0xbd, "LDA", 3, 4, .absolute_x),
        Opcode.init(0xb9, "LDA", 3, 4, .absolute_y),
        Opcode.init(0xa1, "LDA", 2, 6, .indirect_x),
        Opcode.init(0xb1, "LDA", 2, 5, .indirect_y),

        Opcode.init(0x85, "STA", 2, 3, .zero_page),
        Opcode.init(0x95, "STA", 2, 4, .zero_page_x),
        Opcode.init(0x8d, "STA", 3, 4, .absolute),
        Opcode.init(0x9d, "STA", 3, 5, .absolute_x),
        Opcode.init(0x99, "STA", 3, 5, .absolute_y),
        Opcode.init(0x81, "STA", 2, 6, .indirect_x),
        Opcode.init(0x91, "STA", 2, 6, .indirect_y),
    };

    pub var code_maps: std.AutoHashMap(u8, Opcode) = std.AutoHashMap(u8, Opcode).init(std.heap.page_allocator);

    pub fn init(
        op: u8,
        operate: []const u8,
        bytes: u8,
        cycles: u8,
        addressing_mode: AddressingMode,
    ) Opcode {
        return .{
            //
            .op = op,
            .addressing_mode = addressing_mode,
            .bytes = bytes,
            .cycles = cycles,
            .operate = operate,
        };
    }

    pub fn create() std.AutoHashMap(u8, Opcode) {

        //init code_maps
        for (cpu_ops_codes) |cpuop| {
            code_maps.put(cpuop.op, cpuop) catch unreachable;
        }
        return code_maps;
    }
};

const AddressingMode = @import("mode.zig").AddressingMode;
