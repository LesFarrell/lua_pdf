-- Example 2: Multi-page Document with Styling
-- Demonstrates advanced features like multiple pages and styling

package.path = package.path .. ";../?lua;../?.lua"

local PDF = require("pdf")

-- Create document
local doc = PDF.new()
doc.title = "Multi-Page Document"
doc.author = "Lua PDF Library"

-- Page 1: Title Page
doc:add_page(PDF.Utils.PaperSizes.A4.width, PDF.Utils.PaperSizes.A4.height)

-- Add decorative header
doc:set_color_fill(44, 62, 80)  -- Dark blue-gray
doc:rect(0, 0, 210, 80, "F")

-- Title
doc:set_font("Helvetica", "B", 36)
doc:set_color_fill(255, 255, 255)  -- White
doc:text(10, 25, "Lua PDF Library")

-- Subtitle
doc:set_font("Helvetica", "", 14)
doc:set_color_fill(236, 240, 241)  -- Light gray
doc:text(10, 50, "Creating PDFs with Pure Lua")

-- Main content
doc:set_color_fill(52, 73, 94)  -- Dark gray-blue
doc:set_font("Helvetica", "B", 18)
doc:text(10, 110, "Welcome")

doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "", 12)
doc:text(10, 130, "This document demonstrates the capabilities of the Lua PDF Library.")
doc:text(10, 142, "You can create professional documents with:")

local features = {
    "Multiple pages",
    "Various font styles (Bold, Italic)",
    "Custom colors and transparency",
    "Shapes and geometric elements",
    "Precise text positioning",
    "Formatted documents"
}

local y = 158
for i, feature in ipairs(features) do
    doc:set_color_fill(52, 152, 219)  -- Blue
    doc:set_font("Helvetica", "B", 11)
    doc:text(12, y, "•")
    
    doc:set_color_fill(0, 0, 0)
    doc:set_font("Helvetica", "", 11)
    doc:text(18, y, feature)
    
    y = y + 12
end

-- Add decorative footer
doc:set_color_fill(44, 62, 80)
doc:rect(0, 280, 210, 17, "F")
doc:set_font("Helvetica", "", 10)
doc:set_color_fill(255, 255, 255)
doc:text(10, 285, "Page 1")
doc:text(195, 285, os.date("%Y-%m-%d"), nil, "R")

-- Page 2: Content with colored sections
doc:add_page(PDF.Utils.PaperSizes.A4.width, PDF.Utils.PaperSizes.A4.height)

-- Header
doc:set_color_fill(44, 62, 80)
doc:rect(0, 0, 210, 20, "F")
doc:set_font("Helvetica", "B", 14)
doc:set_color_fill(255, 255, 255)
doc:text(10, 5, "Feature Showcase")

-- Section 1: Colors
doc:set_color_fill(231, 76, 60)  -- Red
doc:rect(10, 30, 60, 60, "F")
doc:set_color_fill(255, 255, 255)
doc:set_font("Helvetica", "B", 12)
doc:text(25, 45, "Colors")
doc:set_font("Helvetica", "", 10)
doc:text(15, 60, "Full RGB color")
doc:text(15, 70, "support with")
doc:text(15, 80, "transparency")

-- Section 2: Shapes
doc:set_color_fill(46, 204, 113)  -- Green
doc:rect(80, 30, 60, 60, "F")
doc:set_color_fill(255, 255, 255)
doc:set_font("Helvetica", "B", 12)
doc:text(92, 45, "Shapes")
doc:set_font("Helvetica", "", 10)
doc:text(85, 60, "Rectangles,")
doc:text(85, 70, "circles, lines")
doc:text(85, 80, "and more")

-- Section 3: Text
doc:set_color_fill(52, 152, 219)  -- Blue
doc:rect(150, 30, 50, 60, "F")
doc:set_color_fill(255, 255, 255)
doc:set_font("Helvetica", "B", 12)
doc:text(158, 45, "Text")
doc:set_font("Helvetica", "", 10)
doc:text(155, 60, "Multiple")
doc:text(155, 70, "fonts and")
doc:text(155, 80, "styles")

-- Section with colored boxes
doc:set_font("Helvetica", "B", 14)
doc:set_color_fill(0, 0, 0)
doc:text(10, 110, "Color Palette")

local colors = {
    {name = "Red", r = 231, g = 76, b = 60},
    {name = "Green", r = 46, g = 204, b = 113},
    {name = "Blue", r = 52, g = 152, b = 219},
    {name = "Yellow", r = 241, g = 196, b = 15},
}

local x = 10
for _, color in ipairs(colors) do
    doc:set_color_fill(color.r, color.g, color.b)
    doc:rect(x, 125, 35, 35, "F")
    
    doc:set_color_fill(0, 0, 0)
    doc:set_font("Helvetica", "", 9)
    doc:text(x, 165, color.name, nil, "C")
    
    x = x + 40
end

-- Text samples
doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "B", 14)
doc:text(10, 190, "Text Styles")

doc:set_font("Helvetica", "", 12)
doc:text(10, 210, "Regular text in Helvetica")

doc:set_font("Helvetica", "B", 12)
doc:text(10, 225, "Bold text in Helvetica")

doc:set_font("Helvetica", "I", 12)
doc:text(10, 240, "Italic text in Helvetica")

doc:set_font("Times", "", 12)
doc:text(10, 255, "Regular text in Times-Roman")

doc:set_font("Courier", "B", 12)
doc:text(10, 270, "Bold monospace in Courier")

-- Footer
doc:set_color_fill(44, 62, 80)
doc:rect(0, 280, 210, 17, "F")
doc:set_font("Helvetica", "", 10)
doc:set_color_fill(255, 255, 255)
doc:text(10, 285, "Page 2")
doc:text(195, 285, os.date("%Y-%m-%d"), nil, "R")

-- Save the PDF
doc:save("multipage_document.pdf")
print("✓ Created multipage_document.pdf")
