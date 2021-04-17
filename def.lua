--A file containing definition of common objects
local dsep, tsep, sub,exed, ign = package.config:match("^(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n$")
package.path = package.path  .. tsep .. "loop-3.0" .. dsep .. "lua" .. dsep .. sub .. ".lua"
oop = require "loop.simple"

local def = {}

--asset is anything a player can have
def.Asset = oop.class{flags = {}}

--Productions are atomic increment of the asset table
def.Production = oop.class({fns = function () return {} end})
function def.Production:__call(assets) return self:fns(assets) end

--LinProduction are constant change 
def.LinProduction = oop.class({diff = {}}, def.Production)
function def.LinProduction:fns ()
  return self.diff
end
function def.LinProduction:__new(diff)
  diff = diff or {}
  return oop.rawnew(self, {diff = diff})
end
--TODO: arithmetic metatables for LinProduction

-- Machines are Assets which produce things. The produciton  is a function or a vector 
def.Machine = oop.class({flags = {machine = true}, production = def.Production()}, def.Asset)
-- Materials are Asset that are meant to be consumed
def.Material = oop.class({flags = {material = true}}, def.Asset)
--Flux are Asset which cannot be stored
def.Flux = oop.class({flags = {flux = true}}, def.Asset)

-- Actions can be performed by the agent to modify the assets.
--def.Action = oop.class({production = Production(), date = 0, amount = 0})

--Run are sequences of actions performed from an initial universe
--def.Run = oop.class({time = 0, actionList = {}, initialAssets = {}, currentAssets= {}, })

return setmetatable(def, {__call =
    function(self)
      for k,v in pairs(self) do
        _G[k] = v
      end
    end
  }
)
--[[to enable both 
  d = require "def"
  and 
  require "def" ()  --unpiling everything in global
  syntaxes
  --]]