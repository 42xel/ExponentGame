require "def" ()
cont = require "continuous"

u = Universe.loadfile("burner_city.lua")

--[[
u = Universe
{
  --inert assets
  coal = Material(),
  ore = Material(),
  plate = Material(),
  
  --machines
  drill = Machine{production = LinProduction{
    coal = -3/80,
    ore = 0.25
    }
  },
  furnace = Machine{production = LinProduction{
    coal = -9/400,
    ore = -10/32,
    plate = 10/32
    }
  },

  --recipe/actions
  mine_coal = LinProduction{
    ore = -1,
    coal = 1
  },
  craft_furnace = LinProduction{
    ore = - 5,
    furnace = 1
  },
  craft_drill = LinProduction{
    plate = - 9,
    furnace = -1,
    drill = 1
  }
}
--]]

u:process()
for k, v in pairs(u.assets_klist) do
  print (k, v)
end

print "production and recipes matrix"
linear.print(u.production_matrix)
linear.print(u.recipes_matrix)

local rd, d, s = u:exp_mainPhase()
print "reduced production and recipes matrix"
linear.print(u.reduced_production_matrix)
linear.print(u.reduced_recipes_matrix)

print "inv of reduced recipe matrix"
linear.print(u.intermediate_matrix)

print "reduced strategy matrix"
linear.print(u.reduced_strategy_matrix)

print "A' + R'S'"
linear.print(u.reduced_production_matrix + (u.reduced_recipes_matrix * u.reduced_strategy_matrix))

print "main phase results:"
print "reduced dynamics"
linear.print(rd)
print "dynamics"
linear.print(d)
print "Strategy"
linear.print(s)