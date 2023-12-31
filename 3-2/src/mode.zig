/// https://skilldrick.github.io/easy6502/#addressing
/// https://www.nesdev.org/obelisk-6502-guide/reference.html
pub const AddressingMode = enum {
    //
    immediate,
    zero_page,
    zero_page_x,
    zero_page_y,
    absolute,
    absolute_x,
    Absolute_y,
    indirect_x,
    indirect_y,
    none_addressing,
};
