using Genie, Stipple

Base.@kwdef mutable struct ButtonState <: ReactiveModel
  #state::R{Int} = 1
  mousedown::R{Int} = 0
  mouseup::R{Int} = 0
  arr::R{Vector{Any}} = Any[1,2,3]
end

const model = Stipple.init(ButtonState())


function clicked(i)
  model.arr[][i] = mod1(model.arr[][i] + 1, 3)
end


const last_click_time = Ref(time())
on(model.mousedown) do i
  if model.mousedown[] != 0
    println("mousedown ", i)

    clicked(i)
    last_click_time[] = time()

    model.mousedown[] = 0
  end
end

on(model.mouseup) do i
  if model.mouseup[] != 0
    timediff = time() - last_click_time[]

    if model.mousedown[] == 0 && timediff > 0.3
      println("mouseup ", i," ", timediff)
      clicked(i)
    end

    model.mouseup[] = 0
  end
end

function ui()
    page(
        vm(model), class="container", [
            #<q-btn color="black" class="full-width" label="Full-width" />
#            Html.div("", @text(:state), 
#                     class="switch", 
#                     style="float:left; color:#fff; width:80px; height:80px; background:#99F; margin: 100px;",
#                     @on("mousedown", "mousedown = true"), 
#                     @on("mouseup", "mouseup = true"), 
#            ),
            Html.for_each(enumerate(model.arr[])) do (i,x)
              Html.div(Html.p("", @text("arr[$(i-1)]")), 
                     class="switch", 
                     style="float:left; color:#fff; width:90px; height:90px; background:#99F; margin: 10px;",
                     @on("mousedown", "mousedown = $i"), 
                     @on("mouseup", "mouseup = $i"),
            )
            end,
            Html.p("", @text(R"arr")),
        ]
    ) |> html
end

route("/", ui)

#up(80,"0.0.0.0",async=false)
