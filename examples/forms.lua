package.path = package.path .. ";../?lua;../?.lua"

local PDF = require("pdf")

local doc = PDF.new()
doc.title = "PDF Form Example"
doc.author = "Lua PDF Library"
doc:set_metadata({
    subject = "Interactive PDF form example",
    keywords = "forms, acroform, widgets",
    creator = "examples/forms.lua",
    Company = "Lua PDF Library",
})

doc:add_page(PDF.PaperSizes.A4.width, PDF.PaperSizes.A4.height)

doc:set_font("Helvetica", "B", 16)
doc:text(10, 15, "Contact Form")

doc:set_font("Helvetica", "", 10)
doc:set_color_fill(0, 0, 0)

doc:text(10, 30, "Name")
doc:form_text(10, 34, 90, 10, "contact_name", {
    value = "Ada Lovelace",
})

doc:text(10, 50, "Email")
doc:form_text(10, 54, 120, 10, "contact_email", {
    value = "ada@example.com",
})

doc:text(10, 70, "Notes")
doc:form_text(10, 74, 150, 24, "contact_notes", {
    value = "Interested in the analytical engine.",
    multiline = true,
    font_size = 10,
})

doc:text(10, 108, "Subscribe to updates")
doc:form_checkbox(10, 112, 6, "subscribe_updates", true)

doc:text(10, 128, "Department")
doc:form_combo(10, 132, 80, 10, "department", {
    "Research",
    "Engineering",
    "Operations",
}, {
    value = "Engineering",
})

doc:text(10, 148, "Interests")
doc:form_list(10, 152, 80, 26, "interests", {
    "Mathematics",
    "Poetry",
    "Computing",
    "Astronomy",
}, {
    value = {"Mathematics", "Computing"},
    multi_select = true,
})

doc:text(10, 188, "Signature")
doc:form_signature(10, 192, 90, 18, "customer_signature")

doc:text(110, 128, "Plan")
doc:form_radio(110, 132, 6, "plan_tier", "Basic", false)
doc:text(118, 134, "Basic")
doc:form_radio(110, 142, 6, "plan_tier", "Pro", true)
doc:text(118, 144, "Pro")
doc:form_radio(110, 152, 6, "plan_tier", "Enterprise", false)
doc:text(118, 154, "Enterprise")

doc:save("forms.pdf")
print("Created forms.pdf")
