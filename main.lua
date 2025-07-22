local vec2 = require("lib.nvec")
local QuadTree = require("lib.quadtree")
local utils = require("lib.utils")
local printtable = require("lib.printtable")

local WIDTH = 800
local HEIGHT = 600
local CAMERA_SPEED = 400
local PARTICLE_SIZE = 10
local DETECT_RANGE = PARTICLE_SIZE * 3

local random = love.math.random

--- @alias Vec2 NVec

--- @class Particle
--- @field pos Vec2
--- @field speed Vec2
--- @field mass number
--- @field move boolean
-- --- @field uid string
local Particle = {}
Particle.__index = Particle

--- @param properties { pos: Vec2|nil, speed: Vec2|nil, mass: number|nil }
--- @return Particle
function Particle:new(properties)
  local instance = setmetatable({}, self)
  instance.pos = properties.pos or vec2(0, 0)
  instance.speed = properties.speed or rotated(math.pi * 2 * random()) * 10
  instance.mass = properties.mass or 1
  instance.move = true
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

  pause = false

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

  for _ = 1, 300, 1 do
    -- love.math.setRandomSeed(os.time())

    local pos = vec2(random(-WIDTH / 2, WIDTH / 2), random(-HEIGHT / 2, HEIGHT / 2))

    local particle = Particle:new({
      pos = pos,
    })

    table.insert(particles_buf, particle)
  end

  -- local min_x = 0
  -- local min_y = 0
  -- local max_x = 0
  -- local max_y = 0
  -- for _, p in ipairs(particles) do
  --   min_x = math.min(min_x, p.pos.x)
  --   min_y = math.min(min_y, p.pos.y)
  --   max_x = math.max(max_x, p.pos.x)
  --   max_y = math.max(max_y, p.pos.y)
  -- end

  -- --- @type Rect
  -- local world = {
  --   x = min_x,
  --   y = min_y,
  --   w = max_x - min_x,
  --   h = max_y - min_y,
  -- }

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

  if love.keyboard.isDown("=") then
    zoom = zoom + dt
  end
  if love.keyboard.isDown("-") then
    zoom = zoom - dt * 3
    if zoom <= 0.1 then
      zoom = 0.1
    end
  end

  -- local min_x = 0
  -- local min_y = 0
  -- local max_x = 0
  -- local max_y = 0
  -- for _, p in ipairs(particles) do
  --   min_x = math.min(min_x, p.pos.x)
  --   min_y = math.min(min_y, p.pos.y)
  --   max_x = math.max(max_x, p.pos.x)
  --   max_y = math.max(max_y, p.pos.y)
  -- end
  --
  -- --- @type Rect
  -- local world = {
  --   x = min_x,
  --   y = min_y,
  --   w = max_x - min_x,
  --   h = max_y - min_y,
  -- }

  if pause then
    return
  end

  qt = QuadTree:new(world)

  for _, particle in ipairs(particles) do
    qt:insert(particle)
  end

  for i = 1, #particles, 1 do
    ---@type Particle
    local particle = utils.copy(particles[i])

    if not particle.move then
      return
    end

    local near_particles_query = qt:query({
      x = particle.pos.x - DETECT_RANGE,
      y = particle.pos.y - DETECT_RANGE,
      w = DETECT_RANGE * 2,
      h = DETECT_RANGE * 2,
    } --[[@as Rect]])

    -- printtable(near_particles_query)
    for _, p in ipairs(near_particles_query) do
      local d2 = particle.pos:dist2(p.pos)
      if
        p.pos ~= particle.pos --
        and d2 <= PARTICLE_SIZE * PARTICLE_SIZE * 4
      then
        local p1 = particle
        local p2 = p
        local n = (p2.pos - p1.pos):normalized()
        if d2 <= PARTICLE_SIZE * PARTICLE_SIZE then
          p1.pos = (p1.pos + p2.pos) / 2 + n * PARTICLE_SIZE * 1.2
        end
        local v = p1.speed - 2 * p2.mass / (p2.mass + p1.mass) * (p1.speed - p2.speed):dot(n) * n
        particle.speed = v
      end
    end

    particle.pos = particle.pos + particle.speed * 10 * dt

    if particle.pos.x > WIDTH / 2 then
      particle.pos.x = WIDTH - particle.pos.x
      particle.speed.x = -particle.speed.x
    end
    if particle.pos.x < -WIDTH / 2 then
      particle.pos.x = -WIDTH - particle.pos.x
      particle.speed.x = -particle.speed.x
    end
    if particle.pos.y > HEIGHT / 2 then
      particle.pos.y = HEIGHT - particle.pos.y
      particle.speed.y = -particle.speed.y
    end
    if particle.pos.y < -HEIGHT / 2 then
      particle.pos.y = -HEIGHT - particle.pos.y
      particle.speed.y = -particle.speed.y
    end

    particles_buf[i] = particle
  end

  ---@type Particle[]
  particles = utils.copy(particles_buf)
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
      PARTICLE_SIZE * zoom
    )
    love.graphics.line(
      400 + (particle.pos.x - camera.x) * zoom, --
      300 + (particle.pos.y - camera.y) * zoom, --
      400 + (particle.pos.x + particle.speed.x - camera.x) * zoom, --
      300 + (particle.pos.y + particle.speed.y - camera.y) * zoom --
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
  if k == "space" then
    pause = not pause
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
