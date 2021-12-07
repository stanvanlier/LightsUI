Page([
  LoopingSwitch([
   Switch("reset kitchen","black", "my_location", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "reset1"), [
    Reset(:kitchen),
   ]),
  ]),
  LoopingSwitch([
   Switch("reset rest","black", "my_location", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "reset2"), [
    Reset(:frontleft),
    Reset(:windows),
   ]),
  ]),
  LoopingSwitch([
   Switch("all off","black", "my_location", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "all off"), [
    Off(:frontleft),
    Off(:kitchen),
    Off(:windows),
   ]),
  ]),
  LoopingSwitch([
   Switch("all on","amber","navigation", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "all on"),[
    On(:frontleft),
    On(:kitchen),
    On(:windows),
   ])
  ]),
  LoopingSwitch([
   Switch("productivity","primary", "shopping_cart", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "productivity"),[
    On(:frontleft),
    Intensity(:kitchen, 0.4),
    Off(:windows),
   ]),
   Switch("netflix","purple", "edit_location", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "netflix"), [
    Off(:frontleft),
    Off(:kitchen),
    Intensity(:windows, 0.1),
   ]),
  ]),
  LoopingSwitch([
   Switch("Random 1","deep-orange", "directions", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "Random 1"),[
    RandomIntensity(:frontleft,0.0:0.5),
    RandomIntensity(:kitchen, 0.0:0.5),
    RandomIntensity(:windows, 0.0:0.5),
   ]),
   Switch("Random 2","secondary", "directions", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "Random 2"),[
    RandomIntensity(:frontleft,0.25:0.75),
    RandomIntensity(:kitchen, 0.25:0.75),
    RandomIntensity(:windows, 0.25:0.75),
   ]),
   Switch("Random 3","amber", "directions", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "Random 3"),[
    RandomIntensity(:frontleft,0.5:1.0),
    RandomIntensity(:kitchen, 0.5:1.0),
    RandomIntensity(:windows, 0.5:1.0),
   ]),
   Switch("Random 4","brown-5", "", Img("https://placeimg.com/500/300/nature?t=$(rand())",
                                                "Random 4"),[
    RandomIntensity(:frontleft),
    RandomIntensity(:kitchen),
    RandomIntensity(:windows),
   ]),
  ])
])
