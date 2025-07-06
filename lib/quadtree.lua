local printtable = require("lib.printtable")
local utils = require("lib.utils")
local rect_intersection = utils.rect_intersection
local rect_contains = utils.rect_contains

--- @alias Rect { x: number, y: number, w: number, h: number }
--- @alias Item Particle

--- @class QuadTree
--- @field divided boolean
--- @field children Item[]
--- @field nodes { nw: QuadTree, ne: QuadTree, sw: QuadTree, se: QuadTree}|nil
--- @field boundary Rect
--- @field capacity integer
local QuadTree = {}
QuadTree.__index = QuadTree

--- @param boundary Rect
--- @return QuadTree
function QuadTree:new(boundary)
  local instance = setmetatable({}, self)
  instance.divided = false
  instance.children = {}
  instance.nodes = nil
  instance.boundary = boundary
  instance.capacity = 5

  return instance
end

--- @overload fun(item: Item)
function QuadTree:insert(item)
  if rect_contains(self.boundary, item.pos) then
    if #self.children < 5 or not self.divided then
      table.insert(self.children, item)
    else
      if not self.divided then
        self:subdivide()
      end

      self.nodes.nw:insert(item)
      self.nodes.ne:insert(item)
      self.nodes.sw:insert(item)
      self.nodes.se:insert(item)
    end
  end
end

function QuadTree:subdivide()
  local x = self.boundary.x
  local y = self.boundary.y
  local w = self.boundary.w
  local h = self.boundary.h

  self.nodes = {
    nw = QuadTree:new({
      x = x,
      y = y,
      w = w / 2,
      h = h / 2,
    }),
    ne = QuadTree:new({
      x = x + w / 2,
      y = y,
      w = w / 2,
      h = h / 2,
    }),
    sw = QuadTree:new({
      x = x,
      y = y + h / 2,
      w = w / 2,
      h = h / 2,
    }),
    se = QuadTree:new({
      x = x + w / 2,
      y = y + h / 2,
      w = w / 2,
      h = h / 2,
    }),
  }

  for _, item in ipairs(self.children) do
    self.nodes.nw:insert(item)
    self.nodes.ne:insert(item)
    self.nodes.sw:insert(item)
    self.nodes.se:insert(item)
  end

  self.children = {}
  self.divided = true
end

--- @param boundary Rect
--- @return Item[]
function QuadTree:query(boundary)
  local found = {}

  if not (rect_intersection(self.boundary, boundary) == nil) then
    if self.divided then
      local nw_result = self.nodes.nw:query(boundary)
      local ne_result = self.nodes.ne:query(boundary)
      local sw_result = self.nodes.sw:query(boundary)
      local se_result = self.nodes.se:query(boundary)

      for _, v in ipairs(nw_result) do
        table.insert(found, v)
      end
      for _, v in ipairs(ne_result) do
        table.insert(found, v)
      end
      for _, v in ipairs(sw_result) do
        table.insert(found, v)
      end
      for _, v in ipairs(se_result) do
        table.insert(found, v)
      end
    else
      for _, v in ipairs(self.children) do
        if rect_contains(boundary, v.pos) then
          table.insert(found, v)
        end
      end
    end
  end

  return found
end

return QuadTree
