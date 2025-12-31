const std = @import("std");
const z = @import("../../mod.zig");

const EntityManager = z.EntityManager;

/// Formation tracking handler
pub const FormationTracker = struct {
    enemies_in_formation: u32 = 0,
    total_enemies_spawned: u32 = 0,

    const Self = @This();

    pub fn notifyEnemyInFormation(self: *Self) void {
        self.enemies_in_formation += 1;
    }

    pub fn notifyEnemyDied(self: *Self, was_in_formation: bool) void {
        if (was_in_formation and self.enemies_in_formation > 0) {
            self.enemies_in_formation -= 1;
        }
    }

    pub fn isFormationComplete(self: Self, entity_mgr: *EntityManager) bool {
        const alive = countAliveEnemies(entity_mgr);
        return self.enemies_in_formation >= alive;
    }

    pub fn areAllEnemiesDead(_: Self, entity_mgr: *EntityManager) bool {
        return countAliveEnemies(entity_mgr) == 0;
    }

    pub fn reset(self: *Self) void {
        self.enemies_in_formation = 0;
        self.total_enemies_spawned = 0;
    }
};

fn countAliveEnemies(entity_mgr: *EntityManager) u32 {
    var count: u32 = 0;
    for (entity_mgr.getAll()) |entity| {
        if (entity.active and (entity.type == .boss or entity.type == .goei or entity.type == .zako)) {
            count += 1;
        }
    }
    return count;
}
