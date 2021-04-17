def = require "def"
oop = require "loop.simple"
linear = require "linear_warper"

Universe = oop.class(def)

--Universe.

--[[
createID = coroutine.create(
	function() 
		for i = 1, math.maxinteger do
			coroutine.yield("genericID_" .. i)
		end
	end
)--]]

--[[
function Asset:__new(ID, name)
	ID = ID or error("Must provide ID for asset")
	name = name or ID
	return oop.rawnew(self, {ID = ID, name = name})
end
--]]

--local rawMaterail = def.Material

function Universe.loadfile (filename)
  local r = {}
  local chunk, err = loadfile(filename,"bt", setmetatable(r, {__index = _G}))
  --TODO see if a more restrictive env makes sense
  if chunk == nil then
    print "bla"
    error(err)
  end
  chunk()
  return Universe(r)
end

function Universe:process()
  --processes information into algbraic objects
  --materials, machines and recipes tables
  local t = {materials = "Material", machines = "Machine", recipes = "LinProduction"}
  for k, _ in pairs(t) do
    self[k .. "_table"] = {}
    self[k .. "_number"] = 0
  end
  for k, v in pairs(self) do
    for n, c in pairs(t) do
      if oop.isinstanceof(v, def[c]) then
        self[n .. "_table"][k] = v
        self[n .. "_number"] = self[n .. "_number"] + 1
      end
    end
  end
  
  --asset list
  for _, n in pairs {"", "k", "r"} do
    for _, p in pairs {"assets", "recipes"} do
      self[p .. "_" .. n .. "list"] = {}
    end
  end
  
  for _, c in ipairs {"materials", "machines"} do
    for k, v in pairs(self[c .. "_table"]) do
      table.insert(self.assets_list, v)
      table.insert(self.assets_klist, k)
      local n = #self.assets_list
      self.assets_rlist[k] = n
      self.assets_rlist[v] = n
    end
  end
  
  --recipes list
  for k, v in pairs(self.recipes_table) do
    table.insert(self.recipes_list, v)
    table.insert(self.recipes_klist, k)
    local n = #self.recipes_list
    self.recipes_rlist[k] = n
    self.recipes_rlist[v] = n
  end
  --idle recipes
  for k, v in pairs(self.machines_table) do
    local r = def.LinProduction({})
    for x, y in pairs(v.production.diff) do
      r.diff[x] = - y
    end
    table.insert(self.recipes_list, r)
    table.insert(self.recipes_klist, "idle_" .. tostring(k))
    local n = #self.recipes_list
    self.recipes_rlist[k] = n
    self.recipes_rlist[r] = n
  end

  --production and recipe matrixes
  self.assets_number = #self.assets_list
  self.production_matrix = linear.matrix (self.assets_number, self.assets_number, "col")
  for _, i in pairs(self.machines_table) do
    for j, w in pairs(i.production.diff) do
      self.production_matrix[self.assets_rlist[i] ][self.assets_rlist[j] ] = w
    end
  end

  self.recipes_matrix = linear.matrix (self.assets_number, #self.recipes_list, "col")
  for i, r in ipairs(self.recipes_list) do
    for j, w in pairs(r.diff) do
      self.recipes_matrix[i][self.assets_rlist[j] ] = w
    end
  end
  self.processed = true
end

function Universe:exp_mainPhase()
  if not self.processed  then
    self:process()
  end
  -- main phase: every material can and should be spent, no machine should be idle
  --we first extract the part of the production and recipes matrices that relate to materials
  self.reduced_recipes_matrix = linear.sub(self.recipes_matrix, 1, 1, self.materials_number, self.materials_number)
  self.reduced_production_matrix = linear.sub(self.production_matrix, 1, 1, self.assets_number, self.materials_number)

  --then we compute the reduced strategy matrix using the condition of consuming every materials.
  self.strategy_matrix = linear.matrix(self.assets_number, self.assets_number, "col")
  self.reduced_strategy_matrix = linear.matrix(self.materials_number, self.assets_number, "col")
  self.intermediate_matrix = linear.matrix(self.materials_number, self.materials_number, "col")
  --TODO hide
  
  --A'+R'S' = 0  =>  S = - R'^-1 * A'
  linear.copy(self.reduced_recipes_matrix, self.intermediate_matrix)
  linear.inv(self.intermediate_matrix)
  linear.gemm(self.intermediate_matrix, self.reduced_production_matrix, self.reduced_strategy_matrix, -1)
  
  --we copy it into the full strategy matrix
  r, c, _ = linear.size(self.reduced_strategy_matrix)
  for i = 1, r do
    for j = 1, c do
      self.strategy_matrix[j][i] = self.reduced_strategy_matrix[j][i]
    end
  end
  --then we compute the dynamic matrix using the linear strategy
  self.dynamic_matrix = linear.matrix(self.assets_number, self.assets_number, "col")
  linear.copy(self.production_matrix, self.dynamic_matrix)
  linear.gemm(self.recipes_matrix, self.strategy_matrix, self.dynamic_matrix, 1, 1)
  --then we compute the reduced dynamics highlighting machines only
  self.reduced_dynamic_matrix = linear.sub(self.dynamic_matrix, self.assets_number - self.machines_number + 1, self.assets_number - self.machines_number + 1)
  
  --finally, we return a bunch of relevant matrices
  return self.reduced_dynamic_matrix, self.dynamic_matrix, self.strategy_matrix
end



return Universe