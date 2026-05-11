# Getting Started with Lua PDF Library

## Installation

1. Download `pdf.lua` to your project directory
2. Ensure you have Lua 5.1 or later installed

## Basic Usage

### Creating Your First PDF

```lua
local PDF = require("pdf")

-- Create a new document
local doc = PDF.new()

-- Add a page (width and height in millimeters)
doc:add_page(210, 297)  -- A4 size

-- Set font and add text
doc:set_font("Helvetica", "B", 16)
doc:text(10, 10, "Hello, World!")

-- Save the PDF
doc:save("hello.pdf")
```

### Running the Examples

```bash
lua examples/basic_text_shapes.lua
lua examples/multipage_document.lua
lua examples/report_layout.lua
```

## Common Tasks

### Adding Multiple Pages

```lua
local doc = PDF.new()

-- Page 1
doc:add_page(210, 297)
doc:set_font("Helvetica", "", 12)
doc:text(10, 10, "This is page 1")

-- Page 2
doc:add_page(210, 297)
doc:text(10, 10, "This is page 2")

doc:save("multipage.pdf")
```

### Working with Colors

```lua
local doc = PDF.new()
doc:add_page(210, 297)

-- Using 0-255 RGB values
doc:set_color_fill(255, 0, 0)  -- Red
doc:rect(10, 10, 50, 30, "F")  -- Fill red rectangle

-- Using 0-1 RGB values
doc:set_color_fill(0, 1, 0)    -- Green
doc:circle(100, 30, 15, "F")

-- Using predefined colors from PDF.Utils
doc:set_color_fill(PDF.Utils.Colors.blue[1], PDF.Utils.Colors.blue[2], PDF.Utils.Colors.blue[3])
```

### Text Formatting

```lua
local doc = PDF.new()
doc:add_page(210, 297)

-- Regular text
doc:set_font("Helvetica", "", 12)
doc:text(10, 10, "Regular text")

-- Bold text
doc:set_font("Helvetica", "B", 12)
doc:text(10, 25, "Bold text")

-- Italic text
doc:set_font("Helvetica", "I", 12)
doc:text(10, 40, "Italic text")

-- Bold Italic
doc:set_font("Helvetica", "BI", 12)
doc:text(10, 55, "Bold Italic text")

-- Different font families
doc:set_font("Times", "", 12)
doc:text(10, 70, "Times-Roman font")

doc:set_font("Courier", "", 12)
doc:text(10, 85, "Courier (monospace) font")
```

### Drawing Shapes

```lua
local doc = PDF.new()
doc:add_page(210, 297)

-- Rectangle (filled)
doc:set_color_fill(100, 150, 200)
doc:rect(10, 10, 50, 30, "F")

-- Rectangle (outline only)
doc:set_color_stroke(0, 0, 0)
doc:set_line_width(0.5)
doc:rect(70, 10, 50, 30, "S")

-- Rectangle (filled and outlined)
doc:rect(130, 10, 50, 30, "DF")

-- Circle (filled)
doc:set_color_fill(255, 0, 0)
doc:circle(35, 70, 10, "F")

-- Circle (outline)
doc:circle(100, 70, 10, "S")

-- Line
doc:set_color_stroke(0, 0, 0)
doc:line(10, 100, 100, 100)

-- Thick line
doc:set_line_width(2)
doc:line(10, 110, 100, 110)
```

### Using Built-In Helpers

```lua
local PDF = require("pdf")

local doc = PDF.new()
doc:add_page(210, 297)

-- Add header
local y = doc:add_header("My Report", "Monthly Summary")

-- Add section header
y = doc:section_header("Results", y)

-- Add content boxes
doc:highlight_box(10, y, 50, 20, "Performance: 95%", {52, 152, 219}, {255, 255, 255})

-- Add footer
doc:add_footer(true)  -- true = show date

doc:save("report.pdf")
```

### Working with Coordinates

The library uses millimeters (mm) as the default unit:
- Origin (0, 0) is at the top-left corner
- X increases to the right
- Y increases downward
- Standard A4: 210mm × 297mm

```lua
local doc = PDF.new()
doc:add_page(210, 297)

-- Top-left corner
doc:text(0, 0, "Top-left")

-- Center
doc:text(105, 148, "Center", nil, "C")

-- Bottom-right
doc:text(200, 290, "Bottom-right", nil, "R")
```

### Utilities Reference

```lua
-- Unit conversions
local points = PDF.Utils.mm_to_pt(10)           -- mm to points
local mm = PDF.Utils.pt_to_mm(28.35)            -- points to mm
local mm2 = PDF.Utils.in_to_mm(1)               -- inches to mm
local inches = PDF.Utils.mm_to_in(25.4)         -- mm to inches

-- Get paper size
local a4_width = PDF.Utils.PaperSizes.A4.width
local letter_height = PDF.Utils.PaperSizes.Letter.height

-- Work with colors
local color_name = PDF.Utils.Colors.red
local hex = PDF.Utils.rgb_to_hex(255, 0, 0)
local r, g, b = PDF.Utils.hex_to_rgb("#FF0000")

-- Color gradients
local gradient = PDF.Utils.color_gradient(
    PDF.Utils.Colors.red, 
    PDF.Utils.Colors.blue, 
    10  -- steps
)

-- Angle conversions
local radians = PDF.Utils.degrees_to_radians(90)
local degrees = PDF.Utils.radians_to_degrees(math.pi)

-- Get current timestamp
local timestamp = PDF.Utils.get_pdf_timestamp()
```

## API Quick Reference

### Document Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `PDF.new()` | - | Create new PDF |
| `doc:add_page(w, h, [orient])` | width, height, orientation | Add page |
| `doc:set_font(family, [style], [size])` | family, style, size | Set font |
| `doc:text(x, y, text, [w], [align])` | x, y, text, width, align | Add text |
| `doc:rect(x, y, w, h, [style])` | x, y, width, height, style | Draw rectangle |
| `doc:circle(x, y, r, [style])` | x, y, radius, style | Draw circle |
| `doc:line(x1, y1, x2, y2)` | x1, y1, x2, y2 | Draw line |
| `doc:set_color_fill(r, g, b, [a])` | r, g, b, alpha | Set fill color |
| `doc:set_color_stroke(r, g, b, [a])` | r, g, b, alpha | Set stroke color |
| `doc:set_line_width(w)` | width | Set line width |
| `doc:save(filename)` | filename | Save to file |

### Style Parameters

**Font Styles:**
- `""` - Regular
- `"B"` - Bold
- `"I"` - Italic
- `"BI"` - Bold Italic

**Shape Styles:**
- `"S"` - Stroke (outline)
- `"F"` - Fill
- `"DF"` - Fill and stroke

**Text Alignment:**
- `"L"` - Left
- `"C"` - Center
- `"R"` - Right

## Troubleshooting

### PDF not being created
- Ensure you called `doc:save()` at the end
- Check that the file path is writable
- Verify no other file has the same name

### Text not appearing
- Confirm you added a page with `doc:add_page()`
- Make sure the text position is within the page bounds
- Check that font is set with `doc:set_font()`

### Shapes not visible
- Verify fill or stroke color is set
- Ensure shape dimensions are positive
- Check that coordinates are within page bounds

## Performance Tips

1. Reuse fonts - set a font once and reuse it for multiple texts
2. Group similar operations - set colors before drawing multiple shapes
3. For large documents, generate pages dynamically instead of loading all in memory

## Limitations

- Limited to standard PDF fonts (no custom fonts)
- No image support yet
- No form fields or annotations
- No table support (but you can draw them manually)
- No text wrapping (but you can split text manually)

## Next Steps

- Check out the [examples/](examples/) directory for more complex usage patterns
- Read [README.md](README.md) for API documentation
- Explore the [test.lua](test.lua) file for validation

Happy PDF creating! 📄✨
