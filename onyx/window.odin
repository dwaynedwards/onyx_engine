package onyx

import "core:c"
import "core:strings"
import sdl "vendor:sdl3"

WindowHandle :: rawptr

Window :: struct {
    handle: WindowHandle,
    width: u32,
    height: u32,
}

window_create :: proc (config: Config, alloc:= context.allocator, loc := #caller_location) -> (window: ^Window) {
    title := strings.clone_to_cstring(config.title, context.temp_allocator, loc)
    flags := sdl.WINDOW_HIGH_PIXEL_DENSITY | sdl.WINDOW_RESIZABLE
    when ODIN_OS == .Darwin {
        flags |= sdl.WINDOW_METAL
    }

    window = new(Window, alloc, loc)
    assert_panic(window != nil, "Failed to allocation Window memory")

    window.handle = sdl.CreateWindow(title, cast(c.int)config.width, cast(c.int)config.height, flags)
    assert_sdl(window.handle != nil, "Failed to create SDL Window")

    window.width = config.width
    window.height = config.height

    return
}

window_destroy :: proc (window: ^Window) {
    if window == nil {
        return
    }

    if window.handle != nil {
        sdl.DestroyWindow(cast(^sdl.Window)window.handle)
    }

    free(window)
}