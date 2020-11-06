const std = @import("std");
const backend = @import("backend");
const gfx = @import("../gfx.zig");
const stb_image = @import("stb");
const fs = @import("../fs.zig");

pub const Texture = struct {
    img: gfx.Image,
    width: f32 = 0,
    height: f32 = 0,

    pub fn init(width: i32, height: i32) Texture {
        return initWithOptions(width, height, .nearest, .clamp);
    }

    pub fn initWithOptions(width: i32, height: i32, filter: gfx.TextureFilter, wrap: gfx.TextureWrap) Texture {
        return initWithDataOptions(u8, width, height, &[_]u8{}, filter, wrap);
    }

    pub fn initFromFile(allocator: *std.mem.Allocator, file: []const u8, filter: gfx.TextureFilter) !gfx.Texture {
        const image_contents = try fs.read(allocator, file);
        errdefer allocator.free(image_contents);

        var w: c_int = undefined;
        var h: c_int = undefined;
        var channels: c_int = undefined;
        const load_res = stb_image.stbi_load_from_memory(image_contents.ptr, @intCast(c_int, image_contents.len), &w, &h, &channels, 4);
        if (load_res == null) return error.ImageLoadFailed;
        defer stb_image.stbi_image_free(load_res);

        return initWithDataOptions(u8, w, h, load_res[0..@intCast(usize, w * h * channels)], filter, .clamp);
    }

    pub fn initWithData(comptime T: type, width: i32, height: i32, pixels: []T) gfx.Texture {
        return initWithDataOptions(T, width, height, pixels, .nearest, .clamp);
    }

    pub fn initWithDataOptions(comptime T: type, width: i32, height: i32, pixels: []T, filter: gfx.TextureFilter, wrap: gfx.TextureWrap) gfx.Texture {
        const img = backend.createImage(.{
            .width = width,
            .height = height,
            .min_filter = filter,
            .mag_filter = filter,
            .wrap_u = wrap,
            .wrap_v = wrap,
            .content = std.mem.sliceAsBytes(pixels),
        });
        return .{
            .img = img,
            .width = @intToFloat(f32, width),
            .height = @intToFloat(f32, height),
        };
    }

    pub fn initCheckerTexture() gfx.Texture {
        var pixels = [_]u32{
            0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
            0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
            0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
            0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
        };

        return initWithData(u32, 4, 4, &pixels);
    }

    pub fn initSingleColor(color: u32) gfx.Texture {
        var pixels: [16]u32 = undefined;
        std.mem.set(u32, &pixels, color);
        return initWithData(u32, 4, 4, pixels[0..]);
    }

    pub fn initOffscreen(width: i32, height: i32, filter: gfx.TextureFilter, wrap: gfx.TextureWrap) gfx.Texture {
        const img = backend.createImage(.{
            .render_target = true,
            .width = width,
            .height = height,
            .min_filter = filter,
            .mag_filter = filter,
            .wrap_u = wrap,
            .wrap_v = wrap,
        });
        return .{
            .img = img,
            .width = @intToFloat(f32, width),
            .height = @intToFloat(f32, height),
        };
    }

    pub fn initStencil(width: i32, height: i32, filter: gfx.TextureFilter, wrap: gfx.TextureWrap) gfx.Texture {
        const img = backend.createImage(.{
            .render_target = true,
            .pixel_format = .stencil,
            .width = width,
            .height = height,
            .min_filter = filter,
            .mag_filter = filter,
            .wrap_u = wrap,
            .wrap_v = wrap,
        });
        return .{
            .img = img,
            .width = @intToFloat(f32, width),
            .height = @intToFloat(f32, height),
        };
    }

    pub fn deinit(self: *const Texture) void {
        backend.destroyImage(self.img);
    }

    pub fn setData(self: *Texture, comptime T: type, data: []T) void {
        backend.updateImage(T, self.img, data);
    }
};
