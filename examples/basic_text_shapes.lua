-- Example 1: Basic PDF Creation
-- Creates a simple single-page PDF with text and shapes

package.path = package.path .. ";../?lua;../?.lua"

local PDF = require("pdf")

-- Create a new PDF document
local doc = PDF.new()

-- Add a page (A4 size: 210x297 mm)
doc:add_page(PDF.Utils.PaperSizes.A4.width, PDF.Utils.PaperSizes.A4.height)

-- Set title and metadata
doc.title = "Basic PDF Example"
doc.author = "Lua PDF Library"
doc.subject = "Example document"
doc.keywords = "basic, shapes, text"
doc.creator = "examples/basic_text_shapes.lua"

-- Add a title
doc:set_font("Helvetica", "B", 24)
doc:set_color_fill(0, 51, 102)  -- Dark blue
doc:text(10, 10, "Welcome to Lua PDF")

-- Add some space
doc:set_color_fill(0, 0, 0)  -- Black
doc:set_font("Helvetica", "", 12)
doc:text(10, 30, "This is a simple PDF created using pure Lua.")
doc:text(10, 40, "No external dependencies required!")
doc:text(10, 50,
    "This paragraph is intentionally long so it wraps within a fixed column width. " ..
    "It shows how the text method now lays out multiple lines automatically.",
    85, "L")

-- Draw a rectangle with border
doc:set_color_fill(200, 220, 255)  -- Light blue
doc:set_color_stroke(0, 51, 102)   -- Dark blue
doc:set_line_width(0.5)
doc:rect(10, 85, 190, 40, "DF")    -- Fill and stroke

-- Add text inside the rectangle
doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "I", 11)
doc:text(15, 90, "Key Features:")
doc:text(15, 99, "• Create multi-page documents")
doc:text(15, 108, "• Add text with custom fonts and styles")
doc:text(15, 117, "• Draw shapes and graphics")

-- Draw some circles
doc:set_line_width(0.3)
doc:set_color_fill(255, 100, 100)  -- Red
doc:circle(30, 155, 5, "F")

doc:set_color_fill(100, 255, 100)  -- Green
doc:circle(80, 155, 5, "F")

doc:set_color_fill(100, 100, 255)  -- Blue
doc:circle(130, 155, 5, "F")

-- Draw a line
doc:set_color_stroke(0, 0, 0)
doc:line(10, 175, 200, 175)

-- Add interactive annotations
doc:set_color_fill(0, 0, 255)
doc:set_font("Helvetica", "B", 11)
doc:text(10, 186, "Visit the project page")
doc:link(10, 186, 50, 6, "https://example.com/pdf-library")
doc:note(170, 185, 8, 8, "This is a sample note annotation.", {
    title = "Lua PDF",
    icon = "Comment",
})

-- Add footer
doc:set_font("Helvetica", "", 10)
doc:set_color_fill(128, 128, 128)  -- Gray
doc:text(10, 280, "Page 1 of 1", nil, "L")
doc:text(200, 280, "Lua PDF Library", nil, "R")

-- Save the PDF
doc:save("basic_text_shapes.pdf")
print("✓ Created basic_text_shapes.pdf")
