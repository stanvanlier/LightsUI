using Genie, Stipple, StippleUI
using LightsAPI

include("conf_types.jl")

const conf = include("conf.jl") 

Base.@kwdef mutable struct ButtonState <: ReactiveModel
  clicked_on::R{Int} = 0
  states::R{Vector} = Any[1 for _ in conf.switches]
  texts::R{Vector} = Any[s.sequence[1].text for s in conf.switches]
  colors::R{Vector} = Any[s.sequence[1].color for s in conf.switches]
  icons::R{Vector} = Any[s.sequence[1].icon for s in conf.switches]
end

const model = Stipple.init(ButtonState())

const last_click_time = Ref(time())
function clicked(i)
  print("clicked start ", i)
	timediff = time() - last_click_time[]
  println(" ",timediff)
	if timediff > 1.3
		last_click_time[] = time()
    LightsAPI.greet()
		println("$timediff, TODO handle $(conf.switches[i].sequence[model.states[][i]])")
    #handle(conf.switches[i].sequence[model.states[][i]])

		x = mod1(model.states[][i] + 1, length(conf.switches[i].sequence))
		model.states[][i] = x
		model.states[] = model.states[]

		model.texts[][i] = conf.switches[i].sequence[x].text
		model.texts[] = model.texts[]

		model.colors[][i] = conf.switches[i].sequence[x].color
		model.colors[] = model.colors[]

		model.icons[][i] = conf.switches[i].sequence[x].icon
		model.icons[] = model.icons[]
	end
end

on(model.clicked_on) do i
  println("clicked_on ",i)
  if model.clicked_on[] != 0
    clicked(i)
    model.clicked_on[] = 0
  end
end

const CSS = style("""
	html {
		height: 100%;
		background-color:black; 
	}
	body{
		padding-top:1px;
		background-color:black; 
		height: 100%;
    overflow-y:hidden;
  }
	"""
) 

function ui()
    CSS * page(
        vm(model), class="container", 
				  title="LightsUI",
					Html.div([
#            Html.div("", @text(:state), 
#                     class="switch", 
#                     style="float:left; color:#fff; width:80px; height:80px; background:#99F; margin: 100px;",
#                     @on("mousedown", "mousedown = true"), 
#                     @on("mouseup", "mouseup = true"), 
#            ),
							Html.for_each(enumerate(model.states[])) do (i,x)
								#Html.div([Html.p("", @text(Symbol("texts[$i]"))), Html.p("", @text(Symbol("states[$i]")))], 
								StippleUI.btn(
                  "", 
                  ":label=texts[$(i-1)]", 
                  ":color=colors[$(i-1)]",
                  ":icon=icons[$(i-1)]",
                  #class="full-width",
                  style="width: 231px;",
                  #"key='btn_size_round_xl'",
                  size="xl",
                  #size="gl",
                  :stack, :glossy,
                  ":ripple='false'",
                  @on(:mousedown, "clicked_on = $i"), 
                  @on(:mouseup, "clicked_on = $i"),
                  @on(:mouseenter, "clicked_on = $i"),
								)
	#              Html.div([Html.p("", @text("texts[$i]")), Html.p("", @text("states[$i]"))], 
	#                     
	#                     class="switch", 
	#                     style="float:left; color:#fff; width:90px; height:90px; background:#99F; margin: 10px;",
	#            )
					    end,
        ],style="overflow:scroll; height:100%;")
    ) |> html
end

route("/", ui)

up(80,"0.0.0.0",async=false)
