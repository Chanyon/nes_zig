pub const Opcode = struct {
    op: u8,
    addressing_mode: AddressingMode,
    bytes: u8,
    cycles: u8,
    operate: []const u8,

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
};

pub const CPU_OPS_CODES: @Vector(10, Opcode) = .{
    Opcode.init(0x00, "BRK", 1, 7, .none_addressing),
    Opcode.init(0xaa, "TAX", 1, 2, .none_addressing),

    Opcode.init(0xa9, "LDA", 2, 2, .immediate),
    Opcode.init(0xa5, "LDA", 2, 3, .zero_page),
    Opcode.init(0xb5, "LDA", 2, 4, .zero_page_x),
    Opcode.init(0xad, "LDA", 3, 4, .absolute),
    Opcode.init(0xbd, "LDA", 3, 4, .absolute_x),
    Opcode.init(0xb9, "LDA", 3, 4, .Absolute_y),
    Opcode.init(0xa1, "LDA", 2, 6, .indirect_x),
    Opcode.init(0xb1, "LDA", 2, 5, .indirect_y),
};

const AddressingMode = @import("mode.zig").AddressingMode;
