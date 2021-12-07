using Genie, Stipple

Base.@kwdef mutable struct ButtonState <: ReactiveModel
  state::R{Int} = 1
  mousedown::R{Bool} = false
  mouseup::R{Bool} = false
end

const model = Stipple.init(ButtonState())

const last_click_time = Ref(time())
on(model.mousedown) do _
  if model.mousedown[]
    model.mousedown[] = false
    println("mousedown ", model.state[])

    model.state[] += 1
    last_click_time[] = time()
  end
end

on(model.mouseup) do _
  if model.mouseup[]
    model.mouseup[] = false
    println("mouseup ", model.state[])

    if time() - last_click_time[] < 0.2
      model.state[] += 1
    end
  end
end

function ui()
    page(
        vm(model), class="container", [
            #<q-btn color="black" class="full-width" label="Full-width" />
            Html.div("", @text(:state), 
                     class="switch", 
                     style="color:#fff; width:50px; height:50px; background:#999; margin: 100px;",
                     @on("mousedown", "mousedown = true"), 
                     @on("mouseup", "mouseup = true"), 
            )
        ]
    ) |> html
end

route("/", ui)

#up(80,"0.0.0.0",async=false)
