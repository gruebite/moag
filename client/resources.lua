local Resources = {}
Resources.__index = Resources

local loaders = {
    [".tga"] = love.graphics.newImage,
    [".png"] = love.graphics.newImage,
    [".jpg"] = love.graphics.newImage,
    [".bmp"] = love.graphics.newImage,
    [".ttf"] = love.graphics.newFont,
    [".wav"] = love.audio.newSource,
}

function Resources.new(basename)
    local self = setmetatable({}, Resources)
    self.basename = basename or "resources/"
    self._cache = {}
    return self
end

function Resources:get(key)
    return self._cache[key]
end

function Resources:load(key, filename, ...)
    local ext = filename:match("^.+(%..+)$")
    assert(loaders[ext], ext .. " not supported")
    self._cache[key] = loaders[ext](self.basename .. filename, ...)
    return self._cache[key]
end

function Resources:clear()
    self._cache = {}
end

return Resources.new()
