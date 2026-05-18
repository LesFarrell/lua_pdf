-- Test suite for Lua PDF Library
-- Run this file to verify the library is working correctly

local PDF = require("pdf")

local function decode_base64(input)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i = 1, #alphabet do
        lookup[alphabet:sub(i, i)] = i - 1
    end

    input = input:gsub("%s+", "")
    local out = {}
    local out_len = 0

    for i = 1, #input, 4 do
        local a = input:sub(i, i)
        local b = input:sub(i + 1, i + 1)
        local c = input:sub(i + 2, i + 2)
        local d = input:sub(i + 3, i + 3)

        local n = (lookup[a] or 0) * 262144 +
                  (lookup[b] or 0) * 4096 +
                  (lookup[c] or 0) * 64 +
                  (lookup[d] or 0)

        out_len = out_len + 1
        out[out_len] = string.char(math.floor(n / 65536) % 256)

        if c ~= "=" and c ~= "" then
            out_len = out_len + 1
            out[out_len] = string.char(math.floor(n / 256) % 256)
        end

        if d ~= "=" and d ~= "" then
            out_len = out_len + 1
            out[out_len] = string.char(n % 256)
        end
    end

    return table.concat(out)
end

print("🧪 Running Lua PDF Library Tests...\n")

-- Test 1: Basic document creation
print("Test 1: Creating basic document...")
local doc = PDF.new()
doc:add_page(210, 297)
doc:set_font("Helvetica", "B", 14)
doc:text(10, 10, "Test Document")
doc:set_font("Helvetica", "", 10)
doc:text(10, 18, "Page 1: Basic text rendering")
print("✓ Document created successfully")

-- Test 2: Multiple pages
print("\nTest 2: Adding multiple pages...")
doc:add_page(210, 297)
doc:set_font("Helvetica", "B", 12)
doc:text(10, 10, "Page 2: Multi-page support")
doc:set_font("Helvetica", "", 10)
doc:text(10, 18, "This page confirms additional pages are included in the output PDF.")
doc:add_page(210, 297)
assert(#doc.pages == 3, "Should have 3 pages")
print("✓ Multiple pages added successfully")

-- Test 3: Font settings
print("\nTest 3: Testing font settings...")
doc:set_font("Helvetica", "B", 12)
assert(doc.current_font == "Helvetica-B", "Font key should be 'Helvetica-B'")
doc:text(10, 10, "Page 3: Helvetica Bold sample")
doc:set_font("Times", "I", 10)
assert(doc.current_font == "Times-I", "Font key should be 'Times-I'")
doc:text(10, 18, "Times Italic sample text")
print("✓ Font settings work correctly")

-- Test 4: Color settings
print("\nTest 4: Testing color settings...")
doc:set_color_fill(255, 0, 0)
assert(doc.current_color_fill[1] == 1 and 
       doc.current_color_fill[2] == 0 and 
       doc.current_color_fill[3] == 0, "Should normalize RGB values")
doc:text(10, 28, "Red text sample")
doc:set_color_fill(0.5, 0.5, 0.5)
assert(doc.current_color_fill[1] == 0.5, "Should accept 0-1 values")
doc:text(10, 36, "Gray text sample")
print("✓ Color settings work correctly")

-- Test 5: Utils functions
print("\nTest 5: Testing utility functions...")
local mm_result = PDF.Utils.mm_to_pt(10)
assert(mm_result > 28 and mm_result < 29, "mm_to_pt conversion incorrect")
print("  • mm_to_pt: 10mm = " .. string.format("%.2f", mm_result) .. " pt ✓")

local pt_result = PDF.Utils.pt_to_mm(28.35)
assert(pt_result > 9.9 and pt_result < 10.1, "pt_to_mm conversion incorrect")
print("  • pt_to_mm: 28.35pt = " .. string.format("%.2f", pt_result) .. " mm ✓")

-- Test 6: Paper sizes
print("\nTest 6: Testing paper sizes...")
assert(PDF.Utils.PaperSizes.A4 ~= nil, "A4 paper size missing")
assert(PDF.Utils.PaperSizes.A4.width == 210, "A4 width incorrect")
assert(PDF.Utils.PaperSizes.A4.height == 297, "A4 height incorrect")
print("  • A4: " .. PDF.Utils.PaperSizes.A4.width .. " x " .. PDF.Utils.PaperSizes.A4.height .. " mm ✓")

assert(PDF.Utils.PaperSizes.Letter ~= nil, "Letter paper size missing")
print("  • Letter: " .. PDF.Utils.PaperSizes.Letter.width .. " x " .. PDF.Utils.PaperSizes.Letter.height .. " mm ✓")

-- Test 7: Color utilities
print("\nTest 7: Testing color utilities...")
local hex = PDF.Utils.rgb_to_hex(255, 0, 0)
assert(hex == "#FF0000", "RGB to hex conversion incorrect")
print("  • rgb_to_hex: (255,0,0) = " .. hex .. " ✓")

local r, g, b = PDF.Utils.hex_to_rgb("#00FF00")
assert(r == 0 and g == 255 and b == 0, "Hex to RGB conversion incorrect")
print("  • hex_to_rgb: #00FF00 = (" .. r .. "," .. g .. "," .. b .. ") ✓")

-- Test 8: Text escaping
print("\nTest 8: Testing text escaping...")
local escaped = PDF.Utils.escape_pdf_text("Test (text) with \\backslash")
assert(escaped:find("\\(", 1, true), "Should escape parentheses")
assert(escaped:find("\\\\", 1, true), "Should escape backslashes")
print("✓ Text escaping works correctly")

-- Test 9: Shape drawing
print("\nTest 9: Testing shape drawing...")
doc:add_page(210, 297)
doc:set_font("Helvetica", "B", 12)
doc:set_color_fill(0, 0, 0)
doc:text(10, 10, "Page 4: Shape drawing")
doc:set_color_fill(0, 0, 255)
doc:rect(10, 10, 50, 30, "F")
doc:circle(100, 50, 10, "S")
doc:line(10, 100, 100, 100)
doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "", 10)
doc:text(70, 20, "Blue filled rectangle")
doc:text(115, 50, "Circle outline")
doc:text(10, 108, "Horizontal line")
print("✓ Shape drawing functions work")

-- Test 10: PNG embedding
print("\nTest 10: Testing PNG embedding...")
local tiny_rgb = decode_base64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR42mP8z8BQDwAE/wH+krN0WQAAAABJRU5ErkJggg==")
local tiny_rgba = decode_base64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=")

doc:add_page(210, 297)
doc:set_font("Helvetica", "B", 12)
doc:set_color_fill(0, 0, 0)
doc:text(10, 10, "Page 5: PNG embedding")
doc:image_png_data(tiny_rgb, 10, 20, 20, 20, "tiny-rgb")
doc:image_png_data(tiny_rgba, 40, 20, 20, 20, "tiny-rgba")
doc:image_png("examples/blh_cat_transparent.png", 75, 20, 55, 55)
doc:set_font("Helvetica", "", 10)
doc:text(10, 48, "RGB PNG")
doc:text(40, 48, "RGBA PNG")
doc:text(75, 80, "Cat PNG")
print("✓ PNG embedding works")

-- Test 11: AcroForm fields
print("\nTest 11: Testing form fields...")
doc:add_page(210, 297)
doc:set_font("Helvetica", "", 10)
doc:set_color_fill(0, 0, 0)
doc:text(10, 10, "Page 6: AcroForm widgets")
doc:text(10, 22, "Name")
doc:form_text(10, 26, 80, 10, "test_name", {
    value = "Test User",
})
doc:text(10, 44, "Notes")
doc:form_text(10, 48, 120, 18, "test_notes", {
    value = "Multiline field",
    multiline = true,
})
doc:text(10, 76, "Receive updates")
doc:form_checkbox(10, 80, 6, "test_opt_in", true)
doc:text(10, 94, "Role")
doc:form_combo(10, 98, 70, 10, "test_role", {
    "Admin",
    "Editor",
    "Viewer",
}, {
    value = "Editor",
})
doc:text(10, 116, "Tags")
doc:form_list(10, 120, 90, 22, "test_tags", {
    "Alpha",
    "Beta",
    "Gamma",
}, {
    value = {"Alpha", "Gamma"},
    multi_select = true,
})
doc:text(10, 152, "Signature")
doc:form_signature(10, 156, 70, 16, "test_signature")
doc:text(110, 22, "Priority")
doc:form_radio(110, 26, 6, "test_priority", "Low", false)
doc:text(118, 28, "Low")
doc:form_radio(110, 36, 6, "test_priority", "Medium", true)
doc:text(118, 38, "Medium")
doc:form_radio(110, 46, 6, "test_priority", "High", false)
doc:text(118, 48, "High")
assert(#doc.forms == 9, "Should have 9 form fields")
print("✓ Form field definitions recorded")

-- Test 12: Wrapping and annotations
print("\nTest 12: Testing wrapping and annotations...")
doc:add_page(210, 297)
doc:set_font("Helvetica", "", 12)
doc:set_color_fill(0, 0, 0)
local wrapped_height = doc:text(10, 10,
    "This is a long sentence that should wrap across multiple lines when a width is supplied to the text renderer.",
    55, "L")
assert(wrapped_height > 6, "Wrapped text should consume more than one line of height")
doc:text(10, 40, "Link target")
doc:link(10, 40, 25, 6, "https://example.com")
doc:note(40, 40, 8, 8, "Review this section", {
    title = "Reviewer",
    icon = "Comment",
})
assert(#doc.annotations == 2, "Should have 2 non-form annotations")
print("✓ Wrapping and annotations recorded")

-- Test 13: Metadata
print("\nTest 13: Testing metadata...")
doc.title = "Test Document"
doc.author = "Lua PDF Test Suite"
doc.subject = "Testing the PDF library"
doc.keywords = "test, pdf, lua"
doc:set_metadata({
    creator = "examples/test.lua",
    producer = "Lua PDF Test Suite",
    Department = "QA",
})
assert(doc.creator == "examples/test.lua", "Metadata creator should be updated")
assert(doc.metadata.Department == "QA", "Custom metadata should be stored")
print("✓ Metadata fields recorded")

-- Test 14: PDF generation
print("\nTest 14: Generating PDF file...")

local success, error_msg = pcall(function()
    doc:save("test_output.pdf")
end)

if success then
    print("✓ PDF file generated successfully")
    
    -- Check if file exists
    local file = io.open("test_output.pdf", "rb")
    if file then
        local contents = file:read("*all")
        local size = file:seek("end")
        file:close()
        print("  • File size: " .. size .. " bytes")
        
        if size > 500 then
            print("✓ File size is reasonable")
        end

        assert(contents:find("/Keywords %(test, pdf, lua%)", 1), "PDF should include keywords metadata")
        assert(contents:find("/Creator %(examples/test.lua%)", 1), "PDF should include creator metadata")
        assert(contents:find("/Department %(QA%)", 1), "PDF should include custom metadata")
        assert(contents:find("/Subtype /Link", 1), "PDF should include a link annotation")
        assert(contents:find("/Subtype /Text", 1), "PDF should include a text annotation")
        assert(contents:find("/Filter /FlateDecode", 1, true), "PDF should compress stream objects by default")
        print("✓ Metadata written to PDF")
    else
        print("✗ File was not created")
    end
else
    print("✗ Error generating PDF: " .. error_msg)
end

-- Summary
print("\n" .. string.rep("=", 50))
print("✅ All tests completed!")
print("=" .. string.rep("=", 49))
print("\nYou can now use the library. See examples/ for usage samples.")
