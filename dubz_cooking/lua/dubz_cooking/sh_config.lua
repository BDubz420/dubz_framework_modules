DubzCooking.Config = {
	-- The stove: put a milk and an ingredients bag against it and it starts cooking. Press E when the timer hits 0.
	cookSeconds = 30,

	-- What eating a donut gives
	donutEnergy = 10,
	donutHealth = 10,

	-- Golden donuts: each donut that spawns has a 1 in goldenChance chance of being golden instead (0 = never)
	goldenChance = 1000,
	goldenClass = "dubnut_gold",
	goldenEnergy = 10,
	goldenHealth = 10,
}

-- Master kill switch (admin menu > Modules). True when the framework isn't installed, so the addon still works.
function DubzCooking.Enabled()
	return not (DFW and DFW.Bind) or DFW.Bind.Enabled("cooking")
end
