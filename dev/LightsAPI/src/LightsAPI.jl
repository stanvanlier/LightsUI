module LightsAPI
__precompile__(false)
using DelimitedFiles
include("c_interface.jl")
#using Threads
#using .GPIO

greet() = print("LightsAPI greets")

struct LightState
  name::String
  on_signal::Vector{UInt}
  on_signal_diration::Uint
  off_signal::Vector{UInt}
  off_signal_diration::Uint
  total_intensity_seconds::Float64
  curr_intensity::Ref{Float64}
  curr_direction::Ref{Float64} # 1 = down, 0 = up
  on::Ref{Bool}
end

const MILLI_SECOND = UInt(1_000_000)
function LightState(name, total_intensity_seconds=4.0)
  return LightState(name,
                    isfile("$(dirname(@__DIR__))/signals/$name.light/on.txt") ? vec(readdlm("$(dirname(@__DIR__))/signals/$name.light/on.txt", UInt)) : Vector{UInt}() ,
                    1000MILLI_SECOND,
                    isfile("$(dirname(@__DIR__))/signals/$name.light/off.txt") ? vec(readdlm("$(dirname(@__DIR__))/signals/$name.light/off.txt", UInt)) : Vector{UInt}() ,
                    1500MILLI_SECOND,
                    total_intensity_seconds, #TODO total light change time
                    #total_intensity_seconds, #TODO inintal light state
                    0., #TODO inintal light state
                    1., # 1. = down, 0. = up
                    false)
end

# not used?
ison(s::LightState) = s.on[]
isoff(s::LightState) = !s.on[]
intensity(s::LightState) = s.curr_intensity
direction(s::LightState) = s.curr_direction

# init all saved lights
const lightstates = let
  s = Dict{Symbol,LightState}()
  for d in readdir("$(dirname(@__DIR__))/signals")
    if endswith(d, ".light")
      name = split(d,'.')[1]
      s[Symbol(name)] = LightState(name)
    end
  end
  s
end

# interface without references
# not used?
ison(s::Symbol) = ison(lightstates[s])
isoff(s::Symbol) = isoff(lightstates[s])
intensity(s::Symbol) = intensity(lightstates[s])
direction(s::Symbol) = direction(lightstates[s])

abstract type AbstractChange end

struct On <: AbstractChange end
struct Off <: AbstractChange end
struct IntensityStart <: AbstractChange 
  starttime::Ref{Float64}
end
struct IntensityStop <: AbstractChange 
  starttime::Ref{Float64}
end
struct Reset <: AbstractChange end

struct ChangeSpec{T<:AbstractChange}
  lightstate::LightState
  change::T
end

function send_signal(s::Vector{UInt})
    send_signal(s, 10_000MILLI_SECOND)
end
function send_signal(s::Vector{UInt}, for_duration::UInt)
  i = 0
  starttime = time_ns()
  high = false # this works when used directly with the change_times variable
  #high = true
  for t in s
    if high
      rfhigh()
    else
      rflow()
    end
    high = !high
    if time_ns() - starttime > for_duration
        break
    end
    while time_ns() - starttime < t 
      #println(high)
    end
  end
  #println("signalduration: $(time_ns() - starttime)")
  rflow()
end

function handle(spec::ChangeSpec{On})
  send_signal(spec.lightstate.on_signal, spec.lightstate.on_signal_diration)
  spec.lightstate.on[] = true
end
function handle(spec::ChangeSpec{Off})
  send_signal(spec.lightstate.off_signal, spec.lightstate.off_signal_diration)
  # send off signal twice to be sure its off. Not needed anymore since the off sinal is now longer than the on signal
  #send_signal(spec.lightstate.off_signal, spec.lightstate.off_signal_diration)
  spec.lightstate.on[] = false
end
function handle(spec::ChangeSpec{IntensityStart})
  send_signal(spec.lightstate.on_signal, spec.lightstate.on_signal_diration)
  spec.change.starttime[] = time()
  println("Send intensity start")
end

new_intesity(x,p) = abs(mod(x-p,p*2)-p) 
new_direction(x,p) = mod(div(x, p), 2.0)

function handle(spec::ChangeSpec{IntensityStop}) 
  send_signal(spec.lightstate.on_signal, spec.lightstate.on_signal_diration)
  duration = time() - spec.change.starttime[]
  println("Send intensity start")
  l = spec.lightstate
  start_x = l.curr_intensity[] + (l.total_intensity_seconds - l.curr_intensity[])*l.curr_direction[]
  x = start_x+duration
  l.curr_intensity[] = new_intesity(x, l.total_intensity_seconds)
  # derenction flips every time you configure
  l.curr_direction[] = 1-new_direction(x, l.total_intensity_seconds)
end
function handle(spec::ChangeSpec{Reset})
  spec.lightstate.curr_intensity[] = spec.lightstate.total_intensity_seconds
  spec.lightstate.curr_direction[] = 1
  spec.lightstate.on[] = false
end

# Seperate thread to send signals
const rf_send_queue = Channel{ChangeSpec}(Inf)
const rf_send_task = Threads.@spawn begin
  try
    #println("queue sender started")
    for spec in rf_send_queue
      println("Got changespec to send: ", typeof(spec))
      handle(spec)
    end
  catch e
    println(e)
  end
end


#TODO add a minimal sleep time
function waitfor(i,curr_i,total_i,curr_d) 
    distance = (curr_d*2-1)*(curr_i-i)
    if distance < 1 # or 0?
        distance = 2*abs(total_i*(1-curr_d) - curr_i) - distance
    end
    distance
end

on(l::LightState) = l.on[] || put!(rf_send_queue, ChangeSpec(l, On()))
off(l::LightState) = put!(rf_send_queue, ChangeSpec(l, Off())) 
function set_intensity(l::LightState, intensity::Float64) 
  # make sure lamp is turned on
  on(l)
  intensity = l.total_intensity_seconds*intensity
  sleeptime = waitfor(intensity, l.curr_intensity[], l.total_intensity_seconds,l.curr_direction[])
  if sleeptime > 0.5  # some threshold, since this light difference is probably
                      # not noticable and will may be to fast for the lights to
                      # understand.
    starttime_catch = Ref{Float64}()
    put!(rf_send_queue, ChangeSpec(l, IntensityStart(starttime_catch)))
    sleep(sleeptime)
    put!(rf_send_queue, ChangeSpec(l, IntensityStop(starttime_catch)))
  end
  nothing
end

reset(l::LightState) = put!(rf_send_queue, ChangeSpec(l, Reset()))

# interface without references
on(l::Symbol) = on(lightstates[l])
off(l::Symbol) = off(lightstates[l])
set_intensity(l::Symbol, i::Float64) = set_intensity(lightstates[l], i)
reset(l::Symbol) = reset(lightstates[l])

end # module
