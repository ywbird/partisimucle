local vec2 = require("lib.nvec")
local QuadTree = require("lib.quadtree")
local uid = require("lib.uuid")
local utils = require("lib.utils")
local rect_contains = utils.rect_contains
local printtable = require("lib.printtable")

local WIDTH = 800
local HEIGHT = 600
local CAMERA_SPEED = 400
local DETECT_RANGE = 60

local random = love.math.random

--- @alias Vec2 NVec

--- @class Particle
--- @field pos Vec2
--- @field speed Vec2
--- @field mass number
-- --- @field uid string
local Particle = {}
Particle.__index = Particle

--- @param properties { pos: Vec2|nil, speed: Vec2|nil, mass: number|nil }
--- @return Particle
function Particle:new(properties)
  local instance = setmetatable({}, self)
  instance.pos = properties.pos or vec2(0, 0)
  instance.speed = properties.speed or rotated(math.pi * 2 * random())
  instance.mass = properties.mass or 1
  --instance.uid = uid()
  return instance
end

function Particle:advance() end

function Particle:state()
  return string.format("{ pos: %s }", self.pos)
end

Particle.__tostring = Particle.state

function love.load()
  delta = 0

  camera = vec2(0, 0)

  zoom = 1

  font = {}
  font.galmuri = {}
  font.galmuri.normal = love.graphics.newFont("assets/fonts/Galmuri11.ttf", 12)
  love.graphics.setFont(font.galmuri.normal)

  cursor = {}
  cursor.pointer = love.mouse.getSystemCursor("arrow")
  cursor.hand = love.mouse.getSystemCursor("hand")

  --- @type Particle[]
  particles = {}

  --- @type Particle[]
  particles_buf = {}

  for _ = 1, 1000, 1 do
    -- love.math.setRandomSeed(os.time())

    local pos = vec2(random(-WIDTH / 2, WIDTH / 2), random(-HEIGHT / 2, HEIGHT / 2))

    local particle = Particle:new({
      pos = pos,
    })

    table.insert(particles_buf, particle)
  end

  --- @type Rect
  world = {
    x = -WIDTH / 2,
    y = -HEIGHT / 2,
    w = WIDTH,
    h = HEIGHT,
  }

  qt = QuadTree:new(world)

  for _, particle in ipairs(particles) do
    qt:insert(particle)
  end
end

function love.update(dt)
  delta = dt

  move = vec2(0, 0)

  if love.keyboard.isDown("d") then
    move.x = move.x + dt * CAMERA_SPEED / zoom
  end
  if love.keyboard.isDown("a") then
    move.x = move.x - dt * CAMERA_SPEED / zoom
  end
  if love.keyboard.isDown("w") then
    move.y = move.y - dt * CAMERA_SPEED / zoom
  end
  if love.keyboard.isDown("s") then
    move.y = move.y + dt * CAMERA_SPEED / zoom
  end

  modif = 1
  if love.keyboard.isDown("lshift") then
    modif = modif / 2
  end
  if love.keyboard.isDown("lctrl") then
    modif = modif * 2
  end

  camera = camera + move * modif

  if love.keyboard.isDown("+") then
    zoom = zoom + dt
  end
  if love.keyboard.isDown("-") then
    zoom = zoom - dt * 3
    if zoom <= 0.1 then
      zoom = 0.1
    end
  end

  particles = utils.copy(particles_buf)

  qt = QuadTree:new(world)

  for _, particle in ipairs(particles) do
    qt:insert(particle)
  end

  for _, particle in ipairs(particles) do
    local near_particles_query = qt:query({
      x = particle.pos.x - DETECT_RANGE,
      y = particle.pos.y - DETECT_RANGE,
      w = DETECT_RANGE * 2,
      h = DETECT_RANGE * 2,
    } --[[@as Rect]])

    particle.pos = particle.pos + particle.speed * 10 * dt

    -- printtable(near_particles_query)
    for _, p in ipairs(near_particles_query) do
      if p.pos ~= particle.pos then
        -- local d = particle.pos:dist2(p.pos)
        -- if d < DETECT_RANGE * DETECT_RANGE then
        --   particle.pos = particle.pos - (p.pos - particle.pos) / d * dt * 200
        -- end
      end
    end
  end

  particles_buf = qt:query(world)
end

function love.draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("dt:" .. delta, 10, 12)
  love.graphics.print("cam:" .. tostring(camera), 10, 30)

  for _, particle in pairs(particles) do
    love.graphics.circle(
      "fill",
      400 + (particle.pos.x - camera.x) * zoom,
      300 + (particle.pos.y - camera.y) * zoom,
      3 * zoom
    )
    love.graphics.line(
      400 + (particle.pos.x - camera.x) * zoom, --
      300 + (particle.pos.y - camera.y) * zoom, --
      400 + (particle.pos.x + particle.speed.x * 10 - camera.x) * zoom, --
      300 + (particle.pos.y + particle.speed.y * 10 - camera.y) * zoom --
    )
    -- love.graphics.circle(
    --   "line",
    --   400 + (particle.pos.x - camera.x) * zoom,
    --   300 + (particle.pos.y - camera.y) * zoom,
    --   DETECT_RANGE * zoom
    -- )
    -- love.graphics.circle(
    --   "line",
    --   400 + (particle.pos.x - camera.x) * zoom,
    --   300 + (particle.pos.y - camera.y) * zoom,
    --   DETECT_RANGE * zoom / 2
    -- )
  end

  -- love.graphics.setColor(1, 0, 0, 1)
  -- love.graphics.rectangle("fill", 400 - 1, 300 - 10, 2, 20)
  -- love.graphics.rectangle("fill", 400 - 10, 300 - 1, 20, 2)
end

function love.keypressed(k)
  if k == "q" then
    love.event.quit()
  end
end

function love.wheelmoved(_, y)
  zoom = zoom + y * 0.1
  if zoom <= 0.1 then
    zoom = 0.1
  end
end

function love.mousemoved(x, y, dx, dy, _)
  if love.mouse.isDown(1) then
    love.mouse.setCursor(cursor.hand)
    camera.x = camera.x - dx / zoom
    camera.y = camera.y - dy / zoom
  else
    love.mouse.setCursor(cursor.pointer)
  end
end

precos = {}
presin = {}
for i = 1, 360, 1 do
  table.insert(precos, math.cos(math.pi * 2 * i / 360))
  table.insert(presin, math.sin(math.pi * 2 * i / 360))
end

---pre computed cos function
---@param x number
---@return number
function f_precos(x)
  return precos[math.ceil(180 / math.pi * x)]
end

---pre computed cos function
---@param x number
---@return number
function f_presin(x)
  return presin[math.ceil(180 / math.pi * x)]
end

--- @param dir number
--- @return Vec2
function rotated(dir)
  return vec2(f_precos(dir), f_presin(dir))
end
