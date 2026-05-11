-- Example 5: PNG Image Embedding
-- Demonstrates embedding an internet-sourced PNG into a PDF
--
-- Source image:
-- BLH cat transparent.png by Chatterie des Millenovae
-- Wikimedia Commons: https://commons.wikimedia.org/wiki/File:BLH_cat_transparent.png
-- License: CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0/

package.path = package.path .. ";../?lua;../?.lua"

local PDF = require("pdf")

local doc = PDF.new()
doc.title = "PNG Image Example"
doc.author = "Lua PDF Library"
doc.subject = "Embedding PNG images into PDF documents"

doc:add_page(PDF.Utils.PaperSizes.A4.width, PDF.Utils.PaperSizes.A4.height)

doc:set_color_fill(44, 62, 80)
doc:rect(0, 0, 210, 28, "F")

doc:set_font("Helvetica", "B", 18)
doc:set_color_fill(255, 255, 255)
doc:text(10, 6, "PNG Image Example")

doc:set_font("Helvetica", "", 11)
doc:set_color_fill(52, 73, 94)
doc:text(10, 40, "This page demonstrates native PNG support in pdf.lua.")
doc:text(10, 48, "The image below is loaded from examples/blh_cat_transparent.png.")

doc:set_color_stroke(200, 200, 200)
doc:set_line_width(0.5)
doc:rect(18, 60, 120, 150, "S")

doc:image_png("examples/blh_cat_transparent.png", 24, 66, 108, 108)

doc:set_font("Helvetica", "B", 12)
doc:set_color_fill(0, 0, 0)
doc:text(10, 225, "Attribution")

doc:set_font("Helvetica", "", 10)
doc:set_color_fill(80, 80, 80)
doc:text(10, 236, "BLH cat transparent.png by Chatterie des Millenovae")
doc:text(10, 244, "Source: Wikimedia Commons")
doc:text(10, 252, "License: CC BY-SA 4.0")

doc:add_footer(true)

doc:save("png_embedding.pdf")
print("✓ Created png_embedding.pdf")
