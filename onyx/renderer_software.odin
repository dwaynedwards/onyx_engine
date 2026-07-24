package onyx

import "core:log"
import sdl "vendor:sdl3"

RendererSoftware :: struct {
    handle: ^sdl.Renderer,
    window: ^Window,
}

renderer_sotfware_begin :: proc(renderer: ^Renderer, clear_colour: RendererClearColour) {
    _renderer := cast(^RendererSoftware)renderer.handle
    r, g, b, a := clear_colour.r, clear_colour.g, clear_colour.b, clear_colour.a

    sdl.SetRenderDrawColorFloat(_renderer.handle, cast(f32)r, cast(f32)g, cast(f32)b, cast(f32)a)
    sdl.RenderClear(_renderer.handle)
}

renderer_software_end :: proc(renderer: ^Renderer) {
    _renderer := cast(^RendererSoftware)renderer.handle

    sdl.RenderPresent(_renderer.handle)
}

renderer_software_create :: proc(window: ^Window, alloc := context.allocator, loc := #caller_location) -> (renderer: ^RendererSoftware) {
    renderer = new(RendererSoftware, alloc)
    assert_panic(renderer != nil, "Failed to allocation RendererSoftware memory")

    driver: cstring
    when ODIN_OS == .Darwin {
        driver = set_driver_by_priority({ "metal", "gpu", "opengl", "software" })
    } else {
        driver = set_driver_by_priority({ "gpu", "opengl", "software" })
    }

    assert_panic(driver != nil, "Failed to find driver for os: " + ODIN_OS_STRING)
    log.debugf("Selected driver: %s", driver)

    _renderer := sdl.CreateRenderer(window.handle, driver)
    assert_sdl(_renderer != nil, "Failed to create SDL Renderer")
    assert_sdl(sdl.SetRenderVSync(_renderer, 1), "Failed to enable VSync")

    renderer.handle = _renderer
    return
}

renderer_software_destroy :: proc(renderer: ^Renderer) {
    if renderer == nil {
        return
    }

    _renderer := cast(^RendererSoftware)renderer.handle
    if _renderer == nil {
        return
    }

    if _renderer.handle != nil{
        sdl.DestroyRenderer(_renderer.handle)
    }

    free(_renderer)
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