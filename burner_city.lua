--inert assets
coal = Material()
ore = Material()
plate = Material()

--machines
drill = Machine{production = LinProduction{
  coal = -3/80,
  ore = 0.25
  }
}
furnace = Machine{production = LinProduction{
  coal = -9/400,
  ore = -10/32,
  plate = 10/32
  }
}

--recipe/actions
mine_coal = LinProduction{
  ore = -1,
  coal = 1
}
craft_furnace = LinProduction{
  ore = - 5,
  furnace = 1
}
craft_drill = LinProduction{
  plate = - 9,
  furnace = -1,
  drill = 1
}