-- Pure Lua PDF Library
-- Simple and efficient PDF generation without external dependencies

local PDF = {}
PDF.__index = PDF

local Utils = {}
local Helper = {}
local QuickRef = {}
local unpack_values = table.unpack or unpack

-- Utility functions
local function mm_to_pt(mm)
    return mm * 2.83464567  -- 1 mm = 2.83464567 points
end

local function normalize_rgb(r, g, b)
    if r > 1 or g > 1 or b > 1 then
        return r / 255, g / 255, b / 255
    end
    return r, g, b
end

local function read_u32_be(data, pos)
    local a, b, c, d = string.byte(data, pos, pos + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
end

local function read_u16_be(data, pos)
    local a, b = string.byte(data, pos, pos + 1)
    return a * 256 + b
end

local function reverse_bits(value, width)
    local reversed = 0
    for _ = 1, width do
        reversed = reversed * 2 + (value % 2)
        value = math.floor(value / 2)
    end
    return reversed
end

local function build_huffman(lengths)
    local max_len = 0
    for i = 1, #lengths do
        if lengths[i] > max_len then
            max_len = lengths[i]
        end
    end

    local counts = {}
    for len = 0, max_len do
        counts[len] = 0
    end
    for i = 1, #lengths do
        counts[lengths[i]] = counts[lengths[i]] + 1
    end

    local next_code = {}
    local code = 0
    counts[0] = counts[0] or 0
    for bits = 1, max_len do
        code = (code + (counts[bits - 1] or 0)) * 2
        next_code[bits] = code
    end

    local lookup = {}
    for len = 1, max_len do
        lookup[len] = {}
    end

    for symbol = 0, #lengths - 1 do
        local len = lengths[symbol + 1]
        if len > 0 then
            local assigned = next_code[len]
            next_code[len] = assigned + 1
            lookup[len][reverse_bits(assigned, len)] = symbol
        end
    end

    return {
        lookup = lookup,
        max_len = max_len,
    }
end

local function inflate_zlib(data)
    if #data < 2 then
        error("Invalid zlib stream")
    end

    local cmf = string.byte(data, 1)
    local flg = string.byte(data, 2)
    if cmf % 16 ~= 8 then
        error("Unsupported zlib compression method")
    end
    if ((cmf * 256) + flg) % 31 ~= 0 then
        error("Invalid zlib header checksum")
    end
    if math.floor(flg / 32) % 2 == 1 then
        error("Preset zlib dictionaries are not supported")
    end

    local bit_pos = 17

    local function read_bits(count)
        local value = 0
        local factor = 1
        for _ = 1, count do
            local byte_index = math.floor((bit_pos - 1) / 8) + 1
            local byte = string.byte(data, byte_index)
            if not byte then
                error("Unexpected end of deflate stream")
            end
            local bit_index = (bit_pos - 1) % 8
            local bit = math.floor(byte / (2 ^ bit_index)) % 2
            value = value + bit * factor
            factor = factor * 2
            bit_pos = bit_pos + 1
        end
        return value
    end

    local function align_to_byte()
        local mod = (bit_pos - 1) % 8
        if mod ~= 0 then
            bit_pos = bit_pos + (8 - mod)
        end
    end

    local function decode_symbol(tree)
        local code = 0
        local factor = 1
        for len = 1, tree.max_len do
            local bit = read_bits(1)
            code = code + bit * factor
            local symbol = tree.lookup[len][code]
            if symbol ~= nil then
                return symbol
            end
            factor = factor * 2
        end
        error("Invalid huffman code")
    end

    local fixed_literal_lengths = {}
    for i = 0, 287 do
        if i <= 143 then
            fixed_literal_lengths[i + 1] = 8
        elseif i <= 255 then
            fixed_literal_lengths[i + 1] = 9
        elseif i <= 279 then
            fixed_literal_lengths[i + 1] = 7
        else
            fixed_literal_lengths[i + 1] = 8
        end
    end
    local fixed_distance_lengths = {}
    for i = 1, 32 do
        fixed_distance_lengths[i] = 5
    end
    local fixed_literal_tree = build_huffman(fixed_literal_lengths)
    local fixed_distance_tree = build_huffman(fixed_distance_lengths)

    local length_bases = {3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258}
    local length_extras = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0}
    local distance_bases = {1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577}
    local distance_extras = {0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13}

    local out = {}
    local out_len = 0

    local function append_byte(byte)
        out_len = out_len + 1
        out[out_len] = byte
    end

    local function append_bytes(bytes)
        for i = 1, #bytes do
            append_byte(string.byte(bytes, i))
        end
    end

    local last_block = 0
    while last_block == 0 do
        last_block = read_bits(1)
        local block_type = read_bits(2)
        local literal_tree
        local distance_tree

        if block_type == 0 then
            align_to_byte()
            local byte_index = math.floor((bit_pos - 1) / 8) + 1
            local len1, len2, nlen1, nlen2 = string.byte(data, byte_index, byte_index + 3)
            local len = len1 + len2 * 256
            local nlen = nlen1 + nlen2 * 256
            if len ~= 65535 - nlen then
                error("Invalid uncompressed deflate block")
            end
            bit_pos = bit_pos + 32
            local start = math.floor((bit_pos - 1) / 8) + 1
            append_bytes(data:sub(start, start + len - 1))
            bit_pos = bit_pos + len * 8
        else
            if block_type == 1 then
                literal_tree = fixed_literal_tree
                distance_tree = fixed_distance_tree
            elseif block_type == 2 then
                local hlit = read_bits(5) + 257
                local hdist = read_bits(5) + 1
                local hclen = read_bits(4) + 4
                local code_length_order = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}
                local code_length_lengths = {}
                for i = 1, 19 do
                    code_length_lengths[i] = 0
                end
                for i = 1, hclen do
                    code_length_lengths[code_length_order[i] + 1] = read_bits(3)
                end
                local code_length_tree = build_huffman(code_length_lengths)
                local lengths = {}
                local target = hlit + hdist
                local index = 1
                while index <= target do
                    local symbol = decode_symbol(code_length_tree)
                    if symbol <= 15 then
                        lengths[index] = symbol
                        index = index + 1
                    elseif symbol == 16 then
                        local repeat_count = read_bits(2) + 3
                        local previous = lengths[index - 1] or 0
                        for _ = 1, repeat_count do
                            lengths[index] = previous
                            index = index + 1
                        end
                    elseif symbol == 17 then
                        local repeat_count = read_bits(3) + 3
                        for _ = 1, repeat_count do
                            lengths[index] = 0
                            index = index + 1
                        end
                    elseif symbol == 18 then
                        local repeat_count = read_bits(7) + 11
                        for _ = 1, repeat_count do
                            lengths[index] = 0
                            index = index + 1
                        end
                    else
                        error("Invalid code length symbol")
                    end
                end

                local literal_lengths = {}
                local distance_lengths = {}
                for i = 1, hlit do
                    literal_lengths[i] = lengths[i] or 0
                end
                for i = 1, hdist do
                    distance_lengths[i] = lengths[hlit + i] or 0
                end
                literal_tree = build_huffman(literal_lengths)
                distance_tree = build_huffman(distance_lengths)
            else
                error("Reserved deflate block type")
            end

            while true do
                local symbol = decode_symbol(literal_tree)
                if symbol < 256 then
                    append_byte(symbol)
                elseif symbol == 256 then
                    break
                else
                    local len_index = symbol - 257 + 1
                    local length = length_bases[len_index] + read_bits(length_extras[len_index])
                    local dist_symbol = decode_symbol(distance_tree)
                    local distance = distance_bases[dist_symbol + 1] + read_bits(distance_extras[dist_symbol + 1])
                    for _ = 1, length do
                        append_byte(out[out_len - distance + 1])
                    end
                end
            end
        end
    end

    local chunks = {}
    local chunk = {}
    for i = 1, out_len do
        chunk[#chunk + 1] = string.char(out[i])
        if #chunk >= 4096 then
            chunks[#chunks + 1] = table.concat(chunk)
            chunk = {}
        end
    end
    if #chunk > 0 then
        chunks[#chunks + 1] = table.concat(chunk)
    end
    return table.concat(chunks)
end

local function scale_sample(sample, bit_depth)
    if bit_depth == 8 then
        return sample
    elseif bit_depth == 16 then
        return math.floor(sample / 257)
    end
    local max = (2 ^ bit_depth) - 1
    if max == 0 then
        return 0
    end
    return math.floor((sample * 255) / max + 0.5)
end

local function unpack_samples(row, width, samples_per_pixel, bit_depth)
    local samples = {}
    local index = 1
    if bit_depth == 8 then
        for i = 1, width * samples_per_pixel do
            samples[i] = string.byte(row, index)
            index = index + 1
        end
    elseif bit_depth == 16 then
        for i = 1, width * samples_per_pixel do
            samples[i] = read_u16_be(row, index)
            index = index + 2
        end
    else
        local samples_per_byte = 8 / bit_depth
        local mask = (2 ^ bit_depth) - 1
        local out_index = 1
        for i = 1, #row do
            local byte = string.byte(row, i)
            for offset = samples_per_byte - 1, 0, -1 do
                if out_index > width * samples_per_pixel then
                    break
                end
                samples[out_index] = math.floor(byte / (2 ^ (offset * bit_depth))) % (mask + 1)
                out_index = out_index + 1
            end
        end
    end
    return samples
end

local function unfilter_scanlines(data, width, height, bits_per_pixel)
    local bpp = math.max(1, math.ceil(bits_per_pixel / 8))
    local row_bytes = math.ceil(width * bits_per_pixel / 8)
    local rows = {}
    local pos = 1
    local previous = nil

    for _ = 1, height do
        local filter_type = string.byte(data, pos)
        local row = {string.byte(data, pos + 1, pos + row_bytes)}
        pos = pos + 1 + row_bytes

        if filter_type == 1 then
            for i = 1, #row do
                local left = i > bpp and row[i - bpp] or 0
                row[i] = (row[i] + left) % 256
            end
        elseif filter_type == 2 then
            for i = 1, #row do
                local up = previous and previous[i] or 0
                row[i] = (row[i] + up) % 256
            end
        elseif filter_type == 3 then
            for i = 1, #row do
                local left = i > bpp and row[i - bpp] or 0
                local up = previous and previous[i] or 0
                row[i] = (row[i] + math.floor((left + up) / 2)) % 256
            end
        elseif filter_type == 4 then
            local function paeth(a, b, c)
                local p = a + b - c
                local pa = math.abs(p - a)
                local pb = math.abs(p - b)
                local pc = math.abs(p - c)
                if pa <= pb and pa <= pc then
                    return a
                elseif pb <= pc then
                    return b
                end
                return c
            end
            for i = 1, #row do
                local left = i > bpp and row[i - bpp] or 0
                local up = previous and previous[i] or 0
                local up_left = (previous and i > bpp) and previous[i - bpp] or 0
                row[i] = (row[i] + paeth(left, up, up_left)) % 256
            end
        elseif filter_type ~= 0 then
            error("Unsupported PNG filter type: " .. tostring(filter_type))
        end

        previous = row
        rows[#rows + 1] = string.char(unpack_values(row))
    end

    return rows
end

local function decode_png_pixels(png)
    local channel_count_by_color = {
        [0] = 1,
        [2] = 3,
        [3] = 1,
        [4] = 2,
        [6] = 4,
    }
    local samples_per_pixel = channel_count_by_color[png.color_type]
    if not samples_per_pixel then
        error("Unsupported PNG color type: " .. tostring(png.color_type))
    end

    local bits_per_pixel = samples_per_pixel * png.bit_depth
    local width = png.width
    local height = png.height
    local rgb = {}
    local alpha = {}
    local has_alpha = png.color_type == 4 or png.color_type == 6 or png.trns ~= nil

    local function set_pixel(x, y, r, g, b, a)
        local pixel_index = y * width + x
        local rgb_index = pixel_index * 3 + 1
        rgb[rgb_index] = string.char(r)
        rgb[rgb_index + 1] = string.char(g)
        rgb[rgb_index + 2] = string.char(b)
        if has_alpha then
            alpha[pixel_index + 1] = string.char(a or 255)
        end
    end

    local function process_pass(pass_data, pass_width, pass_height, start_x, start_y, step_x, step_y)
        if pass_width == 0 or pass_height == 0 then
            return
        end
        local rows = unfilter_scanlines(pass_data, pass_width, pass_height, bits_per_pixel)
        for row_index = 1, #rows do
            local samples = unpack_samples(rows[row_index], pass_width, samples_per_pixel, png.bit_depth)
            local sample_index = 1
            for column = 0, pass_width - 1 do
                local dest_x = start_x + column * step_x
                local dest_y = start_y + (row_index - 1) * step_y
                local r, g, b, a = 0, 0, 0, 255
                if png.color_type == 0 then
                    local gray = samples[sample_index]
                    sample_index = sample_index + 1
                    local gray8 = scale_sample(gray, png.bit_depth)
                    r, g, b = gray8, gray8, gray8
                    if png.trns and gray == png.trns.gray then
                        a = 0
                    end
                elseif png.color_type == 2 then
                    local raw_r = samples[sample_index]
                    local raw_g = samples[sample_index + 1]
                    local raw_b = samples[sample_index + 2]
                    sample_index = sample_index + 3
                    r = scale_sample(raw_r, png.bit_depth)
                    g = scale_sample(raw_g, png.bit_depth)
                    b = scale_sample(raw_b, png.bit_depth)
                    if png.trns and raw_r == png.trns.r and raw_g == png.trns.g and raw_b == png.trns.b then
                        a = 0
                    end
                elseif png.color_type == 3 then
                    local idx = samples[sample_index]
                    sample_index = sample_index + 1
                    local palette_offset = idx * 3 + 1
                    r = string.byte(png.palette, palette_offset) or 0
                    g = string.byte(png.palette, palette_offset + 1) or 0
                    b = string.byte(png.palette, palette_offset + 2) or 0
                    if png.trns then
                        a = string.byte(png.trns, idx + 1) or 255
                    end
                elseif png.color_type == 4 then
                    local gray = samples[sample_index]
                    local alpha_sample = samples[sample_index + 1]
                    sample_index = sample_index + 2
                    local gray8 = scale_sample(gray, png.bit_depth)
                    r, g, b = gray8, gray8, gray8
                    a = scale_sample(alpha_sample, png.bit_depth)
                elseif png.color_type == 6 then
                    r = scale_sample(samples[sample_index], png.bit_depth)
                    g = scale_sample(samples[sample_index + 1], png.bit_depth)
                    b = scale_sample(samples[sample_index + 2], png.bit_depth)
                    a = scale_sample(samples[sample_index + 3], png.bit_depth)
                    sample_index = sample_index + 4
                end
                set_pixel(dest_x, dest_y, r, g, b, a)
            end
        end
    end

    if png.interlace == 0 then
        process_pass(png.raw_data, width, height, 0, 0, 1, 1)
    elseif png.interlace == 1 then
        local passes = {
            {0, 0, 8, 8},
            {4, 0, 8, 8},
            {0, 4, 4, 8},
            {2, 0, 4, 4},
            {0, 2, 2, 4},
            {1, 0, 2, 2},
            {0, 1, 1, 2},
        }
        local pos = 1
        for _, pass in ipairs(passes) do
            local start_x, start_y, step_x, step_y = pass[1], pass[2], pass[3], pass[4]
            local pass_width = width <= start_x and 0 or math.floor((width - start_x + step_x - 1) / step_x)
            local pass_height = height <= start_y and 0 or math.floor((height - start_y + step_y - 1) / step_y)
            if pass_width > 0 and pass_height > 0 then
                local row_bytes = math.ceil(pass_width * bits_per_pixel / 8)
                local pass_size = pass_height * (1 + row_bytes)
                process_pass(png.raw_data:sub(pos, pos + pass_size - 1), pass_width, pass_height, start_x, start_y, step_x, step_y)
                pos = pos + pass_size
            end
        end
    else
        error("Unsupported PNG interlace method")
    end

    local rgb_data = table.concat(rgb)
    local alpha_data = has_alpha and table.concat(alpha) or nil
    return rgb_data, alpha_data
end

local function parse_png(data)
    local signature = "\137PNG\r\n\26\n"
    if data:sub(1, 8) ~= signature then
        error("Not a PNG file")
    end

    local png = {
        idat = {},
        palette = nil,
        trns = nil,
    }

    local pos = 9
    while pos <= #data do
        local length = read_u32_be(data, pos)
        local chunk_type = data:sub(pos + 4, pos + 7)
        local chunk_data = data:sub(pos + 8, pos + 7 + length)
        if chunk_type == "IHDR" then
            png.width = read_u32_be(chunk_data, 1)
            png.height = read_u32_be(chunk_data, 5)
            png.bit_depth = string.byte(chunk_data, 9)
            png.color_type = string.byte(chunk_data, 10)
            png.compression = string.byte(chunk_data, 11)
            png.filter = string.byte(chunk_data, 12)
            png.interlace = string.byte(chunk_data, 13)
            if png.compression ~= 0 or png.filter ~= 0 then
                error("Unsupported PNG compression/filter method")
            end
        elseif chunk_type == "PLTE" then
            png.palette = chunk_data
        elseif chunk_type == "tRNS" then
            png.trns = chunk_data
        elseif chunk_type == "IDAT" then
            png.idat[#png.idat + 1] = chunk_data
        elseif chunk_type == "IEND" then
            break
        end

        pos = pos + 12 + length
    end

    if not png.width then
        error("PNG missing IHDR")
    end

    if png.color_type == 0 then
        if png.trns and #png.trns >= 2 then
            png.trns = {gray = read_u16_be(png.trns, 1)}
        else
            png.trns = nil
        end
    elseif png.color_type == 2 then
        if png.trns and #png.trns >= 6 then
            png.trns = {
                r = read_u16_be(png.trns, 1),
                g = read_u16_be(png.trns, 3),
                b = read_u16_be(png.trns, 5),
            }
        else
            png.trns = nil
        end
    elseif png.color_type ~= 3 then
        png.trns = nil
    end

    png.raw_data = inflate_zlib(table.concat(png.idat))
    return png
end

-- PDF Page class
local Page = {}
Page.__index = Page

function Page.new(width, height)
    return setmetatable({
        width = width,
        height = height,
        contents = {},
        annotations = {},
        resources = {
            Font = {},
            XObject = {},
            ColorSpace = {},
            Shading = {}
        }
    }, Page)
end

function Page:add_content(content)
    table.insert(self.contents, content)
end

function Page:get_content_stream()
    return table.concat(self.contents, "\n")
end

-- Main PDF Document class
function PDF.new()
    return setmetatable({
        pages = {},
        fonts = {},
        images = {},
        image_cache = {},
        current_page = nil,
        current_font = nil,
        current_font_size = 12,
        current_color_fill = {0, 0, 0},
        current_color_stroke = {0, 0, 0},
        current_line_width = 0.5,
        compression = true,
        forms = {},
        title = "Untitled",
        author = "Lua PDF Library",
        subject = "",
        created = os.date("D:%Y%m%d%H%M%S")
    }, PDF)
end

function PDF:add_page(width, height, orientation)
    orientation = orientation or "P"
    
    if orientation == "L" then
        width, height = height, width
    end
    
    local page = Page.new(width, height)
    table.insert(self.pages, page)
    page.index = #self.pages
    self.current_page = page
    
    return page
end

function PDF:set_font(family, style, size)
    style = style or ""
    size = size or 12
    
    local font_key = family .. "-" .. style
    
    if not self.fonts[font_key] then
        self.fonts[font_key] = {
            family = family,
            style = style,
            base_font = self:_get_base_font_name(family, style)
        }
    end
    
    self.current_font = font_key
    self.current_font_size = size
end

function PDF:_get_base_font_name(family, style)
    local fonts = {
        Helvetica = "Helvetica",
        Times = "Times-Roman",
        Courier = "Courier"
    }
    
    local base = fonts[family] or "Helvetica"
    
    if style == "B" then
        base = base .. "-Bold"
    elseif style == "I" then
        base = base .. "-Oblique"
    elseif style == "BI" then
        base = base .. "-BoldOblique"
    end
    
    return base
end

function PDF:text(x, y, text, width, align)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    
    align = align or "L"
    width = width or 0
    
    -- Convert mm to points
    local x_pt = mm_to_pt(x)
    local font_size = self.current_font_size
    local text_width_pt = self:_estimate_text_width_pt(text, font_size)
    local text_ascent_pt = self:_estimate_text_ascent_pt(font_size)
    local y_pt = self.current_page.height * 2.83464567 - mm_to_pt(y) - text_ascent_pt
    
    -- Generate font reference
    local font_name = "F" .. self:_get_font_index(self.current_font)
    
    -- Apply simple alignment. When width is omitted, treat x as the anchor point.
    if align == "C" then
        if width > 0 then
            x_pt = x_pt + (mm_to_pt(width) - text_width_pt) / 2
        else
            x_pt = x_pt - text_width_pt / 2
        end
    elseif align == "R" then
        if width > 0 then
            x_pt = x_pt + mm_to_pt(width) - text_width_pt
        else
            x_pt = x_pt - text_width_pt
        end
    end
    
    -- Build content stream command with explicit color and correct PDF order
    -- Include text color (default black: 0 0 0) using rg operator
    local color_r = self.current_color_fill[1] or 0
    local color_g = self.current_color_fill[2] or 0
    local color_b = self.current_color_fill[3] or 0
    
    local content = string.format("BT\n%.3f %.3f %.3f rg\n%.2f %.2f Td\n/%s %d Tf\n(%s) Tj\nET",
        color_r, color_g, color_b, x_pt, y_pt, font_name, font_size, self:_escape_text(text))
    
    if width > 0 then
        -- Text wrapping would go here
        -- For now, simple text placement
    end
    
    self.current_page:add_content(content)
end

function PDF:_get_font_index(font_key)
    if not self._font_indices then
        self._font_indices = {}
    end
    
    if not self._font_indices[font_key] then
        local next_index = 1
        for _ in pairs(self._font_indices) do
            next_index = next_index + 1
        end
        self._font_indices[font_key] = next_index
    end
    
    return self._font_indices[font_key]
end

function PDF:_estimate_text_width_pt(text, font_size)
    local family = "Helvetica"
    local style = ""
    
    if self.current_font and self.fonts[self.current_font] then
        family = self.fonts[self.current_font].family or family
        style = self.fonts[self.current_font].style or style
    end
    
    local factor = 0.52
    if family == "Times" then
        factor = 0.48
    elseif family == "Courier" then
        factor = 0.60
    end
    
    if style == "B" then
        factor = factor + 0.03
    elseif style == "I" then
        factor = factor + 0.01
    elseif style == "BI" then
        factor = factor + 0.04
    end
    
    return #tostring(text) * font_size * factor
end

function PDF:_estimate_text_ascent_pt(font_size)
    local family = "Helvetica"
    
    if self.current_font and self.fonts[self.current_font] then
        family = self.fonts[self.current_font].family or family
    end
    
    local factor = 0.80
    if family == "Times" then
        factor = 0.72
    elseif family == "Courier" then
        factor = 0.78
    end
    
    return font_size * factor
end

function PDF:_escape_text(text)
    text = text:gsub("\\", "\\\\")
    text = text:gsub("%(", "\\(")
    text = text:gsub("%)", "\\)")
    return text
end

function PDF:_ensure_form_font()
    local font_key = "Helvetica-"
    if not self.fonts[font_key] then
        self.fonts[font_key] = {
            family = "Helvetica",
            style = "",
            base_font = self:_get_base_font_name("Helvetica", "")
        }
    end
    return font_key
end

function PDF:_register_form_field(field)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end

    field.page_index = self.current_page.index
    table.insert(self.forms, field)
    table.insert(self.current_page.annotations, #self.forms)
    return field
end

function PDF:_field_rect(x, y, width, height)
    local x1 = mm_to_pt(x)
    local y1 = self.current_page.height * 2.83464567 - mm_to_pt(y + height)
    local x2 = x1 + mm_to_pt(width)
    local y2 = y1 + mm_to_pt(height)
    return x1, y1, x2, y2
end

function PDF:_build_text_field_flags(options)
    local flags = 0
    if options.read_only then
        flags = flags + 1
    end
    if options.required then
        flags = flags + 2
    end
    if options.multiline then
        flags = flags + 4096
    end
    if options.password then
        flags = flags + 8192
    end
    if options.do_not_spell_check then
        flags = flags + 4194304
    end
    if options.do_not_scroll then
        flags = flags + 8388608
    end
    return flags
end

function PDF:_build_common_field_flags(options)
    local flags = 0
    if options.read_only then
        flags = flags + 1
    end
    if options.required then
        flags = flags + 2
    end
    return flags
end

function PDF:_build_choice_field_flags(options)
    local flags = self:_build_common_field_flags(options)
    if options.combo then
        flags = flags + 131072
    end
    if options.editable then
        flags = flags + 262144
    end
    if options.sort then
        flags = flags + 524288
    end
    if options.multi_select then
        flags = flags + 2097152
    end
    if options.do_not_spell_check then
        flags = flags + 4194304
    end
    if options.commit_on_change then
        flags = flags + 67108864
    end
    return flags
end

function PDF:_pdf_literal(value)
    return "(" .. self:_escape_text(tostring(value or "")) .. ")"
end

function PDF:_pdf_string_array(values)
    local parts = {}
    for i = 1, #values do
        parts[i] = self:_pdf_literal(values[i])
    end
    return "[" .. table.concat(parts, " ") .. "]"
end

function PDF:_build_checkbox_appearance(width_pt, height_pt, checked)
    local inset = math.max(math.min(width_pt, height_pt) * 0.18, 2)
    local stroke = math.max(math.min(width_pt, height_pt) * 0.08, 1)
    local parts = {
        "1 1 1 rg",
        "0 0 0 RG",
        "1 w",
        string.format("0 0 %.2f %.2f re", width_pt, height_pt),
        "B",
    }

    if checked then
        parts[#parts + 1] = "0 0 0 RG"
        parts[#parts + 1] = string.format("%.2f w", stroke)
        parts[#parts + 1] = string.format("%.2f %.2f m", inset, height_pt * 0.45)
        parts[#parts + 1] = string.format("%.2f %.2f l", width_pt * 0.42, inset)
        parts[#parts + 1] = string.format("%.2f %.2f l", width_pt - inset, height_pt - inset)
        parts[#parts + 1] = "S"
    end

    return table.concat(parts, "\n")
end

function PDF:_build_radio_appearance(width_pt, height_pt, checked)
    local radius = math.min(width_pt, height_pt) * 0.5
    local cx = width_pt * 0.5
    local cy = height_pt * 0.5
    local outer = radius - 1
    local inner = math.max(radius * 0.42, 1.5)
    local k_outer = outer * 0.5522847498
    local k_inner = inner * 0.5522847498

    local parts = {
        "1 1 1 rg",
        "0 0 0 RG",
        "1 w",
        string.format("%.2f %.2f m", cx + outer, cy),
        string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx + outer, cy + k_outer, cx + k_outer, cy + outer, cx, cy + outer),
        string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx - k_outer, cy + outer, cx - outer, cy + k_outer, cx - outer, cy),
        string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx - outer, cy - k_outer, cx - k_outer, cy - outer, cx, cy - outer),
        string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx + k_outer, cy - outer, cx + outer, cy - k_outer, cx + outer, cy),
        "B",
    }

    if checked then
        parts[#parts + 1] = "0 0 0 rg"
        parts[#parts + 1] = string.format("%.2f %.2f m", cx + inner, cy)
        parts[#parts + 1] = string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx + inner, cy + k_inner, cx + k_inner, cy + inner, cx, cy + inner)
        parts[#parts + 1] = string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx - k_inner, cy + inner, cx - inner, cy + k_inner, cx - inner, cy)
        parts[#parts + 1] = string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx - inner, cy - k_inner, cx - k_inner, cy - inner, cx, cy - inner)
        parts[#parts + 1] = string.format("%.2f %.2f %.2f %.2f %.2f %.2f c", cx + k_inner, cy - inner, cx + inner, cy - k_inner, cx + inner, cy)
        parts[#parts + 1] = "f"
    end

    return table.concat(parts, "\n")
end

function PDF:form_text(x, y, width, height, name, options)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    if not name or name == "" then
        error("form_text requires a field name.")
    end

    options = options or {}
    self:_ensure_form_font()

    local x1, y1, x2, y2 = self:_field_rect(x, y, width, height)
    local font_size = options.font_size or self.current_font_size or 12
    local value = tostring(options.value or "")
    local border_width = options.border_width or 1
    local align = ({L = 0, C = 1, R = 2})[options.align or "L"] or 0
    local border = options.border_color or {0, 0, 0}
    local background = options.background_color or {1, 1, 1}
    local text_color = options.text_color or self.current_color_fill or {0, 0, 0}

    local br, bg, bb = normalize_rgb(border[1] or 0, border[2] or 0, border[3] or 0)
    local r, g, b = normalize_rgb(background[1] or 1, background[2] or 1, background[3] or 1)
    local tr, tg, tb = normalize_rgb(text_color[1] or 0, text_color[2] or 0, text_color[3] or 0)

    return self:_register_form_field({
        field_type = "text",
        name = tostring(name),
        value = value,
        default_value = tostring(options.default_value or value),
        rect = {x1, y1, x2, y2},
        width_pt = x2 - x1,
        height_pt = y2 - y1,
        font_size = font_size,
        align = align,
        flags = self:_build_text_field_flags(options),
        border_width = border_width,
        border_color = {br, bg, bb},
        background_color = {r, g, b},
        text_color = {tr, tg, tb},
    })
end

function PDF:form_checkbox(x, y, size, name, checked, options)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    if not name or name == "" then
        error("form_checkbox requires a field name.")
    end

    options = options or {}
    local x1, y1, x2, y2 = self:_field_rect(x, y, size, size)

    return self:_register_form_field({
        field_type = "checkbox",
        name = tostring(name),
        checked = checked and true or false,
        rect = {x1, y1, x2, y2},
        width_pt = x2 - x1,
        height_pt = y2 - y1,
        read_only = options.read_only and true or false,
        required = options.required and true or false,
    })
end

function PDF:form_combo(x, y, width, height, name, choices, options)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    if not name or name == "" then
        error("form_combo requires a field name.")
    end
    if type(choices) ~= "table" or #choices == 0 then
        error("form_combo requires a non-empty choices array.")
    end

    options = options or {}
    self:_ensure_form_font()

    local x1, y1, x2, y2 = self:_field_rect(x, y, width, height)
    local font_size = options.font_size or self.current_font_size or 12
    local border_width = options.border_width or 1
    local align = ({L = 0, C = 1, R = 2})[options.align or "L"] or 0
    local value = options.value or choices[1]
    local border = options.border_color or {0, 0, 0}
    local background = options.background_color or {1, 1, 1}
    local text_color = options.text_color or self.current_color_fill or {0, 0, 0}

    local br, bg, bb = normalize_rgb(border[1] or 0, border[2] or 0, border[3] or 0)
    local r, g, b = normalize_rgb(background[1] or 1, background[2] or 1, background[3] or 1)
    local tr, tg, tb = normalize_rgb(text_color[1] or 0, text_color[2] or 0, text_color[3] or 0)

    return self:_register_form_field({
        field_type = "choice",
        name = tostring(name),
        choices = choices,
        value = tostring(value),
        default_value = tostring(options.default_value or value),
        rect = {x1, y1, x2, y2},
        font_size = font_size,
        align = align,
        flags = self:_build_choice_field_flags({
            read_only = options.read_only,
            required = options.required,
            combo = true,
            editable = options.editable,
            sort = options.sort,
            do_not_spell_check = options.do_not_spell_check,
            commit_on_change = options.commit_on_change,
        }),
        border_width = border_width,
        border_color = {br, bg, bb},
        background_color = {r, g, b},
        text_color = {tr, tg, tb},
    })
end

function PDF:form_list(x, y, width, height, name, choices, options)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    if not name or name == "" then
        error("form_list requires a field name.")
    end
    if type(choices) ~= "table" or #choices == 0 then
        error("form_list requires a non-empty choices array.")
    end

    options = options or {}
    self:_ensure_form_font()

    local x1, y1, x2, y2 = self:_field_rect(x, y, width, height)
    local font_size = options.font_size or self.current_font_size or 12
    local border_width = options.border_width or 1
    local align = ({L = 0, C = 1, R = 2})[options.align or "L"] or 0
    local value = options.value
    if value == nil then
        if options.multi_select then
            value = {choices[1]}
        else
            value = choices[1]
        end
    end
    local border = options.border_color or {0, 0, 0}
    local background = options.background_color or {1, 1, 1}
    local text_color = options.text_color or self.current_color_fill or {0, 0, 0}

    local br, bg, bb = normalize_rgb(border[1] or 0, border[2] or 0, border[3] or 0)
    local r, g, b = normalize_rgb(background[1] or 1, background[2] or 1, background[3] or 1)
    local tr, tg, tb = normalize_rgb(text_color[1] or 0, text_color[2] or 0, text_color[3] or 0)

    return self:_register_form_field({
        field_type = "choice",
        name = tostring(name),
        choices = choices,
        value = value,
        default_value = options.default_value or value,
        rect = {x1, y1, x2, y2},
        font_size = font_size,
        align = align,
        flags = self:_build_choice_field_flags({
            read_only = options.read_only,
            required = options.required,
            sort = options.sort,
            multi_select = options.multi_select,
            do_not_spell_check = options.do_not_spell_check,
            commit_on_change = options.commit_on_change,
        }),
        border_width = border_width,
        border_color = {br, bg, bb},
        background_color = {r, g, b},
        text_color = {tr, tg, tb},
        top_index = options.top_index or 0,
    })
end

function PDF:form_signature(x, y, width, height, name, options)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    if not name or name == "" then
        error("form_signature requires a field name.")
    end

    options = options or {}
    local x1, y1, x2, y2 = self:_field_rect(x, y, width, height)
    local border_width = options.border_width or 1
    local border = options.border_color or {0, 0, 0}
    local background = options.background_color or {1, 1, 1}

    local br, bg, bb = normalize_rgb(border[1] or 0, border[2] or 0, border[3] or 0)
    local r, g, b = normalize_rgb(background[1] or 1, background[2] or 1, background[3] or 1)

    return self:_register_form_field({
        field_type = "signature",
        name = tostring(name),
        rect = {x1, y1, x2, y2},
        flags = self:_build_common_field_flags(options),
        border_width = border_width,
        border_color = {br, bg, bb},
        background_color = {r, g, b},
    })
end

function PDF:form_radio(x, y, size, group_name, option_name, checked, options)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    if not group_name or group_name == "" then
        error("form_radio requires a group name.")
    end
    if not option_name or option_name == "" then
        error("form_radio requires an option name.")
    end

    options = options or {}
    local x1, y1, x2, y2 = self:_field_rect(x, y, size, size)

    return self:_register_form_field({
        field_type = "radio",
        name = tostring(group_name),
        option_name = tostring(option_name),
        checked = checked and true or false,
        rect = {x1, y1, x2, y2},
        width_pt = x2 - x1,
        height_pt = y2 - y1,
        read_only = options.read_only and true or false,
        required = options.required and true or false,
        no_toggle_to_off = options.no_toggle_to_off and true or false,
    })
end

function PDF:rect(x, y, width, height, style)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    
    style = style or "S"
    
    local x_pt = mm_to_pt(x)
    local y_pt = self.current_page.height * 2.83464567 - mm_to_pt(y + height)
    local w_pt = mm_to_pt(width)
    local h_pt = mm_to_pt(height)
    
    local content = string.format("%.2f %.2f %.2f %.2f re\n", x_pt, y_pt, w_pt, h_pt)
    
    if style == "F" then
        content = content .. "f"
    elseif style == "S" then
        content = content .. "S"
    elseif style == "DF" then
        content = content .. "B"
    end
    
    self.current_page:add_content(content)
end

function PDF:circle(x, y, radius, style)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    
    style = style or "S"
    
    -- Approximate circle with Bezier curves
    local x_pt = mm_to_pt(x)
    local y_pt = self.current_page.height * 2.83464567 - mm_to_pt(y)
    local r_pt = mm_to_pt(radius)
    
    local k = 0.5522847498  -- Bezier constant for circle approximation
    local kr = k * r_pt
    
    local content = string.format("%.2f %.2f m\n", x_pt + r_pt, y_pt)
    content = content .. string.format("%.2f %.2f %.2f %.2f %.2f %.2f c\n",
        x_pt + r_pt, y_pt + kr, x_pt + kr, y_pt + r_pt, x_pt, y_pt + r_pt)
    content = content .. string.format("%.2f %.2f %.2f %.2f %.2f %.2f c\n",
        x_pt - kr, y_pt + r_pt, x_pt - r_pt, y_pt + kr, x_pt - r_pt, y_pt)
    content = content .. string.format("%.2f %.2f %.2f %.2f %.2f %.2f c\n",
        x_pt - r_pt, y_pt - kr, x_pt - kr, y_pt - r_pt, x_pt, y_pt - r_pt)
    content = content .. string.format("%.2f %.2f %.2f %.2f %.2f %.2f c\n",
        x_pt + kr, y_pt - r_pt, x_pt + r_pt, y_pt - kr, x_pt + r_pt, y_pt)
    
    if style == "F" then
        content = content .. "f"
    elseif style == "S" then
        content = content .. "S"
    elseif style == "DF" then
        content = content .. "B"
    end
    
    self.current_page:add_content(content)
end

function PDF:line(x1, y1, x2, y2)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end
    
    local x1_pt = mm_to_pt(x1)
    local y1_pt = self.current_page.height * 2.83464567 - mm_to_pt(y1)
    local x2_pt = mm_to_pt(x2)
    local y2_pt = self.current_page.height * 2.83464567 - mm_to_pt(y2)
    
    local content = string.format("%.2f %.2f m\n%.2f %.2f l\nS",
        x1_pt, y1_pt, x2_pt, y2_pt)
    
    self.current_page:add_content(content)
end

function PDF:_decode_png_image_data(data, cache_key)
    if cache_key and self.image_cache[cache_key] then
        return self.image_cache[cache_key]
    end

    local png = parse_png(data)
    local rgb_data, alpha_data = decode_png_pixels(png)
    local image = {
        name = "Im" .. (#self.images + 1),
        width = png.width,
        height = png.height,
        data = rgb_data,
        alpha_data = alpha_data,
        color_space = "/DeviceRGB",
        bits_per_component = 8,
        path = cache_key,
    }

    self.images[#self.images + 1] = image
    if cache_key then
        self.image_cache[cache_key] = image
    end
    return image
end

function PDF:_load_png_image(path)
    if self.image_cache[path] then
        return self.image_cache[path]
    end

    local file = io.open(path, "rb")
    if not file then
        error("Could not open PNG file: " .. path)
    end
    local data = file:read("*all")
    file:close()

    return self:_decode_png_image_data(data, path)
end

function PDF:image_png(path, x, y, width, height)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end

    local image = self:_load_png_image(path)
    local default_mm_per_pixel = 25.4 / 72
    width = width or (image.width * default_mm_per_pixel)
    height = height or (image.height * default_mm_per_pixel)

    local x_pt = mm_to_pt(x)
    local y_pt = self.current_page.height * 2.83464567 - mm_to_pt(y + height)
    local width_pt = mm_to_pt(width)
    local height_pt = mm_to_pt(height)

    self.current_page.resources.XObject[image.name] = true
    self.current_page:add_content(string.format(
        "q\n%.2f 0 0 %.2f %.2f %.2f cm\n/%s Do\nQ",
        width_pt, height_pt, x_pt, y_pt, image.name
    ))
end

function PDF:image_png_data(data, x, y, width, height, cache_key)
    if not self.current_page then
        error("No page added. Call add_page first.")
    end

    local image = self:_decode_png_image_data(data, cache_key)
    local default_mm_per_pixel = 25.4 / 72
    width = width or (image.width * default_mm_per_pixel)
    height = height or (image.height * default_mm_per_pixel)

    local x_pt = mm_to_pt(x)
    local y_pt = self.current_page.height * 2.83464567 - mm_to_pt(y + height)
    local width_pt = mm_to_pt(width)
    local height_pt = mm_to_pt(height)

    self.current_page.resources.XObject[image.name] = true
    self.current_page:add_content(string.format(
        "q\n%.2f 0 0 %.2f %.2f %.2f cm\n/%s Do\nQ",
        width_pt, height_pt, x_pt, y_pt, image.name
    ))
end

function PDF:set_color_fill(r, g, b, a)
    a = a or 1
    
    -- Normalize if values are 0-255
    r, g, b = normalize_rgb(r, g, b)
    
    self.current_color_fill = {r, g, b, a}
    
    if self.current_page then
        local content = string.format("%.3f %.3f %.3f rg", r, g, b)
        self.current_page:add_content(content)
    end
end

function PDF:set_color_stroke(r, g, b, a)
    a = a or 1
    
    -- Normalize if values are 0-255
    r, g, b = normalize_rgb(r, g, b)
    
    self.current_color_stroke = {r, g, b, a}
    
    if self.current_page then
        local content = string.format("%.3f %.3f %.3f RG", r, g, b)
        self.current_page:add_content(content)
    end
end

function PDF:set_line_width(width)
    self.current_line_width = width
    
    if self.current_page then
        local content = string.format("%.2f w", mm_to_pt(width))
        self.current_page:add_content(content)
    end
end

function PDF:save(filename)
    local file = io.open(filename, "wb")
    if not file then
        error("Could not open file: " .. filename)
    end
    
    -- Build PDF structure
    local objects = {}
    local object_offsets = {}
    
    -- Objects 3+: Font objects, page objects, form fields, and content streams
    local obj_num = 3
    local font_refs = {}
    local image_refs = {}
    local smask_refs = {}
    
    for font_key, font_data in pairs(self.fonts) do
        font_refs[font_key] = obj_num
        objects[obj_num] = "<</Type /Font /Subtype /Type1 /BaseFont /" .. font_data.base_font .. ">>"
        obj_num = obj_num + 1
    end

    for _, image in ipairs(self.images) do
        if image.alpha_data then
            smask_refs[image.name] = obj_num
            local smask_stream = "stream\n" .. image.alpha_data .. "\nendstream"
            objects[obj_num] = "<</Type /XObject /Subtype /Image /Width " .. image.width ..
                               " /Height " .. image.height ..
                               " /ColorSpace /DeviceGray /BitsPerComponent 8 /Length " ..
                               #image.alpha_data .. ">>\n" .. smask_stream
            obj_num = obj_num + 1
        end

        image_refs[image.name] = obj_num
        local smask_part = smask_refs[image.name] and (" /SMask " .. smask_refs[image.name] .. " 0 R") or ""
        local image_stream = "stream\n" .. image.data .. "\nendstream"
        objects[obj_num] = "<</Type /XObject /Subtype /Image /Width " .. image.width ..
                           " /Height " .. image.height ..
                           " /ColorSpace " .. image.color_space ..
                           " /BitsPerComponent " .. image.bits_per_component ..
                           smask_part .. " /Length " .. #image.data .. ">>\n" .. image_stream
        obj_num = obj_num + 1
    end
    
    -- Reserve page object numbers so /Pages /Kids points at the actual page objects
    local page_refs = {}
    for page_idx = 1, #self.pages do
        page_refs[page_idx] = obj_num
        obj_num = obj_num + 2
    end

    local acroform_ref
    local field_refs = {}
    local checkbox_appearance_refs = {}
    local radio_group_refs = {}
    local radio_group_order = {}
    local radio_appearance_refs = {}
    if #self.forms > 0 then
        self:_ensure_form_font()
        acroform_ref = obj_num
        obj_num = obj_num + 1
        for field_idx, field in ipairs(self.forms) do
            if field.field_type == "radio" then
                local group = radio_group_refs[field.name]
                if not group then
                    group = {
                        parent_ref = obj_num,
                        widgets = {},
                        selected = nil,
                        flags = 32768 + self:_build_common_field_flags(field) + (field.no_toggle_to_off and 16384 or 0),
                    }
                    radio_group_refs[field.name] = group
                    radio_group_order[#radio_group_order + 1] = field.name
                    obj_num = obj_num + 1
                elseif field.checked then
                    group.selected = field.option_name
                end
                if field.checked and not group.selected then
                    group.selected = field.option_name
                end

                field_refs[field_idx] = obj_num
                group.widgets[#group.widgets + 1] = field_idx
                obj_num = obj_num + 1
                radio_appearance_refs[field_idx] = {
                    off = obj_num,
                    yes = obj_num + 1,
                }
                obj_num = obj_num + 2
            else
                field_refs[field_idx] = obj_num
                obj_num = obj_num + 1
            end
            if field.field_type == "checkbox" then
                checkbox_appearance_refs[field_idx] = {
                    off = obj_num,
                    yes = obj_num + 1,
                }
                obj_num = obj_num + 2
            end
        end
    end

    -- Object 1: Catalog
    local catalog = "<</Type /Catalog /Pages 2 0 R"
    if acroform_ref then
        catalog = catalog .. " /AcroForm " .. acroform_ref .. " 0 R"
    end
    objects[1] = catalog .. ">>"
    
    -- Object 2: Pages
    local kids = "["
    for page_idx = 1, #page_refs do
        kids = kids .. page_refs[page_idx] .. " 0 R "
    end
    kids = kids .. "]"
    objects[2] = "<</Type /Pages /Kids " .. kids .. " /Count " .. #self.pages .. ">>"
    
    -- Create page objects and content streams
    for page_idx, page in ipairs(self.pages) do
        local page_obj_num = page_refs[page_idx]
        local content_obj_num = page_obj_num + 1
        local page_width = mm_to_pt(page.width)
        local page_height = mm_to_pt(page.height)
        
        -- Resource dictionary
        local font_dict = "<</Font <<"
        for font_key, _ in pairs(self.fonts) do
            local font_index = self:_get_font_index(font_key)
            font_dict = font_dict .. "/F" .. font_index .. " " .. font_refs[font_key] .. " 0 R "
        end
        font_dict = font_dict .. ">>"
        if next(page.resources.XObject) then
            font_dict = font_dict .. " /XObject <<"
            for image_name, _ in pairs(page.resources.XObject) do
                if image_refs[image_name] then
                    font_dict = font_dict .. "/" .. image_name .. " " .. image_refs[image_name] .. " 0 R "
                end
            end
            font_dict = font_dict .. ">>"
        end
        font_dict = font_dict .. ">>"

        local annots_part = ""
        if #page.annotations > 0 then
            local annot_refs = {}
            for _, field_idx in ipairs(page.annotations) do
                annot_refs[#annot_refs + 1] = field_refs[field_idx] .. " 0 R"
            end
            annots_part = " /Annots [" .. table.concat(annot_refs, " ") .. "]"
        end
        
        -- Page object
        local page_obj = "<</Type /Page /Parent 2 0 R /MediaBox [0 0 " .. 
                         page_width .. " " .. page_height .. "] /Resources " .. font_dict ..
                         annots_part .. " /Contents " .. content_obj_num .. " 0 R>>"
        objects[page_obj_num] = page_obj
        
        -- Content stream object
        local stream_data = page:get_content_stream()
        local stream_obj = "stream\n" .. stream_data .. "\nendstream"
        objects[content_obj_num] = "<</Length " .. #stream_data .. ">>\n" .. stream_obj
    end

    if acroform_ref then
        local field_list = {}
        for _, group_name in ipairs(radio_group_order) do
            field_list[#field_list + 1] = radio_group_refs[group_name].parent_ref .. " 0 R"
        end
        for field_idx = 1, #self.forms do
            if self.forms[field_idx].field_type ~= "radio" then
                field_list[#field_list + 1] = field_refs[field_idx] .. " 0 R"
            end
        end
        local form_font_ref = font_refs[self:_ensure_form_font()]
        objects[acroform_ref] = "<</Fields [" .. table.concat(field_list, " ") ..
            "] /NeedAppearances true /DR <</Font <</Helv " .. form_font_ref ..
            " 0 R>>>> /DA (/Helv 12 Tf 0 g)>>"

        for _, group_name in ipairs(radio_group_order) do
            local group = radio_group_refs[group_name]
            local kid_refs = {}
            for _, field_idx in ipairs(group.widgets) do
                kid_refs[#kid_refs + 1] = field_refs[field_idx] .. " 0 R"
            end
            local value_part = group.selected and (" /V /" .. group.selected) or ""
            objects[group.parent_ref] = string.format(
                "<</FT /Btn /T (%s) /Ff %d%s /Kids [%s]>>",
                self:_escape_text(group_name),
                group.flags,
                value_part,
                table.concat(kid_refs, " ")
            )
        end

        for field_idx, field in ipairs(self.forms) do
            local rect = string.format("[%.2f %.2f %.2f %.2f]",
                field.rect[1], field.rect[2], field.rect[3], field.rect[4])

            if field.field_type == "text" then
                local da = string.format("/Helv %d Tf %.3f %.3f %.3f rg",
                    field.font_size,
                    field.text_color[1],
                    field.text_color[2],
                    field.text_color[3])
                objects[field_refs[field_idx]] = string.format(
                    "<</Type /Annot /Subtype /Widget /FT /Tx /T (%s) /Rect %s /P %d 0 R /F 4 /DA (%s) /Q %d /V (%s) /DV (%s) /MK <</BC [%.3f %.3f %.3f] /BG [%.3f %.3f %.3f]>> /BS <</W %.2f /S /S>> /Ff %d>>",
                    self:_escape_text(field.name),
                    rect,
                    page_refs[field.page_index],
                    da,
                    field.align,
                    self:_escape_text(field.value),
                    self:_escape_text(field.default_value),
                    field.border_color[1], field.border_color[2], field.border_color[3],
                    field.background_color[1], field.background_color[2], field.background_color[3],
                    field.border_width,
                    field.flags
                )
            elseif field.field_type == "checkbox" then
                local appearance_refs = checkbox_appearance_refs[field_idx]
                local flags = self:_build_common_field_flags(field)
                local state_name = field.checked and "/Yes" or "/Off"

                objects[appearance_refs.off] = string.format(
                    "<</Type /XObject /Subtype /Form /BBox [0 0 %.2f %.2f] /Resources <<>> /Length %d>>\nstream\n%s\nendstream",
                    field.width_pt,
                    field.height_pt,
                    #self:_build_checkbox_appearance(field.width_pt, field.height_pt, false),
                    self:_build_checkbox_appearance(field.width_pt, field.height_pt, false)
                )
                objects[appearance_refs.yes] = string.format(
                    "<</Type /XObject /Subtype /Form /BBox [0 0 %.2f %.2f] /Resources <<>> /Length %d>>\nstream\n%s\nendstream",
                    field.width_pt,
                    field.height_pt,
                    #self:_build_checkbox_appearance(field.width_pt, field.height_pt, true),
                    self:_build_checkbox_appearance(field.width_pt, field.height_pt, true)
                )

                objects[field_refs[field_idx]] = string.format(
                    "<</Type /Annot /Subtype /Widget /FT /Btn /T (%s) /Rect %s /P %d 0 R /F 4 /V %s /AS %s /AP <</N <</Off %d 0 R /Yes %d 0 R>>>> /MK <</BC [0 0 0] /BG [1 1 1] /CA (4)>> /BS <</W 1 /S /S>> /Ff %d>>",
                    self:_escape_text(field.name),
                    rect,
                    page_refs[field.page_index],
                    state_name,
                    state_name,
                    appearance_refs.off,
                    appearance_refs.yes,
                    flags
                )
            elseif field.field_type == "choice" then
                local da = string.format("/Helv %d Tf %.3f %.3f %.3f rg",
                    field.font_size,
                    field.text_color[1],
                    field.text_color[2],
                    field.text_color[3])
                local choice_opts = self:_pdf_string_array(field.choices)
                local value_literal
                local default_literal
                if type(field.value) == "table" then
                    value_literal = self:_pdf_string_array(field.value)
                else
                    value_literal = self:_pdf_literal(field.value)
                end
                if type(field.default_value) == "table" then
                    default_literal = self:_pdf_string_array(field.default_value)
                else
                    default_literal = self:_pdf_literal(field.default_value)
                end
                objects[field_refs[field_idx]] = string.format(
                    "<</Type /Annot /Subtype /Widget /FT /Ch /T (%s) /Rect %s /P %d 0 R /F 4 /DA (%s) /Q %d /Opt %s /V %s /DV %s /MK <</BC [%.3f %.3f %.3f] /BG [%.3f %.3f %.3f]>> /BS <</W %.2f /S /S>> /TI %d /Ff %d>>",
                    self:_escape_text(field.name),
                    rect,
                    page_refs[field.page_index],
                    da,
                    field.align,
                    choice_opts,
                    value_literal,
                    default_literal,
                    field.border_color[1], field.border_color[2], field.border_color[3],
                    field.background_color[1], field.background_color[2], field.background_color[3],
                    field.border_width,
                    field.top_index or 0,
                    field.flags
                )
            elseif field.field_type == "signature" then
                objects[field_refs[field_idx]] = string.format(
                    "<</Type /Annot /Subtype /Widget /FT /Sig /T (%s) /Rect %s /P %d 0 R /F 4 /MK <</BC [%.3f %.3f %.3f] /BG [%.3f %.3f %.3f]>> /BS <</W %.2f /S /S>> /Ff %d>>",
                    self:_escape_text(field.name),
                    rect,
                    page_refs[field.page_index],
                    field.border_color[1], field.border_color[2], field.border_color[3],
                    field.background_color[1], field.background_color[2], field.background_color[3],
                    field.border_width,
                    field.flags
                )
            elseif field.field_type == "radio" then
                local appearance_refs = radio_appearance_refs[field_idx]
                local group = radio_group_refs[field.name]
                local on_state = "/" .. field.option_name
                local state_name = field.checked and on_state or "/Off"
                local off_stream = self:_build_radio_appearance(field.width_pt, field.height_pt, false)
                local on_stream = self:_build_radio_appearance(field.width_pt, field.height_pt, true)

                objects[appearance_refs.off] = string.format(
                    "<</Type /XObject /Subtype /Form /BBox [0 0 %.2f %.2f] /Resources <<>> /Length %d>>\nstream\n%s\nendstream",
                    field.width_pt,
                    field.height_pt,
                    #off_stream,
                    off_stream
                )
                objects[appearance_refs.yes] = string.format(
                    "<</Type /XObject /Subtype /Form /BBox [0 0 %.2f %.2f] /Resources <<>> /Length %d>>\nstream\n%s\nendstream",
                    field.width_pt,
                    field.height_pt,
                    #on_stream,
                    on_stream
                )

                objects[field_refs[field_idx]] = string.format(
                    "<</Type /Annot /Subtype /Widget /Parent %d 0 R /Rect %s /P %d 0 R /F 4 /AS %s /AP <</N <</Off %d 0 R %s %d 0 R>>>> /MK <</BC [0 0 0] /BG [1 1 1]>> /BS <</W 1 /S /S>>>>",
                    group.parent_ref,
                    rect,
                    page_refs[field.page_index],
                    state_name,
                    appearance_refs.off,
                    on_state,
                    appearance_refs.yes
                )
            end
        end
    end
    
    -- Info object
    objects[obj_num] = "<</Title (" .. self:_escape_text(self.title) .. ") /Author (" .. 
                       self:_escape_text(self.author) .. ") /Subject (" .. 
                       self:_escape_text(self.subject) .. ") /CreationDate (" .. 
                       self.created .. ")>>"
    local info_obj = obj_num
    
    -- Write PDF
    file:write("%PDF-1.4\n")
    
    local offset = #"%PDF-1.4\n"
    
    -- Write objects
    for i = 1, info_obj do
        object_offsets[i] = offset
        
        local obj_content = i .. " 0 obj\n" .. objects[i] .. "\nendobj\n"
        file:write(obj_content)
        offset = offset + #obj_content
    end
    
    -- Write xref
    local xref_offset = offset
    file:write("xref\n")
    file:write("0 " .. (info_obj + 1) .. "\n")
    file:write("0000000000 65535 f \n")
    
    for i = 1, info_obj do
        file:write(string.format("%010d 00000 n \n", object_offsets[i]))
    end
    
    -- Write trailer
    file:write("trailer\n")
    file:write("<</Size " .. (info_obj + 1) .. " /Root 1 0 R /Info " .. info_obj .. " 0 R>>\n")
    file:write("startxref\n")
    file:write(xref_offset .. "\n")
    file:write("%%EOF\n")
    
    file:close()
end

-- Utility helpers exposed from the main module so a single require("pdf") is enough.
function Utils.mm_to_pt(mm)
    return mm_to_pt(mm)
end

function Utils.pt_to_mm(pt)
    return pt / 2.83464567
end

function Utils.in_to_mm(inches)
    return inches * 25.4
end

function Utils.mm_to_in(mm)
    return mm / 25.4
end

Utils.PaperSizes = {
    A0 = {width = 841, height = 1189},
    A1 = {width = 594, height = 841},
    A2 = {width = 420, height = 594},
    A3 = {width = 297, height = 420},
    A4 = {width = 210, height = 297},
    A5 = {width = 148, height = 210},
    A6 = {width = 105, height = 148},
    Letter = {width = 215.9, height = 279.4},
    Legal = {width = 215.9, height = 355.6},
    Tabloid = {width = 279.4, height = 431.8},
}

Utils.Colors = {
    black = {0, 0, 0},
    white = {255, 255, 255},
    red = {255, 0, 0},
    green = {0, 128, 0},
    blue = {0, 0, 255},
    yellow = {255, 255, 0},
    cyan = {0, 255, 255},
    magenta = {255, 0, 255},
    gray = {128, 128, 128},
    darkgray = {64, 64, 64},
    lightgray = {192, 192, 192},
    orange = {255, 165, 0},
    purple = {128, 0, 128},
    brown = {165, 42, 42},
}

Utils.StandardFonts = {
    "Helvetica",
    "Helvetica-Bold",
    "Helvetica-Oblique",
    "Helvetica-BoldOblique",
    "Times-Roman",
    "Times-Bold",
    "Times-Italic",
    "Times-BoldItalic",
    "Courier",
    "Courier-Bold",
    "Courier-Oblique",
    "Courier-BoldOblique",
}

function Utils.escape_pdf_text(text)
    text = tostring(text)
    text = text:gsub("\\", "\\\\")
    text = text:gsub("%(", "\\(")
    text = text:gsub("%)", "\\)")
    return text
end

function Utils.unescape_pdf_text(text)
    text = tostring(text)
    text = text:gsub("\\%)", ")")
    text = text:gsub("\\%(", "(")
    text = text:gsub("\\\\", "\\")
    return text
end

function Utils.split_text(text, delimiter)
    delimiter = delimiter or "\n"
    local lines = {}
    for line in tostring(text):gmatch("[^" .. delimiter .. "]+") do
        table.insert(lines, line)
    end
    return lines
end

function Utils.estimate_text_width(text, font_size)
    font_size = font_size or 12
    return #tostring(text) * 0.5 * font_size
end

function Utils.rgb_to_hex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

function Utils.hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return r, g, b
end

function Utils.hsv_to_rgb(h, s, v)
    local c = v * s
    local hp = h / 60
    local x = c * (1 - math.abs(hp % 2 - 1))

    local r, g, b = 0, 0, 0
    if hp < 1 then
        r, g = c, x
    elseif hp < 2 then
        r, g = x, c
    elseif hp < 3 then
        g, b = c, x
    elseif hp < 4 then
        g, b = x, c
    elseif hp < 5 then
        r, b = x, c
    else
        r, b = c, x
    end

    local m = v - c
    return (r + m) * 255, (g + m) * 255, (b + m) * 255
end

function Utils.rgb_to_hsv(r, g, b)
    r = r / 255
    g = g / 255
    b = b / 255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    local h = 0
    if delta > 0 then
        if max == r then
            h = 60 * (((g - b) / delta) % 6)
        elseif max == g then
            h = 60 * (((b - r) / delta) + 2)
        else
            h = 60 * (((r - g) / delta) + 4)
        end
    end

    local s = max > 0 and (delta / max) or 0
    local v = max
    return h, s, v
end

function Utils.color_gradient(color1, color2, steps)
    steps = steps or 10
    local gradient = {}
    for i = 0, steps - 1 do
        local t = i / (steps - 1)
        table.insert(gradient, {
            color1[1] + (color2[1] - color1[1]) * t,
            color1[2] + (color2[2] - color1[2]) * t,
            color1[3] + (color2[3] - color1[3]) * t,
        })
    end
    return gradient
end

function Utils.format_number(num, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f", num)
end

function Utils.get_pdf_timestamp()
    return os.date("D:%Y%m%d%H%M%S")
end

function Utils.degrees_to_radians(degrees)
    return degrees * math.pi / 180
end

function Utils.radians_to_degrees(radians)
    return radians * 180 / math.pi
end

function Helper.add_header(doc, title, subtitle)
    doc:set_color_fill(44, 62, 80)
    doc:rect(0, 0, doc.current_page.width, 30, "F")

    doc:set_font("Helvetica", "B", 18)
    doc:set_color_fill(255, 255, 255)
    doc:text(10, 5, title)

    if subtitle then
        doc:set_font("Helvetica", "", 11)
        doc:set_color_fill(189, 195, 199)
        doc:text(10, 18, subtitle)
    end

    return 35
end

function Helper.add_footer(doc, show_date)
    show_date = show_date ~= false

    doc:set_color_fill(44, 62, 80)
    doc:rect(0, doc.current_page.height - 15, doc.current_page.width, 15, "F")

    doc:set_font("Helvetica", "", 9)
    doc:set_color_fill(255, 255, 255)
    doc:text(10, doc.current_page.height - 10, "Page " .. #doc.pages, nil, "L")

    if show_date then
        doc:text(doc.current_page.width - 10, doc.current_page.height - 10, os.date("%Y-%m-%d"), nil, "R")
    end
end

function Helper.section_header(doc, text, y)
    doc:set_color_fill(52, 152, 219)
    doc:rect(10, y, doc.current_page.width - 20, 0.5, "F")

    doc:set_font("Helvetica", "B", 14)
    doc:set_color_fill(44, 62, 80)
    doc:text(10, y - 8, text)

    return y + 10
end

function Helper.highlight_box(doc, x, y, width, height, text, bgcolor, textcolor)
    bgcolor = bgcolor or {236, 240, 241}
    textcolor = textcolor or {0, 0, 0}

    doc:set_color_fill(bgcolor[1], bgcolor[2], bgcolor[3])
    doc:rect(x, y, width, height, "F")

    doc:set_color_fill(textcolor[1], textcolor[2], textcolor[3])
    doc:set_font("Helvetica", "", 10)
    doc:text(x + 5, y + 5, text)
end

function Helper.box(doc, x, y, width, height, border_color, border_width)
    border_color = border_color or {0, 0, 0}
    border_width = border_width or 0.5

    doc:set_color_stroke(border_color[1], border_color[2], border_color[3])
    doc:set_line_width(border_width)
    doc:rect(x, y, width, height, "S")
end

function Helper.title_page(doc, title, subtitle, content_lines)
    local page_width = 210
    local page_height = 297

    if #doc.pages > 0 then
        page_width = doc.pages[1].width
        page_height = doc.pages[1].height
    end

    doc:add_page(page_width, page_height)
    doc:set_color_fill(44, 62, 80)
    doc:rect(0, 0, doc.current_page.width, doc.current_page.height, "F")

    doc:set_font("Helvetica", "B", 48)
    doc:set_color_fill(255, 255, 255)
    doc:text(10, 80, title)

    if subtitle then
        doc:set_font("Helvetica", "I", 24)
        doc:set_color_fill(189, 195, 199)
        doc:text(10, 130, subtitle)
    end

    doc:set_color_stroke(52, 152, 219)
    doc:set_line_width(2)
    doc:line(10, 150, doc.current_page.width - 10, 150)

    if content_lines then
        doc:set_font("Helvetica", "", 14)
        doc:set_color_fill(255, 255, 255)
        local y = 170
        for _, line in ipairs(content_lines) do
            doc:text(10, y, line)
            y = y + 20
        end
    end
end

function Helper.page_break(doc, page_width, page_height, with_header)
    doc:add_page(page_width, page_height)
    if with_header then
        return Helper.add_header(doc, with_header.title, with_header.subtitle)
    end
    return 10
end

function Helper.two_column_layout(doc, left_title, left_content, right_title, right_content, y)
    local col_width = (doc.current_page.width - 30) / 2
    local col_x1 = 10
    local col_x2 = 10 + col_width + 10

    doc:set_font("Helvetica", "B", 12)
    doc:set_color_fill(52, 152, 219)
    doc:text(col_x1, y, left_title)
    doc:text(col_x2, y, right_title)

    doc:set_font("Helvetica", "", 10)
    doc:set_color_fill(0, 0, 0)

    local left_y = y + 15
    for _, line in ipairs(left_content) do
        doc:text(col_x1 + 2, left_y, line, col_width - 4)
        left_y = left_y + 8
    end

    local right_y = y + 15
    for _, line in ipairs(right_content) do
        doc:text(col_x2 + 2, right_y, line, col_width - 4)
        right_y = right_y + 8
    end

    return math.max(left_y, right_y) + 10
end

function Helper.watermark(doc, text, opacity)
    opacity = opacity or 0.1
    doc:set_color_fill(200, 200, 200, opacity)
    doc:set_font("Helvetica", "B", 80)
    doc:text(doc.current_page.width / 2 - 50, doc.current_page.height / 2 - 30, text)
end

function Helper.checklist_item(doc, x, y, text, checked)
    local box_size = 4
    doc:set_color_stroke(0, 0, 0)
    doc:set_line_width(0.3)
    doc:rect(x, y, box_size, box_size, "S")

    if checked then
        doc:set_color_stroke(0, 128, 0)
        doc:line(x + 1, y + 2, x + 2, y + 3)
        doc:line(x + 2, y + 3, x + 3.5, y + 1)
    end

    doc:set_color_fill(0, 0, 0)
    doc:set_font("Helvetica", "", 10)
    doc:text(x + 8, y + 0.5, text)
end

function Helper.progress_bar(doc, x, y, width, height, percentage, color)
    color = color or {52, 152, 219}
    doc:set_color_fill(200, 200, 200)
    doc:rect(x, y, width, height, "F")

    local filled_width = (width * percentage) / 100
    doc:set_color_fill(color[1], color[2], color[3])
    doc:rect(x, y, filled_width, height, "F")

    doc:set_color_stroke(0, 0, 0)
    doc:set_line_width(0.3)
    doc:rect(x, y, width, height, "S")

    doc:set_font("Helvetica", "B", 9)
    doc:set_color_fill(0, 0, 0)
    doc:text(x + width + 5, y - 1, percentage .. "%")
end

function PDF:add_header(title, subtitle)
    return Helper.add_header(self, title, subtitle)
end

function PDF:add_footer(show_date)
    return Helper.add_footer(self, show_date)
end

function PDF:section_header(text, y)
    return Helper.section_header(self, text, y)
end

function PDF:highlight_box(x, y, width, height, text, bgcolor, textcolor)
    return Helper.highlight_box(self, x, y, width, height, text, bgcolor, textcolor)
end

function PDF:box(x, y, width, height, border_color, border_width)
    return Helper.box(self, x, y, width, height, border_color, border_width)
end

function PDF:title_page(title, subtitle, content_lines)
    return Helper.title_page(self, title, subtitle, content_lines)
end

function PDF:page_break(page_width, page_height, with_header)
    return Helper.page_break(self, page_width, page_height, with_header)
end

function PDF:two_column_layout(left_title, left_content, right_title, right_content, y)
    return Helper.two_column_layout(self, left_title, left_content, right_title, right_content, y)
end

function PDF:watermark(text, opacity)
    return Helper.watermark(self, text, opacity)
end

function PDF:checklist_item(x, y, text, checked)
    return Helper.checklist_item(self, x, y, text, checked)
end

function PDF:progress_bar(x, y, width, height, percentage, color)
    return Helper.progress_bar(self, x, y, width, height, percentage, color)
end

QuickRef.BasicOperations = {
    create_document = function()
        return PDF.new()
    end,
    add_page = function(doc)
        doc:add_page(210, 297)
    end,
    save_document = function(doc, filename)
        doc:save(filename or "output.pdf")
    end,
}

QuickRef.TextOperations = {
    regular_text = [[
        doc:set_font("Helvetica", "", 12)
        doc:text(10, 10, "Hello World")
    ]],
    bold_text = [[
        doc:set_font("Helvetica", "B", 12)
        doc:text(10, 10, "Bold Text")
    ]],
    italic_text = [[
        doc:set_font("Helvetica", "I", 12)
        doc:text(10, 10, "Italic Text")
    ]],
    different_fonts = [[
        doc:set_font("Times", "", 12)
        doc:text(10, 10, "Times font")

        doc:set_font("Courier", "", 12)
        doc:text(10, 25, "Courier font")
    ]],
    centered_text = [[
        doc:set_font("Helvetica", "", 12)
        doc:text(100, 50, "Centered", nil, "C")
    ]],
    right_aligned_text = [[
        doc:set_font("Helvetica", "", 12)
        doc:text(200, 50, "Right aligned", nil, "R")
    ]],
}

QuickRef.ColorOperations = {
    fill_color_255 = [[
        doc:set_color_fill(255, 0, 0)
    ]],
    fill_color_normalized = [[
        doc:set_color_fill(1, 0, 0)
    ]],
    stroke_color = [[
        doc:set_color_stroke(0, 0, 0)
    ]],
    transparency = [[
        doc:set_color_fill(255, 0, 0, 0.5)
    ]],
    using_color_presets = [[
        doc:set_color_fill(
            PDF.Utils.Colors.blue[1],
            PDF.Utils.Colors.blue[2],
            PDF.Utils.Colors.blue[3]
        )
    ]],
}

QuickRef.ShapeOperations = {
    rectangle_filled = [[
        doc:set_color_fill(100, 150, 200)
        doc:rect(10, 10, 50, 30, "F")
    ]],
    rectangle_outline = [[
        doc:set_color_stroke(0, 0, 0)
        doc:rect(10, 10, 50, 30, "S")
    ]],
    rectangle_filled_and_outline = [[
        doc:rect(10, 10, 50, 30, "DF")
    ]],
    circle_filled = [[
        doc:set_color_fill(255, 0, 0)
        doc:circle(50, 50, 10, "F")
    ]],
    circle_outline = [[
        doc:set_color_stroke(0, 0, 0)
        doc:circle(50, 50, 10, "S")
    ]],
    line = [[
        doc:set_color_stroke(0, 0, 0)
        doc:set_line_width(0.5)
        doc:line(10, 10, 100, 100)
    ]],
    thick_line = [[
        doc:set_line_width(2)
        doc:line(10, 10, 100, 100)
    ]],
}

QuickRef.LayoutTips = {
    a4_dimensions = "210mm × 297mm",
    letter_dimensions = "215.9mm × 279.4mm",
    top_margin = 10,
    bottom_margin = 10,
    left_margin = 10,
    right_margin = 10,
    available_width = 190,
    available_height = 277,
    center_x = 105,
    center_y = 148,
}

QuickRef.MultiPageExample = [[
    local doc = PDF.new()
    doc:add_page(210, 297)
    doc:set_font("Helvetica", "B", 24)
    doc:text(10, 10, "Page 1")
    doc:add_page(210, 297)
    doc:set_font("Helvetica", "B", 24)
    doc:text(10, 10, "Page 2")
    doc:add_page(210, 297)
    doc:set_font("Helvetica", "B", 24)
    doc:text(10, 10, "Page 3")
    doc:save("multipage.pdf")
]]

QuickRef.HelperFunctions = {
    add_header = [[
        local y = PDF.Helper.add_header(doc, "Title", "Subtitle")
    ]],
    add_footer = [[
        PDF.Helper.add_footer(doc, true)
    ]],
    section_header = [[
        local y = PDF.Helper.section_header(doc, "Section Title", y)
    ]],
    progress_bar = [[
        PDF.Helper.progress_bar(doc, x, y, width, height, percentage, color)
    ]],
    checklist_item = [[
        PDF.Helper.checklist_item(doc, x, y, "Task description", true)
    ]],
    title_page = [[
        PDF.Helper.title_page(doc, "Title", "Subtitle", {"Line 1", "Line 2"})
    ]],
}

QuickRef.UtilityFunctions = {
    unit_conversion = [[
        local pt = PDF.Utils.mm_to_pt(10)
        local mm = PDF.Utils.pt_to_mm(28.35)
    ]],
    color_conversion = [[
        local hex = PDF.Utils.rgb_to_hex(255, 0, 0)
        local r, g, b = PDF.Utils.hex_to_rgb("#FF0000")
    ]],
    get_paper_size = [[
        local a4 = PDF.Utils.PaperSizes.A4
        local letter = PDF.Utils.PaperSizes.Letter
    ]],
    color_gradient = [[
        local gradient = PDF.Utils.color_gradient(color1, color2, num_steps)
    ]],
}

QuickRef.Fonts = {
    families = {"Helvetica", "Times", "Courier"},
    styles = {"", "B", "I", "BI"},
    examples = [[
        doc:set_font("Helvetica", "", 12)
        doc:set_font("Helvetica", "B", 12)
        doc:set_font("Helvetica", "I", 12)
        doc:set_font("Times", "", 12)
        doc:set_font("Times", "B", 12)
        doc:set_font("Courier", "", 12)
        doc:set_font("Courier", "B", 12)
    ]],
}

QuickRef.CommonPatterns = {
    report_header = [[
        doc:set_color_fill(44, 62, 80)
        doc:rect(0, 0, 210, 30, "F")
        doc:set_font("Helvetica", "B", 20)
        doc:set_color_fill(255, 255, 255)
        doc:text(10, 7, "Report Title")
    ]],
    colored_section = [[
        doc:set_color_fill(236, 240, 241)
        doc:rect(10, 50, 190, 80, "F")
        doc:set_color_fill(0, 0, 0)
        doc:text(15, 55, "Content")
    ]],
    metric_box = [[
        doc:set_color_fill(52, 152, 219)
        doc:rect(x, y, 40, 20, "F")
        doc:set_font("Helvetica", "B", 12)
        doc:set_color_fill(255, 255, 255)
        doc:text(x, y + 5, value, 40, "C")
    ]],
}

PDF.Utils = Utils
PDF.Helper = Helper
PDF.QuickRef = QuickRef
PDF.PaperSizes = Utils.PaperSizes
PDF.Colors = Utils.Colors

return PDF
