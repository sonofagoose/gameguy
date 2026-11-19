//! A minimal PNG writer (8-bit RGB, uncompressed), for frame dumps from headless runs.
const std = @import("std");
const c = @import("c");

fn crc32(start: u32, data: []const u8) u32 {
    var crc = start;
    for (data) |byte| {
        crc ^= byte;
        for (0..8) |_| {
            crc = if (crc & 1 != 0) (crc >> 1) ^ 0xEDB88320 else crc >> 1;
        }
    }
    return crc;
}

fn put32(out: []u8, value: u32) void {
    out[0] = @truncate(value >> 24);
    out[1] = @truncate(value >> 16);
    out[2] = @truncate(value >> 8);
    out[3] = @truncate(value);
}

fn writeChunk(file: *c.FILE, kind: *const [4]u8, data: []const u8) void {
    var head: [8]u8 = undefined;
    put32(head[0..4], @intCast(data.len));
    @memcpy(head[4..8], kind);
    _ = c.fwrite(&head, 1, 8, file);
    if (data.len > 0) _ = c.fwrite(data.ptr, 1, data.len, file);
    var tail: [4]u8 = undefined;
    put32(&tail, ~crc32(crc32(0xFFFFFFFF, kind), data));
    _ = c.fwrite(&tail, 1, 4, file);
}

/// Write `rgba` (width * height * 4 bytes, bottom row first, as glReadPixels returns it) to
/// `path` as an RGB PNG. Returns false if the file or the memory could not be had.
pub fn writeFromGl(path: [*:0]const u8, width: usize, height: usize, rgba: []const u8) bool {
    const row_len = 1 + width * 3;
    const raw_len = row_len * height;
    const block_max = 65535;
    const blocks = (raw_len + block_max - 1) / block_max;
    const zlib_len = 2 + raw_len + blocks * 5 + 4;
    const memory: [*]u8 = @ptrCast(c.malloc(raw_len + zlib_len) orelse return false);
    defer c.free(memory);
    const raw = memory[0..raw_len];
    const zlib = memory[raw_len .. raw_len + zlib_len];

    for (0..height) |y| {
        const src = rgba[(height - 1 - y) * width * 4 ..];
        const dst = raw[y * row_len ..];
        dst[0] = 0; // filter: none
        for (0..width) |x| {
            dst[1 + x * 3 + 0] = src[x * 4 + 0];
            dst[1 + x * 3 + 1] = src[x * 4 + 1];
            dst[1 + x * 3 + 2] = src[x * 4 + 2];
        }
    }

    // zlib stream of stored (uncompressed) deflate blocks
    zlib[0] = 0x78;
    zlib[1] = 0x01;
    var at: usize = 2;
    var done: usize = 0;
    var a: u32 = 1;
    var b: u32 = 0;
    while (done < raw_len) {
        const n: usize = @min(block_max, raw_len - done);
        zlib[at] = if (done + n == raw_len) 1 else 0;
        zlib[at + 1] = @truncate(n);
        zlib[at + 2] = @truncate(n >> 8);
        zlib[at + 3] = @truncate(~n);
        zlib[at + 4] = @truncate(~n >> 8);
        @memcpy(zlib[at + 5 .. at + 5 + n], raw[done .. done + n]);
        for (raw[done .. done + n]) |byte| {
            a = (a + byte) % 65521;
            b = (b + a) % 65521;
        }
        at += 5 + n;
        done += n;
    }
    put32(zlib[at .. at + 4], (b << 16) | a);

    const file = c.fopen(path, "wb") orelse return false;
    defer _ = c.fclose(file);
    _ = c.fwrite("\x89PNG\r\n\x1a\n", 1, 8, file);
    var header: [13]u8 = undefined;
    put32(header[0..4], @intCast(width));
    put32(header[4..8], @intCast(height));
    header[8] = 8; // bits per channel
    header[9] = 2; // colour type: RGB
    header[10] = 0;
    header[11] = 0;
    header[12] = 0;
    writeChunk(file, "IHDR", &header);
    writeChunk(file, "IDAT", zlib);
    writeChunk(file, "IEND", &.{});
    return true;
}
