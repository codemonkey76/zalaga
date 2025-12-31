pub const player = struct {
    pub const SPEED: f32 = 0.5;
    pub const SHOOT_COOLDOWN: f32 = 0.1;
    pub const SIDE_MARGIN: f32 = 0.04;
    pub const MAX_BULLETS: u32 = 2;
    pub const BULLET_SPEED: f32 = 0.8;
    pub const START_LIVES: u8 = 5;
};

pub const stage = struct {
    pub const PLAYER_READY_DURATION: f32 = 4.0;
    pub const STAGE_READY_DURATION: f32 = 2.0;
    pub const PLAYER_SPAWN_DURATION: f32 = 2.0;
};

pub const formation = struct {
    pub const BREATHE_SPEED: f32 = 0.2; // Cycles per second
    pub const BREATHE_AMOUNT: f32 = 0.20; // Max scale change (20%)
    pub const SWAY_SPEED: f32 = 0.09; // Cycles per second
    pub const SWAY_AMOUNT: f32 = 0.13; // Max horizontal movement (normalized coords)
    pub const TRANSITION_TIME: f32 = 0.5; // Time to blend between modes (seconds)
    pub const IDLE_ANIM_SPEED: f32 = 2.0;
};

pub const movement = struct {
    pub const DISTANCE_THRESHOLD: f32 = 0.01;
    pub const OFFSCREEN_MARGIN: f32 = 0.1;
};
