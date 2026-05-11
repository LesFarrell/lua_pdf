-- Example 3: Report with Tables and Complex Layout
-- Demonstrates creating structured documents with tables and reports

package.path = package.path .. ";../?lua;../?.lua"

local PDF = require("pdf")

-- Helper function to draw a table
local function draw_table(doc, x, y, columns, rows, data)
    local table_width = columns.width or (doc.current_page.width - x - 10)
    local col_width = table_width / #columns
    local row_height = 10
    local cell_padding = 2
    local header_y_offset = 3.2
    local row_y_offset = 3.4
    
    -- Draw header
    doc:set_color_fill(44, 62, 80)
    doc:rect(x, y, table_width, row_height, "F")
    
    doc:set_font("Helvetica", "B", 10)
    doc:set_color_fill(255, 255, 255)
    
    for i, header in ipairs(columns) do
        local col_x = x + (i - 1) * col_width
        doc:text(col_x + cell_padding, y + header_y_offset, header)
    end
    
    -- Draw rows
    local current_y = y + row_height
    doc:set_font("Helvetica", "", 9)
    
    for row_idx, row in ipairs(data) do
        -- Alternate row colors
        if row_idx % 2 == 0 then
            doc:set_color_fill(236, 240, 241)
            doc:rect(x, current_y, table_width, row_height, "F")
        end
        
        doc:set_color_fill(0, 0, 0)
        for col_idx, value in ipairs(row) do
            local col_x = x + (col_idx - 1) * col_width
            doc:text(col_x + cell_padding, current_y + row_y_offset, tostring(value))
        end
        
        current_y = current_y + row_height
    end
    
    -- Draw borders
    doc:set_color_stroke(52, 152, 219)
    doc:set_line_width(0.3)
    
    for i = 0, #columns do
        local line_x = x + i * col_width
        doc:line(line_x, y, line_x, current_y)
    end
    
    for i = 0, #data do
        local line_y = y + (i) * row_height
        if i == 0 then line_y = y end
        if i == #data then line_y = y + row_height + #data * row_height end
        doc:line(x, y + i * row_height, x + table_width, y + i * row_height)
    end
    
    doc:line(x, y + row_height + #data * row_height, 
             x + table_width, y + row_height + #data * row_height)
    
    return current_y + row_height
end

-- Create document
local doc = PDF.new()
doc.title = "Sales Report"
doc.author = "Lua PDF Library"
doc.subject = "Q1 2024 Sales Report"

-- Page 1
doc:add_page(PDF.Utils.PaperSizes.A4.width, PDF.Utils.PaperSizes.A4.height)

-- Header with background
doc:set_color_fill(41, 128, 185)
doc:rect(0, 0, 210, 25, "F")

doc:set_font("Helvetica", "B", 18)
doc:set_color_fill(255, 255, 255)
doc:text(10, 5, "Q1 2024 Sales Report")

doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "", 11)
doc:text(10, 35, "Report Summary")

-- Key metrics boxes
local metrics = {
    {label = "Total Revenue", value = "$125,450"},
    {label = "Units Sold", value = "2,341"},
    {label = "Avg. Order", value = "$53.60"},
    {label = "Growth", value = "+12.5%"},
}

local metric_x = 10
for i, metric in ipairs(metrics) do
    local box_x = metric_x + (i - 1) * 48
    
    -- Box background
    doc:set_color_fill(236, 240, 241)
    doc:rect(box_x, 50, 45, 30, "F")
    
    -- Box border
    doc:set_color_stroke(52, 152, 219)
    doc:set_line_width(0.5)
    doc:rect(box_x, 50, 45, 30, "S")
    
    -- Metric label
    doc:set_color_fill(127, 140, 141)
    doc:set_font("Helvetica", "", 8)
    doc:text(box_x, 52, metric.label, 45, "C")
    
    -- Metric value
    doc:set_color_fill(41, 128, 185)
    doc:set_font("Helvetica", "B", 11)
    doc:text(box_x, 62, metric.value, 45, "C")
end

-- Section: Monthly Breakdown
doc:set_color_fill(0, 0, 0)
doc:set_font("Helvetica", "B", 12)
doc:text(10, 95, "Monthly Breakdown")

-- Table data
local month_data = {
    {"January", "$38,900", "758", "$51.32", "+8.2%"},
    {"February", "$41,200", "782", "$52.68", "+5.9%"},
    {"March", "$45,350", "801", "$56.60", "+9.8%"},
}

-- Draw table
draw_table(doc, 10, 110, 
    {"Month", "Revenue", "Units", "Avg Order", "Growth"},
    3,
    month_data)

-- Section: Top Products
doc:set_font("Helvetica", "B", 12)
doc:set_color_fill(0, 0, 0)
doc:text(10, 160, "Top Performing Products")

-- Product data
local product_data = {
    {"Product A", "845", "$31,455", "37.3%"},
    {"Product B", "612", "$28,908", "34.2%"},
    {"Product C", "484", "$23,232", "27.5%"},
}

draw_table(doc, 10, 175,
    {"Product", "Units", "Revenue", "% of Total"},
    3,
    product_data)

-- Section: Notes
doc:set_font("Helvetica", "B", 11)
doc:set_color_fill(0, 0, 0)
doc:text(10, 225, "Notes & Analysis")

doc:set_font("Helvetica", "", 10)
doc:set_color_fill(52, 73, 94)
doc:text(10, 240, "• Strong performance in Q1 with overall growth of 12.5%")
doc:text(10, 250, "• March saw the highest revenue, indicating positive market trends")
doc:text(10, 260, "• Product A continues to be the market leader with 37.3% of sales")

-- Footer
doc:set_color_fill(44, 62, 80)
doc:rect(0, 280, 210, 17, "F")

doc:set_font("Helvetica", "", 9)
doc:set_color_fill(255, 255, 255)
doc:text(10, 285, "Confidential - Internal Use Only", nil, "L")
doc:text(200, 285, os.date("%B %d, %Y"), nil, "R")

-- Save the PDF
doc:save("report_layout.pdf")
print("✓ Created report_layout.pdf")
