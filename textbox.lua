--
-- TextBox widget re-using code from lite's DocView.
--

local core = require "core"
local config = require "core.config"
local style = require "core.style"
local Doc = require "core.doc"
local DocView = require "core.docview"
local View = require "core.view"
local Widget = require "widget"


---@class widget.textbox.SingleLineDoc
local SingleLineDoc = Doc:extend()

function SingleLineDoc:insert(line, col, text)
  text = text:gsub("\n", "")
  SingleLineDoc.super.insert(self, line, col, text)
end

---@class widget.textbox.TextView
local TextView = DocView:extend()

function TextView:new()
  TextView.super.new(self, SingleLineDoc())
  self.gutter_width = 0
  self.hide_lines_gutter = true
  self.gutter_text_brightness = 0
  self.scrollable = true
  self.font = "font"
end

function TextView:get_name()
  return View.get_name(self)
end

function TextView:get_text()
  return self.doc:get_text(1, 1, 1, math.huge)
end

function TextView:set_text(text, select)
  self.doc:remove(1, 1, math.huge, math.huge)
  self.doc:text_input(text)
  if select then
    self.doc:set_selection(math.huge, math.huge, 1, 1)
  end
end

function TextView:get_gutter_width()
  return self.gutter_width
end

function TextView:draw_line_gutter(idx, x, y)
  if self.hide_lines_gutter then
    return
  end
  TextView.super.draw_line_gutter(self, idx, x, y)
end

function TextView:draw_line_highlight()
  -- no-op function to disable this functionality
end

-- Overwrite this function just to disable the core.push_clip_rect
function TextView:draw()
  self:draw_background(style.background)

  self:get_font():set_tab_size(config.indent_size)

  local minline, maxline = self:get_visible_line_range()
  local lh = self:get_line_height()

  local x, y = self:get_line_screen_position(minline)
  for i = minline, maxline do
    self:draw_line_gutter(i, self.position.x, y)
    y = y + lh
  end

  local gw = self:get_gutter_width()
  local pos = self.position
  x, y = self:get_line_screen_position(minline)
  for i = minline, maxline do
    self:draw_line_body(i, x, y)
    y = y + lh
  end
  self:draw_overlay()

  self:draw_scrollbar()
end

---@class widget.textbox : widget
---@field public textview widget.textbox.TextView
---@field public placeholder string
---@field private placeholder_active string
local TextBox = Widget:extend()

function TextBox:new(parent, text, placeholder)
  TextBox.super.new(self, parent)
  self.textview = TextView()
  self.size.x = 200 + (style.padding.x * 2)
  self.size.y = self.font:get_height() + (style.padding.y * 2)
  self.placeholder = placeholder or ""
  self.placeholder_active = false
  -- this widget is for text input
  self.input_text = true

  if text ~= "" then
    self.textview:set_text(text, select)
  else
    self.placeholder_active = true
    self.textview:set_text(self.placeholder)
  end

  -- more granular listening of text changing events
  local this = self
  local doc_raw_insert = self.textview.doc.raw_insert
  function self.textview.doc:raw_insert(...)
    doc_raw_insert(self, ...)
    this:on_text_change("insert", ...)
  end

  local doc_raw_remove = self.textview.doc.raw_remove
  function self.textview.doc:raw_remove(...)
    doc_raw_remove(self, ...)
    this:on_text_change("remove", ...)
  end
end

--- Get the text displayed on the textbox.
---@return string
function TextBox:get_text()
  if self.placeholder_active then
    return ""
  end
  return self.textview:get_text()
end

--- Set the text displayed on the textbox.
---@param text string
---@param select boolean
function TextBox:set_text(text, select)
  self.textview:set_text(text, select)
end

--
-- Events
--

function TextBox:on_mouse_pressed(button, x, y, clicks)
  TextBox.super.on_mouse_pressed(self, button, x, y, clicks)
  self.textview:on_mouse_pressed(button, x, y, clicks)
end

function TextBox:on_mouse_released(button, x, y)
  TextBox.super.on_mouse_released(self, button, x, y)
  self.textview:on_mouse_released(button, x, y)
end

function TextBox:on_mouse_moved(x, y, dx, dy)
  TextBox.super.on_mouse_moved(self, x, y, dx, dy)
  self.textview:on_mouse_moved(x, y, dx, dy)
  system.set_cursor("ibeam")
end

function TextBox:activate()
  self.hover_border = style.caret
  if self.placeholder_active then
    self:set_text("")
    self.placeholder_active = false
  end
  system.set_cursor("ibeam")
end

function TextBox:deactivate()
  self.hover_border = nil
  if self:get_text() == "" then
    self:set_text(self.placeholder)
    self.placeholder_active = true
  end
  system.set_cursor("arrow")
end

function TextBox:on_text_input(text)
  TextBox.super.on_text_input(self, text)
  self.textview:on_text_input(text)
end

---Event fired on any text change event.
---@param action string Can be "insert" or "remove",
---insert arguments (see Doc:raw_insert):
---  line, col, text, undo_stack, time
---remove arguments (see Doc:raw_remove):
---  line1, col1, line2, col2, undo_stack, time
function TextBox:on_text_change(action, ...) end

function TextBox:update()
  TextBox.super.update(self)
  self.textview:update()
  self.size.y = self.font:get_height() + (style.padding.y * 2)
end

function TextBox:draw()
  self.border.color = self.hover_border or style.text
  TextBox.super.draw(self)
  self.textview.position.x = self.position.x + (style.padding.x / 2)
  self.textview.position.y = self.position.y - (style.padding.y/2.5)
  self.textview.size.x = self.size.x
  self.textview.size.y = self.size.y - (style.padding.y * 2)

  core.push_clip_rect(
    self.position.x,
    self.position.y,
    self.size.x,
    self.size.y
  )
  self.textview:draw()
  core.pop_clip_rect()
end


return TextBox

