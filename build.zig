const std = @import("std");
const Build = std.Build;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const attempt_mod = b.createModule(.{
        .root_source_file = b.path("src/attempt.zig"),
        .target = target,
        .optimize = optimize,
    });

    const colorize_mod = b.createModule(.{
        .root_source_file = b.path("src/colorize.zig"),
        .target = target,
        .optimize = optimize,
    });

    const display_mod = b.createModule(.{
        .root_source_file = b.path("src/display.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const modules = [_]*Build.Module{
        attempt_mod,
        colorize_mod,
        display_mod,
        exe_mod,
    };

    exe_mod.addImport("attempt", attempt_mod);
    exe_mod.addImport("colorize", colorize_mod);
    exe_mod.addImport("display", display_mod);

    colorize_mod.addImport("attempt", attempt_mod);

    display_mod.addImport("attempt", attempt_mod);
    display_mod.addImport("colorize", colorize_mod);

    for (modules) |module| {
        if (module == exe_mod) continue;

        const lib_name = std.fs.path.basename(module.root_source_file.?.src_path.sub_path);

        const library = b.addLibrary(.{
            .linkage = .static,
            .name = lib_name,
            .root_module = attempt_mod,
        });

        b.installArtifact(library);
    }

    const exe = b.addExecutable(.{
        .name = "terminle",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    for (modules) |module| {
        const unit_tests = b.addTest(.{
            .root_module = module,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);

        test_step.dependOn(&run_unit_tests.step);
    }
}
