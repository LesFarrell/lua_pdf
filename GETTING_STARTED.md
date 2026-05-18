# Getting Started with Lua PDF Library

`pdf.lua` is a single-file, pure Lua PDF generator. It can create multi-page PDFs with text, shapes, PNG images, annotations, helper-driven layouts, and basic AcroForm widgets.

## Installation

1. Copy `pdf.lua` into your project or Lua package path.
2. Use Lua 5.1 or later.
3. Require the module:

```lua
local PDF = require("pdf")
```

## First PDF

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

Notes:
- Coordinates are in millimeters.
- The origin is the top-left corner.
- Stream compression is enabled by default. Set `doc.compression = false` before `save()` if you want raw streams.

## Run the Examples

From the repository root:

```bash
lua examples/basic_text_shapes.lua
lua examples/multipage_document.lua
lua examples/report_layout.lua
lua examples/advanced_features.lua
lua examples/forms.lua
lua examples/png_embedding.lua
lua examples/test.lua
```

What each example covers:
- `basic_text_shapes.lua`: text, wrapping, shapes, links, note annotations
- `multipage_document.lua`: multi-page layout and styling
- `report_layout.lua`: report-style composition and a local table helper
- `advanced_features.lua`: helper methods such as title pages, progress bars, and checklists
- `forms.lua`: AcroForm text, checkbox, combo, list, radio, and signature widgets
- `png_embedding.lua`: PNG embedding with transparency
- `test.lua`: bundled smoke/integration test

## Common Tasks

### Add pages

```lua
local doc = PDF.new()

doc:add_page(210, 297)
doc:set_font("Helvetica", "", 12)
doc:text(10, 10, "This is page 1")

doc:add_page(210, 297)
doc:text(10, 10, "This is page 2")

doc:save("multipage.pdf")
```

### Add wrapped text

```lua
doc:set_font("Helvetica", "", 11)
local height = doc:text(
    10,
    20,
    "This paragraph wraps automatically when a width is supplied.",
    60,
    "L"
)
```

`height` is the rendered height in millimeters.

### Draw shapes

```lua
doc:set_color_fill(100, 150, 200)
doc:rect(10, 10, 50, 30, "F")

doc:set_color_stroke(0, 0, 0)
doc:set_line_width(0.5)
doc:rect(70, 10, 50, 30, "S")
doc:circle(35, 70, 10, "F")
doc:line(10, 100, 100, 100)
```

### Work with PNGs

```lua
doc:image_png("examples/blh_cat_transparent.png", 20, 40, 80, 80)
```

```lua
local raw_png = assert(io.open("icon.png", "rb")):read("*all")
doc:image_png_data(raw_png, 20, 130, 25, 25, "icon-cache-key")
```

### Add annotations

```lua
doc:text(10, 20, "Project website")
doc:link(10, 20, 35, 6, "https://example.com")

doc:note(50, 20, 8, 8, "Follow up on this section", {
    title = "Reviewer",
    icon = "Comment",
})
```

### Use layout helpers

```lua
local y = doc:add_header("Monthly Report", "April 2026")
y = doc:section_header("Summary", y + 10)
doc:highlight_box(10, y, 60, 18, "Healthy", {46, 204, 113}, {255, 255, 255})
doc:add_footer(true)
```

Available helper-backed methods:
- `add_header`
- `add_footer`
- `section_header`
- `highlight_box`
- `box`
- `title_page`
- `page_break`
- `two_column_layout`
- `watermark`
- `checklist_item`
- `progress_bar`

### Add form fields

```lua
doc:text(10, 20, "Name")
doc:form_text(10, 24, 90, 10, "customer_name", {
    value = "Ada Lovelace",
})

doc:text(10, 42, "Subscribe")
doc:form_checkbox(10, 46, 6, "newsletter_opt_in", true)

doc:text(10, 60, "Department")
doc:form_combo(10, 64, 80, 10, "department", {
    "Research",
    "Engineering",
    "Operations",
}, {
    value = "Engineering",
})
```

The library supports:
- text fields
- checkboxes
- radio groups
- combo boxes
- list boxes
- empty signature widgets

## Handy Utilities

```lua
local a4 = PDF.PaperSizes.A4
local blue = PDF.Colors.blue

local pt = PDF.Utils.mm_to_pt(10)
local mm = PDF.Utils.pt_to_mm(28.35)
local hex = PDF.Utils.rgb_to_hex(255, 0, 0)
local r, g, b = PDF.Utils.hex_to_rgb("#FF0000")
```

Useful exported groups:
- `PDF.PaperSizes`
- `PDF.Colors`
- `PDF.Utils`
- `PDF.Helper`
- `PDF.QuickRef`

## Troubleshooting

### PDF is not created

- Confirm `doc:save("file.pdf")` is being called.
- Make sure the output path is writable.
- Check for runtime errors printed by Lua.

### Text is missing

- Call `doc:add_page()` before drawing.
- Call `doc:set_font()` before `doc:text()`.
- Make sure coordinates are inside the page bounds.

### PNG loading fails

- Confirm the file is a PNG.
- Use a readable path from the current working directory.
- Note that PNG is the only supported image format today.

### Form field creation fails

- Make sure a page exists before creating fields.
- Supply non-empty field names.
- For radio buttons, use a shared `group_name` and unique `option_name` values.

## Current Limitations

- Built-in fonts only; no custom font embedding yet
- General drawing transparency is not emitted as PDF transparency
- PNG is the only supported image format
- Forms are limited to basic AcroForm widgets
- Signature fields are unsigned containers only
- Non-form annotations are limited to external links and text notes
- Metadata is written to the PDF Info dictionary only; XMP is not emitted

## Where to Look Next

- [README.md](README.md): full API reference
- [INDEX.md](INDEX.md): project map and example guide
- [examples](examples): runnable sample scripts
