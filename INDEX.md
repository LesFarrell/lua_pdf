# Lua PDF Library Index

This repository is centered around a single module, `pdf.lua`, plus runnable examples and reference documentation.

## Project Layout

```text
pdf/
├── pdf.lua
├── README.md
├── GETTING_STARTED.md
├── INDEX.md
├── LICENSE
├── examples/
│   ├── advanced_features.lua
│   ├── basic_text_shapes.lua
│   ├── forms.lua
│   ├── multipage_document.lua
│   ├── png_embedding.lua
│   ├── report_layout.lua
│   ├── test.lua
│   └── blh_cat_transparent.png
└── *.pdf
```

Notes:
- `pdf.lua` is the only code module you need to require.
- The generated `*.pdf` files in the repository root are example outputs, not source files.

## Main Module

`pdf.lua` contains:
- the `PDF` document API
- low-level PNG decoding
- PDF serialization and stream compression
- `PDF.Utils`
- `PDF.Helper`
- `PDF.QuickRef`

Primary document methods:
- `PDF.new()`
- `add_page()`
- `set_font()`
- `text()`
- `rect()`, `circle()`, `line()`
- `image_png()`, `image_png_data()`
- `form_text()`, `form_checkbox()`, `form_radio()`, `form_combo()`, `form_list()`, `form_signature()`
- `link()`, `note()`
- `save()`

## Documentation Files

- [README.md](README.md): complete API and capability reference
- [GETTING_STARTED.md](GETTING_STARTED.md): short practical guide
- [INDEX.md](INDEX.md): this project map

## Example Guide

### basic_text_shapes.lua

Focus:
- basic text placement
- wrapped text
- vector drawing
- links and note annotations

Output:
- `basic_text_shapes.pdf`

### multipage_document.lua

Focus:
- multiple pages
- styled sections
- color usage
- mixed font styles

Output:
- `multipage_document.pdf`

### report_layout.lua

Focus:
- report-like composition
- metric cards
- table-like layout using a local helper
- footer styling

Output:
- `report_layout.pdf`

Note:
- The table renderer in this example is local to the example; it is not a built-in library API.

### advanced_features.lua

Focus:
- `title_page`
- `page_break`
- `two_column_layout`
- `progress_bar`
- `checklist_item`
- `highlight_box`

Output:
- `advanced_features.pdf`

### forms.lua

Focus:
- interactive AcroForm widgets
- text fields
- checkboxes
- combo boxes
- list boxes
- radio groups
- signature widgets

Output:
- `forms.pdf`

### png_embedding.lua

Focus:
- PNG embedding from disk
- transparency preservation via soft masks
- image framing and attribution text

Output:
- `png_embedding.pdf`

### test.lua

Focus:
- smoke/integration testing across the library surface
- metadata verification
- compression verification
- form/annotation registration

Output:
- `test_output.pdf`

Run it from the repository root:

```bash
lua examples/test.lua
```

## Quick Start Commands

Generate all examples one by one from the repository root:

```bash
lua examples/basic_text_shapes.lua
lua examples/multipage_document.lua
lua examples/report_layout.lua
lua examples/advanced_features.lua
lua examples/forms.lua
lua examples/png_embedding.lua
lua examples/test.lua
```

## Feature Summary

Implemented:
- pure Lua PDF generation
- page management
- standard PDF fonts
- wrapped text
- rectangles, circles, lines
- PNG embedding
- link and note annotations
- basic AcroForm widgets
- helper-driven layout methods
- default stream compression

Not implemented yet:
- custom font embedding
- JPEG/SVG support
- internal links/bookmarks/outlines
- digital signing workflow
- XMP metadata packets
- built-in table abstraction

## Useful Exports

```lua
local PDF = require("pdf")

local a4 = PDF.PaperSizes.A4
local blue = PDF.Colors.blue
local pt = PDF.Utils.mm_to_pt(10)
```

Top-level convenience exports:
- `PDF.PaperSizes`
- `PDF.Colors`
- `PDF.Utils`
- `PDF.Helper`
- `PDF.QuickRef`
