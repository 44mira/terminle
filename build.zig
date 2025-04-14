const std = @import("std");
const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const attempt_mod = b.createModule(.{
        .root_source_file = b.path("src/attempt.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("attempt", attempt_mod);

    const attempt_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "attempt",
        .root_module = attempt_mod,
    });

    const exe = b.addExecutable(.{
        .name = "terminle",
        .root_module = exe_mod,
    });

    b.installArtifact(attempt_lib);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const modules = [_]*std.Build.Module{ attempt_mod, exe_mod };

    const test_step = b.step("test", "Run unit tests");
    for (modules) |module| {
        const unit_tests = b.addTest(.{
            .root_module = module,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);

        test_step.dependOn(&run_unit_tests.step);
    }
}
