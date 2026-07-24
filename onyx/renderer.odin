package onyx

import sdl "vendor:sdl3"

RendererHandle :: rawptr

RendererType :: enum {
    Software,
    Gpu,
}

Renderer :: struct {
    type: RendererType,
    handle: RendererHandle,
}

RendererClearColour :: [4]f64

renderer_begin :: proc(renderer: ^Renderer, clear_colour: RendererClearColour) {
    if renderer.type == .Software {
        renderer_sotfware_begin(renderer, clear_colour)
    } else {
        when ODIN_OS == .Darwin {
            renderer_metal_begin(renderer, clear_colour)
        }
    }
}
renderer_end :: proc(renderer: ^Renderer) {
    if renderer.type == .Software {
        renderer_software_end(renderer)
    } else {
        when ODIN_OS == .Darwin {
            renderer_metal_end(renderer)
        }
    }
}

renderer_create :: proc(type: RendererType, window: ^Window, alloc := context.allocator, loc := #caller_location) -> (renderer: ^Renderer) {
    renderer = new(Renderer, alloc)
    assert_panic(renderer != nil, "Failed to allocation Renderer memory")

    _renderer: rawptr
    if type == .Software {
        _renderer = renderer_software_create(window, alloc)
    } else {
        when ODIN_OS == .Darwin {
            _renderer = renderer_metal_create(window, alloc)
        }
    }
    assert_panic(_renderer != nil, "Failed to create Renderer")

    renderer.handle = _renderer
    renderer.type = type

    return
}

renderer_destroy :: proc(renderer: ^Renderer) {
    if renderer == nil {
        return
    }

    if renderer.type == .Software {
        renderer_software_destroy(renderer)
    } else {
        when ODIN_OS == .Darwin {
            renderer_metal_destroy(renderer)
        }
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