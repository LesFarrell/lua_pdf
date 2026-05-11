# Lua PDF Library - Complete Package

A pure Lua library for creating PDF documents. No external dependencies required!

## 📁 Project Structure

```
pdf/
├── pdf.lua                 # Core library plus built-in utils/helpers/reference
├── test.lua              # Test suite
├── README.md             # Full API documentation
├── GETTING_STARTED.md    # Quick start guide
├── LICENSE               # MIT License
└── examples/
    ├── basic_text_shapes.lua        # Simple PDF with text and shapes
    ├── multipage_document.lua       # Multi-page document with styling
    ├── report_layout.lua            # Report with tables and layout
    ├── advanced_features.lua        # Advanced features showcase
    ├── png_embedding.lua            # PNG image embedding example
    └── blh_cat_transparent.png      # Cat PNG asset for image example
```

## 🚀 Quick Start

### 1. Create Your First PDF

```bash
lua -e "
local PDF = require('pdf')
local doc = PDF.new()
doc:add_page(210, 297)
doc:set_font('Helvetica', 'B', 16)
doc:text(10, 10, 'Hello, World!')
doc:save('hello.pdf')
"
```

### 2. Run Examples

```bash
# Run basic example
lua examples/basic_text_shapes.lua

# Run multi-page example
lua examples/multipage_document.lua

# Run report example
lua examples/report_layout.lua

# Run advanced example
lua examples/advanced_features.lua
```

### 3. Run Tests

```bash
lua test.lua
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Complete API documentation with all methods and parameters |
| **GETTING_STARTED.md** | Beginner-friendly guide with common tasks |
| **test.lua** | Validation and test suite |

## 🔧 Core Modules

### pdf.lua
The main PDF library module. Contains:
- `PDF.new()` - Create new document
- `add_page()` - Add pages
- `text()` - Add text
- `rect()`, `circle()`, `line()` - Draw shapes
- `set_font()` - Font management
- `set_color_fill()`, `set_color_stroke()` - Colors
- `save()` - Generate PDF file

It also exposes:
- `PDF.Utils` - Conversions, paper sizes, colors, and utility helpers
- `PDF.Helper` - Header/footer/layout helper functions
- `PDF.QuickRef` - Embedded quick-reference snippets

## 📖 Features

✅ **Pure Lua** - No external dependencies
✅ **Multi-page documents** - Create documents with any number of pages
✅ **Text formatting** - Bold, italic, different fonts
✅ **Colors** - Full RGB support with transparency
✅ **Shapes** - Rectangles, circles, lines
✅ **Professional layouts** - Headers, footers, sections
✅ **Coordinates in mm** - Intuitive millimeter-based positioning
✅ **Standard fonts** - Helvetica, Times, Courier
✅ **PDF 1.4 compliant** - Works with all PDF readers
✅ **Helper functions** - Pre-built common patterns

## 🎯 Common Use Cases

### Create a Simple Document
See `basic_text_shapes.lua`

### Create a Multi-Page Report
See `report_layout.lua`

### Create Professional Layouts
See `advanced_features.lua`

### Use Helper Functions
See `helper.lua` documentation

## 🔍 File Guide

### For Users
1. Start with **GETTING_STARTED.md**
2. Check **examples/** for inspiration
3. Reference **README.md** for API details
4. Use **PDF.QuickRef** for code snippets

### For Developers
1. Study **pdf.lua** for core implementation
2. Review `PDF.Utils` and `PDF.Helper` inside **pdf.lua**
3. Extend **pdf.lua** with custom helper patterns
4. Run **test.lua** to validate changes

## 📝 API Quick Reference

```lua
-- Create and save
local doc = PDF.new()
doc:add_page(210, 297)
doc:save("output.pdf")

-- Text
doc:set_font("Helvetica", "B", 12)
doc:text(10, 10, "Hello")

-- Shapes
doc:rect(10, 10, 50, 30, "F")    -- Filled
doc:rect(10, 10, 50, 30, "S")    -- Outline
doc:circle(50, 50, 10, "F")
doc:line(10, 10, 100, 100)

-- Colors
doc:set_color_fill(255, 0, 0)     -- Red
doc:set_color_stroke(0, 0, 0)     -- Black
doc:set_line_width(0.5)

-- Helpers (from helper.lua)
doc:add_header("Title")
doc:progress_bar(x, y, 100, 10, 75)
doc:checklist_item(x, y, "Task", true)
```

## 🎨 Coordinates System

- **Origin**: Top-left corner (0, 0)
- **X-axis**: Increases to the right
- **Y-axis**: Increases downward
- **Units**: Millimeters (mm)
- **A4 Size**: 210mm × 297mm

## 🌟 Standard Paper Sizes

| Size | Width | Height |
|------|-------|--------|
| A4 | 210mm | 297mm |
| Letter | 215.9mm | 279.4mm |
| A3 | 297mm | 420mm |
| A5 | 148mm | 210mm |

## 📋 Font Options

**Families**: Helvetica, Times, Courier
**Styles**: Regular (""), Bold ("B"), Italic ("I"), Bold-Italic ("BI")

## 🎨 Color Formats

```lua
-- RGB 0-255
doc:set_color_fill(255, 0, 0)

-- RGB 0-1 normalized
doc:set_color_fill(1, 0, 0)

-- With transparency (0-1)
doc:set_color_fill(1, 0, 0, 0.5)
```

## 🧪 Testing

Run the test suite to verify everything works:

```bash
lua test.lua
```

Expected output: All tests pass ✅

## 📖 Examples Explained

| Example | Focus | Demonstrates |
|---------|-------|--------------|
| basic_text_shapes | Core features | Text, shapes, colors |
| multipage_document | Multi-page docs | Page management, styling |
| report_layout | Professional layout | Tables, metrics, reports |
| advanced_features | Helper functions | Title pages, checklists |

## ⚙️ Requirements

- Lua 5.1 or later
- No external libraries needed
- Works on Windows, macOS, Linux

## 📄 License

MIT License - See LICENSE file

## 🤝 Contributing

Feel free to extend this library:
- Add new helper functions to `helper.lua`
- Create additional utility functions in `utils.lua`
- Share examples in the `examples/` directory
- Report issues or improvements

## 📞 Support

- Check **README.md** for full API documentation
- See **GETTING_STARTED.md** for common tasks
- Review **examples/** for code samples
- Use **quick_reference.lua** for snippets

## 🚀 Next Steps

1. Run an example: `lua examples/basic_text_shapes.lua`
2. Read the GETTING_STARTED guide
3. Create your first PDF
4. Explore the helper functions
5. Build your PDF application!

---

**Happy PDF Creating!** 📄✨

Built with ❤️ using pure Lua
