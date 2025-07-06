local module = {}

--- @param rect Rect
--- @param point Vec2
function rect_contains(rect, point)
  return point.x >= rect.x --
    and point.x < rect.x + rect.w --
    and point.y < rect.y + rect.h --
    and point.y >= rect.y --
end
module.rect_contains = rect_contains

--- @param r1 Rect
--- @param r2 Rect
--- @return Rect|nil
function rect_intersection(r1, r2)
  local left = math.max(r1.x, r2.x)
  local top = math.max(r1.y, r2.y)
  local right = math.min(r1.x + r1.w, r2.x + r2.w)
  local bottom = math.min(r1.y + r1.h, r2.y + r2.h)

  if right < left or bottom < top then
    return nil
  end

  return {
    x = left,
    y = top,
    w = right - left,
    h = bottom - top,
  }
end
module.rect_intersection = rect_intersection

return module
