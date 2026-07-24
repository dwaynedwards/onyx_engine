package onyx

import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"
import sdl "vendor:sdl3"

RendererMetal :: struct {
    ns_window: ^NS.Window,
    mtl_device: ^MTL.Device,
    mtl_swapchain: ^CA.MetalLayer,
    mtl_pso: ^MTL.RenderPipelineState,
    mtl_command_queue : ^MTL.CommandQueue,
    ca_drawable: ^CA.MetalDrawable,
    mtl_pass: ^MTL.RenderPassDescriptor,
}

renderer_metal_begin :: proc(renderer: ^Renderer, clear_colour: RendererClearColour) {
    _renderer := cast(^RendererMetal)renderer.handle
    r, g, b, a := clear_colour.r, clear_colour.g, clear_colour.b, clear_colour.a

    _renderer.ca_drawable = _renderer.mtl_swapchain->nextDrawable()

    _renderer.mtl_pass = MTL.RenderPassDescriptor.renderPassDescriptor()

    color_attachment := _renderer.mtl_pass->colorAttachments()->object(0)
    color_attachment->setClearColor(MTL.ClearColor{ r, g, b, a })
    color_attachment->setLoadAction(.Clear)
    color_attachment->setStoreAction(.Store)
    color_attachment->setTexture(_renderer.ca_drawable->texture())
}

renderer_metal_end :: proc(renderer: ^Renderer) {
    _renderer := cast(^RendererMetal)renderer.handle

    defer _renderer.ca_drawable->release()
    defer _renderer.mtl_pass->release()

    command_buffer := _renderer.mtl_command_queue->commandBuffer()
    defer command_buffer->release()

    render_encoder := command_buffer->renderCommandEncoderWithDescriptor(_renderer.mtl_pass)
    defer render_encoder->release()

    render_encoder->setRenderPipelineState(_renderer.mtl_pso)
    render_encoder->drawPrimitives(.Triangle, 0, 3)

    render_encoder->endEncoding()

    command_buffer->presentDrawable(_renderer.ca_drawable)
    command_buffer->commit()
}

renderer_metal_create :: proc(window: ^Window, alloc := context.allocator, loc := #caller_location) -> (renderer_metal: ^RendererMetal) {
    renderer_metal = new(RendererMetal, alloc)
    assert_panic(renderer_metal != nil, "Failed to allocate RendererMetall memory")

    _ns_window := cast(^NS.Window)sdl.GetPointerProperty(sdl.GetWindowProperties(window.handle), sdl.PROP_WINDOW_COCOA_WINDOW_POINTER, nil)
    assert_panic(_ns_window != nil, "Failed to get NSWindow")

    _mtl_device := MTL.CreateSystemDefaultDevice()
    assert_panic(_mtl_device != nil, "Failed to create MTLDevice")

    _mtl_swapchain := CA.MetalLayer.layer()
    assert_panic(_mtl_device != nil, "Failed to create CAMetalLayer")

    _mtl_swapchain->setDevice(_mtl_device)
    _mtl_swapchain->setPixelFormat(.BGRA8Unorm_sRGB)
    _mtl_swapchain->setFramebufferOnly(true)
    _mtl_swapchain->setFrame(_ns_window->frame())

    _ns_window->contentView()->setLayer(_mtl_swapchain)
    _ns_window->setOpaque(true)
    _ns_window->setBackgroundColor(nil)

    shader_src := `
		struct v2f {
			float4 position [[position]];
			half3 color;
		};
		v2f vertex vertex_main(uint vertex_id [[vertex_id]]) {
			float2 positions[3] = { float2(-0.5, -0.5), float2(0.0, 0.5), float2(0.5, -0.5) };
			half3 colours[3] = { half3(1.0, 0.0, 0.0), half3(0.0, 1.0, 0.0), half3(0.0, 0.0, 1.0) };
			v2f o;
			o.position = float4(positions[vertex_id], 0.0, 1.0);
			o.color = colours[vertex_id];
			return o;
		}
		half4 fragment fragment_main(v2f in [[stage_in]]) {
			return half4(in.color, 1.0);
		}
		`
    shader_src_str := NS.String.alloc()->initWithOdinString(shader_src)
    assert_panic(shader_src_str != nil, "Failed to create Shader source string")
    defer shader_src_str->release()

    library, library_err := _mtl_device->newLibraryWithSource(shader_src_str, nil)
    assert_panic(library_err == nil, "Failed to create MTLLibrary: ", library_err->localizedFailureReason()->odinString())
    defer library->release()

    vertex_function := library->newFunctionWithName(NS.AT("vertex_main"))
    assert_panic(vertex_function != nil, "Failed to create Vertex MTLFunction")
    fragment_function := library->newFunctionWithName(NS.AT("fragment_main"))
    assert_panic(fragment_function != nil, "Failed to create Fragment MTLFunction")
    defer vertex_function->release()
    defer fragment_function->release()

    desc := MTL.RenderPipelineDescriptor.alloc()->init()
    assert_panic(desc != nil, "Failed to create MTLRenderPipelineDescriptor")
    defer desc->release()

    desc->setVertexFunction(vertex_function)
    desc->setFragmentFunction(fragment_function)
    desc->colorAttachments()->object(0)->setPixelFormat(.BGRA8Unorm_sRGB)

    _mtl_pso, pso_err := _mtl_device->newRenderPipelineStateWithDescriptor(desc)
    assert_panic(pso_err == nil, "Failed to create MTLRenderPipelineState: ", pso_err->localizedFailureReason()->odinString())

    _mtl_command_queue := _mtl_device->newCommandQueue()

    renderer_metal.ns_window = _ns_window
    renderer_metal.mtl_device = _mtl_device
    renderer_metal.mtl_swapchain = _mtl_swapchain
    renderer_metal.mtl_pso = _mtl_pso
    renderer_metal.mtl_command_queue = _mtl_command_queue
    return
}

renderer_metal_destroy :: proc(renderer: ^Renderer) {
    if renderer == nil {
        return
    }

    _renderer := cast(^RendererMetal)renderer.handle
    if _renderer == nil {
        return
    }

    if _renderer.mtl_pso != nil {
        _renderer.mtl_pso->release()
    }

    if _renderer.mtl_command_queue != nil {
        _renderer.mtl_command_queue->release()
    }

    if _renderer.mtl_swapchain != nil {
        _renderer.mtl_swapchain->release()
    }

    if _renderer.mtl_device != nil {
        _renderer.mtl_device->release()
    }

    if _renderer.ns_window != nil {
        _renderer.ns_window->release()
    }
}