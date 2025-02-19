--
-- Line Widget.
-- @copyright Jefferson Gonzalez
-- @license MIT
--

local style = require "core.style"
local Widget = require "widget"

---@class widget.line : widget
---@field public padding integer
local Line = Widget:extend()

function Line:new(parent, thickness, padding)
  Line.super.new(self, parent)
  self.size.y = thickness or 2
  self.padding = padding or (style.padding.x / 2)
end

function Line:set_thickness(thickness)
  self.size.y  = thickness or 2
end

function Line:draw()
  self.size.x = self.parent.size.x

  renderer.draw_rect(
    self.position.x + self.padding,
    self.position.y,
    self.size.x - (self.padding * 2),
    self.size.y,
    self.foreground_color or style.caret
  )
end


return Line

