package onyx

import "core:log"
import "core:os"
import "base:runtime"
import sdl "vendor:sdl3"

foreign {
    onyx_startup :: proc "odin" (args: []string) -> Result ---
    onyx_event :: proc "odin" (event: ^Event) -> Result ---
    onyx_update :: proc "odin" (delta_time: f64) -> Result ---
    onyx_fixed_update :: proc "odin" (delta_time: f64) -> Result ---
    onyx_render :: proc "odin" (delta_time: f64) -> Result ---
    onyx_shutdown :: proc "odin" (result: Result) ---
}

Config :: struct {
    title: string,
    width: u32,
    height: u32,
}

Result :: enum i32 {
    CONTINUE,
    SUCCESS,
    FAILURE,
}

PAUSE_RENDERING_SLEEP_TIME :: 100

@(private="file")
g_context: runtime.Context

@(private="file")
g_pause_rendering: b32

onyx_run :: proc() {
    g_context = context

    if g_context.logger.procedure == runtime.default_logger_proc {
        g_context.logger = log.create_console_logger(.Debug)
        log_alloc: log.Log_Allocator
        log.log_allocator_init(&log_alloc, .Debug)
        g_context.allocator = log.log_allocator(&log_alloc)
    }

    argv := cast([^]cstring)raw_data(os.args)
    argc := cast(i32)len(os.args)
    sdl.EnterAppMainCallbacks(argc, argv, init, iterate, event, quit)
}

@(private="file")
init :: proc "c" (appstate: ^rawptr, argc: i32, argv: [^]cstring) -> sdl.AppResult {
    context = g_context

    log.info("Starting up Onyx Engine")

    assert_sdl(sdl.Init(sdl.INIT_VIDEO | sdl.INIT_EVENTS), "Failed to initialize SDL")

    args := make([]string, argc, context.temp_allocator)
    for i in 0 ..< argc {
        args[i] = string(argv[i])
    }
    result := cast(sdl.AppResult)onyx_startup(args)
    if result != .CONTINUE {
        return result
    }

    g_pause_rendering = false

    log.info("Onyx Engine started")

    return result
}

@(private="file")
event :: proc "c" (appstate: rawptr, event: ^sdl.Event) -> sdl.AppResult {
    context = g_context

    #partial switch event.type {
    case .QUIT:
        return .SUCCESS
    case .WINDOW_MINIMIZED:
        g_pause_rendering = true
    case .WINDOW_MAXIMIZED:
        g_pause_rendering = false
    case .WINDOW_RESTORED:
        g_pause_rendering = false
    case .WINDOW_RESIZED:
        g_pause_rendering = false
    }

    result := cast(sdl.AppResult)onyx_event(cast(^Event)event)
    if result != .CONTINUE {
        return result
    }

    return result
}

@(private="file")
iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
    context = g_context

    if g_pause_rendering {
        sdl.Delay(PAUSE_RENDERING_SLEEP_TIME)
        return .CONTINUE
    }

    result := cast(sdl.AppResult)onyx_update(0.0)
    if result != .CONTINUE {
        return result
    }

    result = cast(sdl.AppResult)onyx_fixed_update(0.0)
    if result != .CONTINUE {
        return result
    }

    result = cast(sdl.AppResult)onyx_render(0.0)
    if result != .CONTINUE {
        return result
    }

    free_all(context.temp_allocator)

    return result
}

@(private="file")
quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
    context = g_context

    log.info("Shutting down Onyx Engine")

    onyx_shutdown(cast(Result)result)

    sdl.Quit()

    log.info("Onyx Engine shutdown")
}
