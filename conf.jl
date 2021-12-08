Page([
  LoopingSwitch([
   Switch("reset1","black", "my_location",[
    Reset(:kitchenfront),
   ]),
  ]),
  LoopingSwitch([
   Switch("reset2","black", "my_location",[
    Reset(:livingroom_wall),
   ]),
  ]),
  LoopingSwitch([
   Switch("all off","black", "my_location",[
    Off(:kitchenfront),
    Off(:livingroom_wall),
   ]),
  ]),
  LoopingSwitch([
   Switch("all on","amber","navigation",[
    On(:kitchenfront),
    On(:livingroom_wall),
   ])
  ]),
  LoopingSwitch([
   Switch("Looping Switch","primary", "shopping_cart",[
    On(:kitchenfront),
    Off(:livingroom_wall),
   ]),
   Switch("Looping Switch","purple", "edit_location", [
    Off(:kitchenfront),
    On(:livingroom_wall),
   ]),
  ]),
  LoopingSwitch([
   Switch("Random 1","deep-orange", "directions",[
    RandomIntensity(:kitchenfront, 0.0:0.5),
    RandomIntensity(:livingroom_wall, 0.0:0.5),
   ]),
   Switch("Random 2","secondary", "directions",[
    RandomIntensity(:kitchenfront,0.25:0.75),
    RandomIntensity(:livingroom_wall, 0.25:0.75),
   ]),
   Switch("Random 3","amber", "directions",[
    RandomIntensity(:kitchenfront,0.5:1.0),
    RandomIntensity(:livingroom_wall, 0.5:1.0),
   ]),
   Switch("Random 4","brown-5", "",[
    RandomIntensity(:livingroom_wall),
    RandomIntensity(:kitchenfront),
   ]),
  ])
])
