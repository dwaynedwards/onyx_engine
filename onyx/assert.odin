package onyx

import "core:log"
import sdl "vendor:sdl3"

assert_panic :: proc(condition: bool, args: ..any, loc := #caller_location) {
    if !condition {
        log.panic(..args, location = loc)
    }
}

assert_sdl :: proc(condition: bool, msg: string, loc := #caller_location) {
    if !condition {
        log.panicf("SDL Error: %s: %s", msg, sdl.GetError(), location = loc)
    }
}