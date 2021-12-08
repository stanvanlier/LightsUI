abstract type LightSetting end

struct On <: LightSetting
  lightid::Symbol
end

struct Off <: LightSetting
  lightid::Symbol
end

struct Intensity <: LightSetting
  lightid::Symbol
  intensity::Float64
end

struct Reset <: LightSetting
  lightid::Symbol
end

struct RandomIntensity <: LightSetting
  lightid::Symbol
  range::StepRangeLen{Float64}
end
RandomIntensity(lightid) = RandomIntensity(lightid, 0.0:1.0) 

handle(s::On) = LightsAPI.on(s.lightid) 
handle(s::Off) = LightsAPI.off(s.lightid)
handle(s::Intensity) = LightsAPI.set_intensity(s.lightid,s.intensity) 
handle(s::Reset) = LightsAPI.reset(s.lightid) 
handle(s::RandomIntensity) = begin 
  rangesize = last(s.range)-first(s.range)
  i = rand()*rangesize + first(s.range)
  println(s.lightid, " random to ", i)
  LightsAPI.set_intensity(s.lightid, i)
end

#struct RandomOn <: LightSetting
#  lightid::Symbol
#  prob::Float
#end
#RandomOn(lightid) = RandomOn(lightid, 0.5) # 50-50 as default
#
#struct RandomOff <: LightSetting
#  lightid::Symbol
#  prob::Float
#end
#RandomOff(lightid) = RandomOff(lightid, 0.5) # 50-50 as default

struct Switch
  text::String
  color::String
	icon::String
  lights::Vector{LightSetting}
end

function handle(s::Switch)
  for ls in s.lights
    handle(ls)
  end
end

struct LoopingSwitch
  sequence::Vector{Switch}
end

struct Page
  switches::Vector{LoopingSwitch}
end
