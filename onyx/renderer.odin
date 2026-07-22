package onyx

import "core:log"
import sdl "vendor:sdl3"

RendererHandle :: rawptr

Renderer :: struct {
    handle: RendererHandle,
}

RendererClearColour :: [4]f32

renderer_begin :: proc(renderer: ^Renderer, clear_colour: RendererClearColour) {
    r, g, b, a := clear_colour.r, clear_colour.g, clear_colour.b, clear_colour.a
    sdl.SetRenderDrawColorFloat(cast(^sdl.Renderer)renderer.handle, r, g, b, a)
    sdl.RenderClear(cast(^sdl.Renderer)renderer.handle)
}
renderer_end :: proc(renderer: ^Renderer) {
    sdl.RenderPresent(cast(^sdl.Renderer)renderer.handle)
}

renderer_create :: proc(window: ^Window, alloc := context.allocator, loc := #caller_location) -> (renderer: ^Renderer) {
    renderer = new(Renderer, alloc, loc)
    assert_panic(renderer != nil, "Failed to allocation Renderer memory")

    driver: cstring
    when ODIN_OS == .Darwin {
        driver = set_driver_by_priority({ "metal", "gpu", "opengl", "software" })
    } else {
        driver = set_driver_by_priority({ "gpu", "opengl", "software" })
    }

    assert_panic(driver != nil, "Failed to find driver for os: " + ODIN_OS_STRING)
    log.infof("Selected driver: %s", driver)

    renderer.handle = sdl.CreateRenderer(cast(^sdl.Window)window.handle, driver)
    assert_sdl(renderer.handle != nil, "Failed to create SDL Renderer")
    assert_sdl(sdl.SetRenderVSync(cast(^sdl.Renderer)renderer.handle, 1), "Failed to enable VSync")

    return
}

renderer_destroy :: proc(renderer: ^Renderer) {
    if renderer == nil {
        return
    }

    if renderer.handle != nil{
        sdl.DestroyRenderer(cast(^sdl.Renderer)renderer.handle)
    }

    free(renderer)
}

@(private="file")
@require_results
get_driver_names :: proc() -> (driver_list: []cstring, count: i32) {
    count = sdl.GetNumRenderDrivers()
    driver_list = make([]cstring, count, context.temp_allocator)
    for i in 0 ..< count {
        driver_list[i] = sdl.GetRenderDriver(i)
    }
    return
}

@(private="file")
set_driver_by_priority :: proc(priority_list: []cstring) -> cstring {
    driver_list, _ := get_driver_names()
    for priority in priority_list {
        for driver in driver_list {
            if driver == priority {
                return driver
            }
        }
    }
    return nil
}