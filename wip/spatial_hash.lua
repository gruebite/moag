local spatial_hash = {}
spatial_hash.mt = { __index = spatial_hash }

function spatial_hash.new(width, height, cell_size)
    local self = setmetatable({}, spatial_hash.mt)
    self._width = assert(width, "missing width parameter")
    self._cell_size = cell_size or 20
    self._cells = {}
    -- entity -> list of cell coords
    self._entities = {}
    return self
end

function spatial_hash:_touching_cells(ent)
    local offx = (ent.offset and ent.offset.x or 0) * (ent.siz.x or 0)
    local minx = (ent.pos.x - offx)
    local maxx = (ent.pos.x - offx) + ent.siz.x

end

function spatial_hash:remove(ent)
    local cells = self._entities[ent]

    for _, cell in ipairs(cells) do
        self._cells[cell.x][cell.y][ent] = nil
    end

    self._entities[ent] = nil
end

function spatial_hash:insert(ent)
    if self._entities[ent] then
        self:remove(ent)
    end
end

return spatial_hash
