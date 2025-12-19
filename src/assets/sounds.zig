const std = @import("std");
const engine = @import("engine");

pub const SoundId = enum {
    shoot,
    die_player,
    die_zako,
    die_goei,
    die_boss,
    hit_boss,
    swoop,
    swoop_idle,
    tractor_pickup,
    tractor_success,
    challenge_succeeded,
    challenge_failed,
    level_marker,
    extra_life,
    high_score,
    insert_coin,
    intro,
};

const Context = engine.Context(SoundId);

pub fn loadSounds(ctx: *Context) !void {
    try ctx.audio.loadSound(.shoot, "sounds/shoot.mp3");
    try ctx.audio.loadSound(.die_player, "sounds/die-player.mp3");
    try ctx.audio.loadSound(.die_zako, "sounds/die_zako.mp3");
    try ctx.audio.loadSound(.die_goei, "sounds/die-goei.mp3");
    try ctx.audio.loadSound(.die_boss, "sounds/die-boss.mp3");
    try ctx.audio.loadSound(.hit_boss, "sounds/hit-boss.mp3");
    try ctx.audio.loadSound(.swoop, "sounds/swoop.mp3");
    try ctx.audio.loadSound(.swoop_idle, "sounds/swoop-idle.mp3");
    try ctx.audio.loadSound(.tractor_pickup, "sounds/tractor-pickup.mp3");
    try ctx.audio.loadSound(.tractor_success, "sounds/tractor-success.mp3");
    try ctx.audio.loadSound(.challenge_succeeded, "sounds/challenge-succeeded.mp3");
    try ctx.audio.loadSound(.challenge_failed, "sounds/challenge-failed.mp3");
    try ctx.audio.loadSound(.level_marker, "sounds/level-marker.mp3");
    try ctx.audio.loadSound(.extra_life, "sounds/extra-life.mp3");
    try ctx.audio.loadSound(.high_score, "sounds/high-score.mp3");
    try ctx.audio.loadSound(.insert_coin, "sounds/insert_coin.mp3");
    try ctx.audio.loadSound(.intro, "sounds/intro.mp3");
}
