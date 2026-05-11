-- Example 4: Advanced Features
-- Demonstrates using helper functions and complex layouts

package.path = package.path .. ";../?lua;../?.lua"

local PDF = require("pdf")

-- Create document
local doc = PDF.new()
doc.title = "Advanced PDF Features"
doc.author = "Lua PDF Library"

-- Create title page
doc:title_page(
    "Advanced",
    "PDF Features Guide",
    {
        "Creating Beautiful Documents",
        "Using Helper Functions",
        "Professional Layouts"
    }
)

-- Page 2: Two-column layout
doc:page_break(210, 297, {
    title = "Features Showcase",
    subtitle = "Page 2 - Two Column Layout"
})

local y = 40

-- Two-column content
local left_content = {
    "• Professional headers",
    "• Customizable footers",
    "• Title pages",
    "• Progress bars",
    "• Checkboxes",
}

local right_content = {
    "• Color gradients",
    "• Nested sections",
    "• Watermarks",
    "• Highlights",
    "• Layout helpers",
}

doc:two_column_layout(
    "Left Column", left_content,
    "Right Column", right_content,
    y)

-- Add progress bars
y = 160
doc:set_font("Helvetica", "B", 12)
doc:set_color_fill(0, 0, 0)
doc:text(10, y, "Progress Tracking")

y = y + 20
doc:text(10, y, "Project A: ")
doc:progress_bar(50, y - 2, 120, 6, 75, {46, 204, 113})

y = y + 15
doc:text(10, y, "Project B: ")
doc:progress_bar(50, y - 2, 120, 6, 45, {241, 196, 15})

y = y + 15
doc:text(10, y, "Project C: ")
doc:progress_bar(50, y - 2, 120, 6, 90, {231, 76, 60})

-- Add footer
doc:add_footer(true)

-- Page 3: Checklist and forms
doc:page_break(210, 297, {
    title = "Checklists & Organization",
    subtitle = "Page 3"
})

y = 40

doc:set_font("Helvetica", "B", 13)
doc:set_color_fill(0, 0, 0)
doc:text(10, y, "Project Checklist")

local checklist_items = {
    {text = "Define requirements", checked = true},
    {text = "Design interface", checked = true},
    {text = "Implement features", checked = true},
    {text = "Write tests", checked = false},
    {text = "Deploy to production", checked = false},
}

y = y + 15
for _, item in ipairs(checklist_items) do
    doc:checklist_item(10, y, item.text, item.checked)
    y = y + 12
end

-- Colored boxes for different statuses
y = y + 20
doc:set_font("Helvetica", "B", 12)
doc:text(10, y, "Status Summary")

y = y + 20
doc:highlight_box(10, y, 55, 20, "Done: 3/5", 
                     {46, 204, 113}, {255, 255, 255})

doc:highlight_box(70, y, 55, 20, "Active: 0/5",
                     {241, 196, 15}, {255, 255, 255})

doc:highlight_box(130, y, 55, 20, "Pending: 2/5",
                     {231, 76, 60}, {255, 255, 255})

-- Add footer
doc:add_footer(true)

-- Page 4: Styled report with boxes
doc:page_break(210, 297, {
    title = "Advanced Styling",
    subtitle = "Page 4 - Professional Design"
})

y = 40

-- Section with background
doc:set_color_fill(236, 240, 241)
doc:rect(0, y, 210, 50, "F")

doc:set_font("Helvetica", "B", 14)
doc:set_color_fill(44, 62, 80)
doc:text(10, y + 5, "Key Metrics")

-- Metric boxes
local metrics_data = {
    {label = "Revenue", value = "$125K", color = {52, 152, 219}},
    {label = "Users", value = "2,341", color = {46, 204, 113}},
    {label = "Growth", value = "+12.5%", color = {241, 196, 15}},
    {label = "Uptime", value = "99.9%", color = {155, 89, 182}},
}

local box_x = 10
local box_width = 40
for _, metric in ipairs(metrics_data) do
    doc:set_color_fill(metric.color[1], metric.color[2], metric.color[3])
    doc:rect(box_x, y + 25, box_width, 18, "F")
    
    doc:set_font("Helvetica", "B", 10)
    doc:set_color_fill(255, 255, 255)
    doc:text(box_x + box_width/2, y + 27, metric.value, nil, "C")
    
    doc:set_font("Helvetica", "", 8)
    doc:set_color_fill(200, 200, 200)
    doc:text(box_x + box_width/2, y + 37, metric.label, nil, "C")
    
    box_x = box_x + box_width + 5
end

-- Content sections
y = y + 60

doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "B", 12)
doc:text(10, y, "Implementation Details")

y = y + 15

-- Info boxes
local sections = {
    {title = "Architecture", content = {"Modular design", "Well documented", "Easy to extend"}},
    {title = "Performance", content = {"Optimized for speed", "Lean memory use", "Fast output"}},
    {title = "Support", content = {"Comprehensive docs", "Practical examples", "Clear API guide"}},
}

local section_x = 10
for _, section in ipairs(sections) do
    doc:box(section_x, y, 55, 45, {52, 152, 219}, 0.5)
    
    doc:set_font("Helvetica", "B", 10)
    doc:set_color_fill(52, 152, 219)
    doc:text(section_x + 27, y + 3, section.title, nil, "C")
    
    doc:set_font("Helvetica", "", 8)
    doc:set_color_fill(0, 0, 0)
    local line_y = y + 13
    for _, line in ipairs(section.content) do
        doc:text(section_x + 2, line_y, line)
        line_y = line_y + 8
    end
    
    section_x = section_x + 60
end

-- Add footer
doc:add_footer(true)

-- Save document
doc:save("advanced_features.pdf")
print("✓ Created advanced_features.pdf")
print("  This example demonstrates:")
print("  • Title page creation")
print("  • Two-column layouts")
print("  • Progress bars")
print("  • Checklists")
print("  • Status highlighting")
print("  • Professional styling")
