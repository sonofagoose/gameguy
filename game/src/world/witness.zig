//! Witnesses: the world itself notes when a promise's moment happens (spec/promises.md).
//!
//! A promise whose full size has a `take` line is in `promise_list.zig`, which the promise tool
//! writes. The rules call `meet` when the moment's conditions hold and `hold` on each step the
//! player stays in it. Nothing here feeds back into the rules, and none of it is in the world's
//! fingerprint: adding a promise never changes a take.
const list = @import("promise_list.zig");

pub const Id = list.Id;
pub const names = list.names;
pub const count = names.len;

pub const Mark = struct {
    met: bool = false,
    /// The step it first happened on.
    first: u64 = 0,
    /// How many steps the player stayed in it.
    held: u32 = 0,
};

pub const Table = struct {
    marks: [count]Mark = @splat(.{}),

    pub fn meet(self: *Table, id: Id, step: u64) void {
        const mark = &self.marks[@intFromEnum(id)];
        if (mark.met) return;
        mark.met = true;
        mark.first = step;
    }

    pub fn hold(self: *Table, id: Id) void {
        self.marks[@intFromEnum(id)].held +|= 1;
    }

    pub fn get(self: *const Table, id: Id) Mark {
        return self.marks[@intFromEnum(id)];
    }

    /// The promise of that name, if the world witnesses it.
    pub fn find(name: []const u8) ?Id {
        for (names, 0..) |n, i| {
            if (n.len == name.len and @import("std").mem.eql(u8, n, name)) return @enumFromInt(i);
        }
        return null;
    }
};
