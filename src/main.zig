const std = @import("std");
const z = @import("zalaga");
const Game = z.Game;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game = try Game.init(allocator);
    defer game.deinit();

    try game.run();
}
