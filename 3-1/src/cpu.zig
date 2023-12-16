const std = @import("std");
const ArrayList = std.ArrayList;

/// https://bugzmanov.github.io/nes_ebook/chapter_3_1.html
pub const Cpu = struct {
    register_a: u8,
    register_x: u8,
    status: u8,
    program_counter: u16, //指令指针 ip

    pub fn init() Cpu {
        return .{
            .register_a = 0,
            .register_x = 0,
            .status = 0,
            .program_counter = 0,
        };
    }

    //执行指令 (字节码)
    //取指->解码->执行
    pub fn interpret(cpu: *Cpu, program: ArrayList(u8)) void {
        cpu.program_counter = 0;
        outer: while (true) {
            const opscode = program.items[@as(usize, cpu.program_counter)];
            cpu.program_counter += 1;

            switch (opscode) {
                0xA9 => {
                    const param = program.items[@as(usize, cpu.program_counter)];
                    cpu.program_counter += 1;
                    cpu.lda(param);
                },
                0xAA => {
                    cpu.tax();
                },
                0x00 => break :outer,
                else => {},
            }
        }
    }

    fn tax(cpu: *Cpu) void {
        cpu.register_x = cpu.register_a;
        cpu.updateZeroAndNegativeFlags(cpu.register_x);
    }

    fn lda(cpu: *Cpu, value: u8) void {
        cpu.register_a = value;
        cpu.updateZeroAndNegativeFlags(cpu.register_a);
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
};

test Cpu {
    try test_0xa9_lda_immediate_loda_data();
    try test_0xa9_lda_zero_flag();
    try test_0xaa_tax_move_a_to_x();
    try test_5_opscode_working();
    try test_inx_overflow();
}

//test fn
fn test_0xa9_lda_immediate_loda_data() !void {
    var cpu: Cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa9, 0x05, 0x00 });
    defer program.deinit();
    cpu.interpret(program);

    try std.testing.expectEqual(@as(u8, cpu.register_a), 0x05);
    try std.testing.expect(cpu.status & 0b0000_0010 == 0);
    try std.testing.expect(cpu.status & 0b1000_0000 == 0);
}

fn test_0xa9_lda_zero_flag() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa9, 0x00, 0x00 });
    defer program.deinit();

    cpu.interpret(program);

    try std.testing.expect(cpu.status & 0b0000_0010 == 0b10);
}

fn test_0xaa_tax_move_a_to_x() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xaa, 0x00 });
    defer program.deinit();
    cpu.register_a = 10;
    cpu.interpret(program);

    try std.testing.expectEqual(@as(u8, cpu.register_x), 10);
}

fn test_5_opscode_working() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xa9, 0xc0, 0xaa, 0xe8, 0x00 });
    defer program.deinit();
    cpu.interpret(program);

    try std.testing.expectEqual(@as(u8, cpu.register_x), 0xc0);
}

fn test_inx_overflow() !void {
    var cpu = Cpu.init();
    var program = ArrayList(u8).init(std.testing.allocator);
    try program.appendSlice(&.{ 0xe8, 0xe8, 0x00 });
    defer program.deinit();
    cpu.register_x = 0xff;
    cpu.interpret(program);

    try std.testing.expectEqual(@as(u8, cpu.register_x), 0xff);
}
