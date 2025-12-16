const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_dep = b.dependency("arcade_lib", .{ .target = target });
    const lib_mod = lib_dep.module("arcade_lib");

    const engine_dep = b.dependency("engine", .{ .target = target });
    const engine_mod = engine_dep.module("engine");

    const mod = b.addModule("zalaga", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "arcade_lib", .module = lib_mod },
            .{ .name = "engine", .module = engine_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "zalaga",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zalaga", .module = mod },
                .{ .name = "arcade_lib", .module = lib_mod },
                .{ .name = "engine", .module = engine_mod },
            },
        }),
    });

    if (target.result.os.tag == .windows) {
        exe.win32_manifest = b.path("windows.manifest");
        if (optimize == .Debug) {
            exe.subsystem = .Console; // Keep terminal in debug
        } else {
            exe.subsystem = .Windows; // Hide in release
        }
    }

    // Install assets directory alongside executable
    const install_assets = b.addInstallDirectory(.{
        .source_dir = b.path("assets"),
        .install_dir = .bin,
        .install_subdir = "assets",
    });

    exe.step.dependOn(&install_assets.step);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
