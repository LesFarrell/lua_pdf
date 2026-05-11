# Lua PDF Library

A pure Lua library for generating PDF files without external dependencies. It is distributed as a single `pdf.lua` module and supports text, vector drawing, multi-page documents, layout helpers, and native PNG embedding.

## Highlights

- Single-file library: `require("pdf")`
- Pure Lua PDF generation
- Multi-page documents with custom page sizes
- Standard PDF fonts: Helvetica, Times, Courier
- Text placement with left, center, and right alignment
- Basic vector drawing: rectangles, circles, lines
- Helper methods for headers, footers, title pages, checklists, and progress bars
- Native PNG embedding from file paths or raw PNG data
- Built-in utilities for units, colors, paper sizes, and formatting

## Project Layout

```text
pdf/
├── pdf.lua
├── README.md
├── GETTING_STARTED.md
├── INDEX.md
├── LICENSE
└── examples/
    ├── basic_text_shapes.lua
    ├── multipage_document.lua
    ├── report_layout.lua
    ├── advanced_features.lua
    ├── png_embedding.lua
    ├── test.lua
    └── blh_cat_transparent.png
```

## Installation

Place `pdf.lua` somewhere on your Lua package path, then:

```lua
local PDF = require("pdf")
```

Requires Lua 5.1+.

## Quick Start

```lua
local PDF = require("pdf")

local doc = PDF.new()
doc.title = "Hello"
doc.author = "Lua PDF Library"

doc:add_page(PDF.PaperSizes.A4.width, PDF.PaperSizes.A4.height)
doc:set_font("Helvetica", "B", 16)
doc:text(10, 12, "Hello, World!")

doc:set_color_fill(52, 152, 219)
doc:rect(10, 22, 60, 18, "F")

doc:set_font("Helvetica", "", 10)
doc:set_color_fill(255, 255, 255)
doc:text(40, 33, "Generated in pure Lua", nil, "C")

doc:save("hello.pdf")
```

## Running Examples

From the repository root:

```bash
lua examples/basic_text_shapes.lua
lua examples/multipage_document.lua
lua examples/report_layout.lua
lua examples/advanced_features.lua
lua examples/png_embedding.lua
```

Run the bundled smoke test with:

```bash
lua examples/test.lua
```

## Core API

### Create documents

```lua
local doc = PDF.new()
doc:add_page(210, 297)
doc:save("output.pdf")
```

`PDF.new()`
- Creates a new document object.

`doc:add_page(width, height, [orientation])`
- Adds a page in millimeters.
- `orientation` may be `"P"` or `"L"`.

### Text

Call `set_font` before adding text.

```lua
doc:set_font("Helvetica", "B", 12)
doc:text(10, 10, "Left aligned")
doc:text(105, 20, "Centered", nil, "C")
doc:text(200, 30, "Right aligned", nil, "R")
```

`doc:set_font(family, [style], [size])`
- Families: `Helvetica`, `Times`, `Courier`
- Styles: `""`, `"B"`, `"I"`, `"BI"`
- Size is in points

`doc:text(x, y, text, [width], [align])`
- Positions text in millimeters
- `align` may be `"L"`, `"C"`, or `"R"`
- If `width` is omitted, alignment uses `x` as the anchor point

### Shapes and drawing

```lua
doc:set_color_fill(255, 0, 0)
doc:rect(10, 40, 40, 20, "F")

doc:set_color_stroke(0, 0, 0)
doc:set_line_width(0.5)
doc:circle(80, 50, 10, "S")
doc:line(10, 70, 100, 70)
```

`doc:rect(x, y, width, height, [style])`
- Styles: `"S"`, `"F"`, `"DF"`

`doc:circle(x, y, radius, [style])`
- Styles: `"S"`, `"F"`, `"DF"`

`doc:line(x1, y1, x2, y2)`

`doc:set_color_fill(r, g, b, [a])`

`doc:set_color_stroke(r, g, b, [a])`

`doc:set_line_width(width)`

Color values can be given as either `0..255` or normalized `0..1`.

### PNG images

The library can embed PNGs directly and preserves PNG alpha via a soft mask when present.

```lua
doc:image_png("examples/blh_cat_transparent.png", 20, 40, 80, 80)
```

```lua
local raw_png = assert(io.open("icon.png", "rb")):read("*all")
doc:image_png_data(raw_png, 20, 130, 25, 25, "icon-cache-key")
```

`doc:image_png(path, x, y, [width], [height])`
- Loads a PNG from disk and draws it on the current page

`doc:image_png_data(data, x, y, [width], [height], [cache_key])`
- Draws from raw PNG bytes already in memory

If `width` and `height` are omitted, the image uses a default 72 DPI conversion.

### Layout helpers

These are exposed as document methods and also via `PDF.Helper`.

```lua
local y = doc:add_header("Monthly Report", "April 2026")
y = doc:section_header("Summary", y + 10)
doc:highlight_box(10, y, 60, 18, "Healthy", {46, 204, 113}, {255, 255, 255})
doc:add_footer(true)
```

Available helpers:

- `doc:add_header(title, [subtitle])`
- `doc:add_footer([show_date])`
- `doc:section_header(text, y)`
- `doc:highlight_box(x, y, width, height, text, [bgcolor], [textcolor])`
- `doc:box(x, y, width, height, [border_color], [border_width])`
- `doc:title_page(title, [subtitle], [content_lines])`
- `doc:page_break(page_width, page_height, [with_header])`
- `doc:two_column_layout(left_title, left_content, right_title, right_content, y)`
- `doc:watermark(text, [opacity])`
- `doc:checklist_item(x, y, text, checked)`
- `doc:progress_bar(x, y, width, height, percentage, [color])`

## Utilities

`require("pdf")` also exposes helpers directly:

```lua
local PDF = require("pdf")

local a4 = PDF.PaperSizes.A4
local blue = PDF.Colors.blue
local pt = PDF.Utils.mm_to_pt(10)
local hex = PDF.Utils.rgb_to_hex(255, 0, 0)
```

Useful utility groups:

- `PDF.PaperSizes`
- `PDF.Colors`
- `PDF.Utils`
- `PDF.Helper`
- `PDF.QuickRef`

Selected utility functions:

- `PDF.Utils.mm_to_pt(mm)`
- `PDF.Utils.pt_to_mm(pt)`
- `PDF.Utils.in_to_mm(inches)`
- `PDF.Utils.mm_to_in(mm)`
- `PDF.Utils.rgb_to_hex(r, g, b)`
- `PDF.Utils.hex_to_rgb(hex)`
- `PDF.Utils.hsv_to_rgb(h, s, v)`
- `PDF.Utils.rgb_to_hsv(r, g, b)`
- `PDF.Utils.color_gradient(color1, color2, steps)`
- `PDF.Utils.format_number(num, decimals)`
- `PDF.Utils.get_pdf_timestamp()`

## Coordinate System

- Units are millimeters
- Origin is top-left
- X increases to the right
- Y increases downward

## Current Limitations

- Built-in fonts are limited to the standard PDF font set
- Text wrapping is not implemented yet; the `width` argument on `text` currently only affects alignment
- General drawing transparency is not emitted as PDF transparency, even though color setters accept an alpha argument
- PNG is the only image format supported today
- No forms, annotations, or table abstraction layer

## License

MIT
