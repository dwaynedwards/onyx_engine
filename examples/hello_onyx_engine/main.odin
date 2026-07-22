package examples

import "../../onyx"

GameContext :: struct {
    window: ^onyx.Window,
    renderer: ^onyx.Renderer,
}

@(private="file")
g_game: ^GameContext

CORNFLOWER_BLUE :[4]f32 : { 0.332, 0.554, 0.929, 1.0 }

@(export)
onyx_startup :: proc(args: []string) -> onyx.Result {
    config := onyx.Config {
        title = "Onyx Engine",
        width = 1920,
        height = 1080,
    }

    g_game = new(GameContext)
    g_game.window = onyx.window_create(config)
    g_game.renderer = onyx.renderer_create(g_game.window)

    return onyx.Result.CONTINUE
}

@(export)
onyx_event :: proc(event: ^onyx.Event) -> onyx.Result {
    return onyx.Result.CONTINUE
}

@(export)
onyx_update :: proc(delta_time: f64) -> onyx.Result {
    return onyx.Result.CONTINUE
}

@(export)
onyx_fixed_update :: proc(delta_time: f64) -> onyx.Result {
    return onyx.Result.CONTINUE
}

@(export)
onyx_render :: proc(delta_time: f64) -> onyx.Result {
    onyx.renderer_begin(g_game.renderer, CORNFLOWER_BLUE)
    onyx.renderer_end(g_game.renderer)
    return onyx.Result.CONTINUE
}

@(export)
onyx_shutdown :: proc(result: onyx.Result) {
    if g_game == nil {
        return
    }

    onyx.renderer_destroy(g_game.renderer)
    onyx.window_destroy(g_game.window)

    free(g_game)
}

main :: proc() {
    onyx.onyx_run()
}