const std = @import("std");
const build_facilio = @import("facil.io/build.zig").build_facilio;

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const use_openssl = b.option(bool, "openssl", "Use system-installed openssl for TLS support in zap") orelse false;

    // create a module to be used internally.
    var zap_module = b.createModule(.{
        .source_file = .{ .path = "src/zap.zig" },
    });

    // register the module so it can be referenced using the package manager.
    try b.modules.put(b.dupe("zap"), zap_module);

    const facilio = try build_facilio("facil.io", b, target, optimize, use_openssl);

    const all_step = b.step("all", "build all examples");

    inline for ([_]struct {
        name: []const u8,
        src: []const u8,
    }{
        .{ .name = "hello", .src = "examples/hello/hello.zig" },
        .{ .name = "hello2", .src = "examples/hello2/hello2.zig" },
        .{ .name = "routes", .src = "examples/routes/routes.zig" },
        .{ .name = "serve", .src = "examples/serve/serve.zig" },
        .{ .name = "hello_json", .src = "examples/hello_json/hello_json.zig" },
        .{ .name = "endpoint", .src = "examples/endpoint/main.zig" },
        .{ .name = "wrk", .src = "wrk/zig/main.zig" },
        .{ .name = "wrk_zigstd", .src = "wrk/zigstd/main.zig" },
        .{ .name = "mustache", .src = "examples/mustache/mustache.zig" },
        .{ .name = "endpoint_auth", .src = "examples/endpoint_auth/endpoint_auth.zig" },
        .{ .name = "http_params", .src = "examples/http_params/http_params.zig" },
        .{ .name = "cookies", .src = "examples/cookies/cookies.zig" },
        .{ .name = "websockets", .src = "examples/websockets/websockets.zig" },
        .{ .name = "userpass_session", .src = "examples/userpass_session_auth/userpass_session_auth.zig" },
        .{ .name = "sendfile", .src = "examples/sendfile/sendfile.zig" },
        .{ .name = "middleware", .src = "examples/middleware/middleware.zig" },
        .{ .name = "middleware_with_endpoint", .src = "examples/middleware_with_endpoint/middleware_with_endpoint.zig" },
        .{ .name = "senderror", .src = "examples/senderror/senderror.zig" },
        .{ .name = "bindataformpost", .src = "examples/bindataformpost/bindataformpost.zig" },
    }) |excfg| {
        const ex_name = excfg.name;
        const ex_src = excfg.src;
        const ex_build_desc = try std.fmt.allocPrint(
            b.allocator,
            "build the {s} example",
            .{ex_name},
        );
        const ex_run_stepname = try std.fmt.allocPrint(
            b.allocator,
            "run-{s}",
            .{ex_name},
        );
        const ex_run_stepdesc = try std.fmt.allocPrint(
            b.allocator,
            "run the {s} example",
            .{ex_name},
        );
        const example_run_step = b.step(ex_run_stepname, ex_run_stepdesc);
        const example_step = b.step(ex_name, ex_build_desc);

        var example = b.addExecutable(.{
            .name = ex_name,
            .root_source_file = .{ .path = ex_src },
            .target = target,
            .optimize = optimize,
        });

        example.linkLibrary(facilio);
        example.addModule("zap", zap_module);

        // const example_run = example.run();
        const example_run = b.addRunArtifact(example);
        example_run_step.dependOn(&example_run.step);

        // install the artifact - depending on the "example"
        const example_build_step = b.addInstallArtifact(example, .{});
        example_step.dependOn(&example_build_step.step);
        all_step.dependOn(&example_build_step.step);
    }

    //
    // TOOLS & TESTING
    //
    // n.b.: tests run in parallel, so we need all tests that use the network
    //       to run sequentially, since zap doesn't like to be started multiple
    //       times on different threads
    //
    // TODO: for some reason, tests aren't run more than once unless
    //       dependencies have changed.
    //       So, for now, we just force the exe to be built, so in order that
    //       we can call it again when needed.

    // authentication tests
    //
    const auth_tests = b.addTest(.{
        .name = "auth_tests",
        .root_source_file = .{ .path = "src/tests/test_auth.zig" },
        .target = target,
        .optimize = optimize,
    });
    auth_tests.linkLibrary(facilio);
    auth_tests.addModule("zap", zap_module);

    const run_auth_tests = b.addRunArtifact(auth_tests);
    const install_auth_tests = b.addInstallArtifact(auth_tests, .{});

    // mustache tests
    const mustache_tests = b.addTest(.{
        .name = "mustache_tests",
        .root_source_file = .{ .path = "src/tests/test_mustache.zig" },
        .target = target,
        .optimize = optimize,
    });
    mustache_tests.linkLibrary(facilio);
    mustache_tests.addModule("zap", zap_module);

    const run_mustache_tests = b.addRunArtifact(mustache_tests);
    const install_mustache_tests = b.addInstallArtifact(mustache_tests, .{});

    // http paramters (qyery, body) tests
    const httpparams_tests = b.addTest(.{
        .name = "http_params_tests",
        .root_source_file = .{ .path = "src/tests/test_http_params.zig" },
        .target = target,
        .optimize = optimize,
    });

    httpparams_tests.linkLibrary(facilio);
    httpparams_tests.addModule("zap", zap_module);
    const run_httpparams_tests = b.addRunArtifact(httpparams_tests);
    // TODO: for some reason, tests aren't run more than once unless
    //       dependencies have changed.
    //       So, for now, we just force the exe to be built, so in order that
    //       we can call it again when needed.
    const install_httpparams_tests = b.addInstallArtifact(httpparams_tests, .{});

    // http paramters (qyery, body) tests
    const sendfile_tests = b.addTest(.{
        .name = "sendfile_tests",
        .root_source_file = .{ .path = "src/tests/test_sendfile.zig" },
        .target = target,
        .optimize = optimize,
    });

    sendfile_tests.linkLibrary(facilio);
    sendfile_tests.addModule("zap", zap_module);
    const run_sendfile_tests = b.addRunArtifact(sendfile_tests);
    const install_sendfile_tests = b.addInstallArtifact(sendfile_tests, .{});

    // test commands
    const run_auth_test_step = b.step("test-authentication", "Run auth unit tests [REMOVE zig-cache!]");
    run_auth_test_step.dependOn(&run_auth_tests.step);
    run_auth_test_step.dependOn(&install_auth_tests.step);

    const run_mustache_test_step = b.step("test-mustache", "Run mustache unit tests [REMOVE zig-cache!]");
    run_mustache_test_step.dependOn(&run_mustache_tests.step);
    run_mustache_test_step.dependOn(&install_mustache_tests.step);

    const run_httpparams_test_step = b.step("test-httpparams", "Run http param unit tests [REMOVE zig-cache!]");
    run_httpparams_test_step.dependOn(&run_httpparams_tests.step);
    run_httpparams_test_step.dependOn(&install_httpparams_tests.step);

    const run_sendfile_test_step = b.step("test-sendfile", "Run http param unit tests [REMOVE zig-cache!]");
    run_sendfile_test_step.dependOn(&run_sendfile_tests.step);
    run_sendfile_test_step.dependOn(&install_sendfile_tests.step);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the participant to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_auth_tests.step);
    test_step.dependOn(&run_mustache_tests.step);
    test_step.dependOn(&run_httpparams_tests.step);
    test_step.dependOn(&run_sendfile_tests.step);

    //
    // pkghash
    //
    var pkghash_exe = b.addExecutable(.{
        .name = "pkghash",
        .root_source_file = .{ .path = "./tools/pkghash.zig" },
        .target = target,
        .optimize = optimize,
    });
    var pkghash_step = b.step("pkghash", "Build pkghash");
    const pkghash_build_step = b.addInstallArtifact(pkghash_exe, .{});
    pkghash_step.dependOn(&pkghash_build_step.step);
    all_step.dependOn(&pkghash_build_step.step);

    //
    // announceybot
    //
    var announceybot_exe = b.addExecutable(.{
        .name = "announceybot",
        .root_source_file = .{ .path = "./tools/announceybot.zig" },
        .target = target,
        .optimize = optimize,
    });
    var announceybot_step = b.step("announceybot", "Build announceybot");
    const announceybot_build_step = b.addInstallArtifact(announceybot_exe, .{});
    announceybot_step.dependOn(&announceybot_build_step.step);
    all_step.dependOn(&announceybot_build_step.step);
}
