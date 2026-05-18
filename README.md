# Lua PDF Library

A pure Lua library for generating PDF files without external dependencies. It is distributed as a single `pdf.lua` module and supports text, vector drawing, multi-page documents, layout helpers, and native PNG embedding.

## Highlights

- Single-file library: `require("pdf")`
- Pure Lua PDF generation
- Multi-page documents with custom page sizes
- Standard PDF fonts: Helvetica, Times, Courier
- Text placement with left, center, and right alignment plus basic wrapping
- Basic vector drawing: rectangles, circles, lines
- Helper methods for headers, footers, title pages, checklists, and progress bars
- Native PNG embedding from file paths or raw PNG data
- Link and note annotations
- Basic AcroForm support for text fields, checkboxes, radio buttons, dropdowns, list boxes, and signature widgets
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
    ├── forms.lua
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
doc.keywords = "hello, example, lua"

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
lua examples/forms.lua
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
- Stream compression is enabled by default; set `doc.compression = false` before `save()` to write raw streams instead

Common document metadata fields are available as direct properties:
- `doc.title`
- `doc.author`
- `doc.subject`
- `doc.keywords`
- `doc.creator`
- `doc.producer`
- `doc.created`
- `doc.modified`

You can also set them in one call:

```lua
doc:set_metadata({
    title = "Quarterly Report",
    author = "Finance Team",
    keywords = "q1, sales, finance",
    creator = "Internal Reporting Tool",
    producer = "Lua PDF Library",
    Company = "Example Corp",
})
```

`doc:set_metadata(metadata_table)`
- Updates standard Info dictionary fields and stores any additional keys as custom PDF Info entries
- Date strings should use PDF timestamp format such as `D:20260518143000`

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
doc:text(10, 40, "This paragraph wraps when width is provided.", 50, "L")
```

`doc:set_font(family, [style], [size])`
- Families: `Helvetica`, `Times`, `Courier`
- Styles: `""`, `"B"`, `"I"`, `"BI"`
- Size is in points

`doc:text(x, y, text, [width], [align])`
- Positions text in millimeters
- `align` may be `"L"`, `"C"`, or `"R"`
- If `width` is omitted, alignment uses `x` as the anchor point
- If `width` is provided, text wraps within that column width and the method returns the rendered height in millimeters

### Annotations

The library can emit basic PDF annotations alongside forms.

```lua
doc:text(10, 20, "Project website")
doc:link(10, 20, 35, 6, "https://example.com")
doc:note(50, 20, 8, 8, "Follow up on this section", {
    title = "Reviewer",
    icon = "Comment",
})
```

`doc:link(x, y, width, height, url, [options])`
- Adds an external URL link annotation over the given rectangle
- `options.border_width` controls the visible border and defaults to `0`

`doc:note(x, y, width, height, contents, [options])`
- Adds a text note annotation
- `options.title` sets the popup author/title
- `options.icon` sets the PDF note icon name such as `Note`, `Comment`, or `Help`
- `options.open` controls whether the note starts expanded
- `options.color` accepts either `0..255` or `0..1` RGB values

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

### Forms

The library can emit interactive AcroForm widgets for simple PDFs.

```lua
doc:add_page(210, 297)
doc:set_font("Helvetica", "", 11)
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

doc:text(10, 80, "Interests")
doc:form_list(10, 84, 80, 22, "interests", {
    "Math",
    "Computing",
    "Astronomy",
}, {
    value = {"Math", "Computing"},
    multi_select = true,
})

doc:text(10, 116, "Signature")
doc:form_signature(10, 120, 90, 18, "customer_signature")

doc:text(110, 60, "Plan")
doc:form_radio(110, 64, 6, "plan_tier", "Basic", false)
doc:text(118, 66, "Basic")
doc:form_radio(110, 74, 6, "plan_tier", "Pro", true)
doc:text(118, 76, "Pro")
```

`doc:form_text(x, y, width, height, name, [options])`
- Adds an interactive text field
- `options.value` sets the current value
- `options.default_value` sets the reset value
- `options.multiline`, `options.read_only`, `options.required`, and `options.password` map to PDF field flags
- `options.align` may be `"L"`, `"C"`, or `"R"`
- `options.font_size`, `options.border_width`, `options.border_color`, `options.background_color`, and `options.text_color` control appearance hints

`doc:form_checkbox(x, y, size, name, checked, [options])`
- Adds an interactive checkbox widget
- `checked` sets the initial state
- `options.read_only` and `options.required` are supported

`doc:form_radio(x, y, size, group_name, option_name, checked, [options])`
- Adds one radio button widget to a shared group
- Use the same `group_name` for all buttons in the set
- `option_name` is the export value for that choice
- Only one button in a group should be created with `checked = true`
- `options.no_toggle_to_off` keeps the group from clearing once one item is selected

`doc:form_combo(x, y, width, height, name, choices, [options])`
- Adds a dropdown choice field
- `choices` is an array of visible option strings
- `options.value` and `options.default_value` set the selected value
- `options.editable` creates an editable combo box
- `options.align`, `options.font_size`, and color/border options work like `form_text`

`doc:form_list(x, y, width, height, name, choices, [options])`
- Adds a list box field
- `options.value` may be a single string or an array when `options.multi_select = true`
- `options.top_index` controls the first visible row
- `options.align`, `options.font_size`, and color/border options work like `form_text`

`doc:form_signature(x, y, width, height, name, [options])`
- Adds an empty signature widget area
- This creates the field container only; actual cryptographic signing is not implemented by the library

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
- General drawing transparency is not emitted as PDF transparency, even though color setters accept an alpha argument
- PNG is the only image format supported today
- Form support is currently limited to AcroForm text fields, checkboxes, radio buttons, dropdowns, list boxes, and unsigned signature widgets
- Push buttons and digital signing workflows are not implemented yet
- No non-form annotations or table abstraction layer
- Annotation support is currently limited to external links and text notes
- Metadata is currently written to the PDF Info dictionary only; XMP metadata packets are not emitted yet

## License

MIT
