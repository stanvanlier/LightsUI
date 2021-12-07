module RFCatcher

using Libdl

# read RF433 signal 

const rflib = dlopen("c/rf_receiver.so")

const Cstatus = dlsym(rflib, :status)

export rfstatus
rfstatus() = ccall(Cstatus, Cint, ())

export sample_rfsignals
function sample_rfsignals(seconds)
  endtime = time_ns() + 1_000_000_000*seconds
  highlows = Vector{Int}()
  n_in_a_row = Vector{Int}()
  val = 0
  valstart = time_ns()
  n = 0
  while true
    n+=1
    if rfstatus() != val
      now = time_ns()
      push!(highlows, now-valstart)
      push!(n_in_a_row, n)
      val = 1-val
      valstart = now
      n=0
      now > endtime && break
    end
  end
  highlows, n_in_a_row
end

export sample_rfsignals_allocated
function sample_rfsignals_allocated(sample_size=30_000_000) # default is +- 10s
    samples = falses(sample_size) 
    times = Vector{UInt64}(undef, sample_size)
    starttime=time()
    for i in 1:sample_size
      samples[i] = rfstatus()
      times[i] = time_ns()
    end
    println("sampled for ",time()-starttime)
    times .-= times[1]

    change_times = Vector{UInt64}()
    change_vals = Vector{Bool}()
   	val_durations = Vector{Int}()
    val_time = 0
    n_in_a_row = Vector{Int}()
    n = 0
    for i in 2:sample_size
      val_time += times[i]-times[i-1]
      n += 1
      if samples[i] != samples[i-1]
        push!(change_times, times[i])
        push!(change_vals, samples[i])
        push!(val_durations, val_time)
        val_time = 0
        push!(n_in_a_row, n)
        n = 0
      end
    end
	change_times, change_vals, val_durations, n_in_a_row
end

export split_into_signals
function split_into_signals(val_durations, threshold=5_000_000)
    splitpositions = collect(1:length(val_durations))[val_durations.>threshold]
    return [val_durations[splitpositions[i]+1:splitpositions[i+1]] for i in 1:length(splitpositions)-1]
end

export split_into_signals_with_vals
function split_into_signals_with_vals(val_durations, vals, ;threshold=5_000_000)
    splitpositions = collect(1:length(val_durations))[val_durations.>threshold]
    return ([val_durations[splitpositions[i]+1:splitpositions[i+1]-1] for i in 1:length(splitpositions)-1],
            [vals[splitpositions[i]+1:splitpositions[i+1]-1] for i in 1:length(splitpositions)-1])
end

using UnicodePlots

export plot_highlows
plot_highlows(s, width=180) = display(lineplot(cumsum(s), repeat([1,0],length(s/2))[1:length(s)], width=width, height=6))

function countmap(v)
    u = unique(v)
    collect((i=>count(x->x==i,v) for i in u))
end

pairmax(c) = c[argmax([last(x) for x in c])]

using Statistics
using DelimitedFiles

export save_signal
function save_signal(loc, ;sample_duration=30_000_000, split_threshold=15_000_000)
    println("press $loc !!")
    change_times, change_vals, val_durations, n_in_a_row = sample_rfsignals_allocated(sample_duration)
    ss, vv = split_into_signals_with_vals(val_durations, change_vals, threshold=split_threshold)
    println("Raw signals")
    foreach(ss, vv) do s, v
        display(lineplot(cumsum(s), v, width=180, height=6))
    end
    println("Signal lengths:")
    try
        display(histogram(map(length, vv)))
    catch e
        println(e, typeof(e))
    end
    lens = map(length, ss)
    @show lens
    counts = countmap(lens)
    @show counts
    picked_len = first(pairmax([c for c in counts if first(c) > 10]))
    println("Best signal len: ", picked_len)
    ss_picked = filter(x->length(x) == picked_len, ss)
    vv_picked = filter(x->length(x) == picked_len, vv)

    println("Parsed signals")
    foreach(ss_picked, vv_picked) do s, v
        display(lineplot(cumsum(s), v, width=180, height=6))
    end
    ss_picked_cumsum = map(cumsum, ss_picked)
    ss_picked = hcat(ss_picked...)
    mc = median(cumsum(ss_picked, dims=1),dims=2)[:,1]
    # cm is just for coparrison of losses
    cm = cumsum(median(ss_picked, dims=(2))[:,1])
    mclosses = [convert(Int,round(mean(abs.(s .- mc)))) for s in ss_picked_cumsum]
    cmlosses = [convert(Int,round(mean(abs.(s .- cm)))) for s in ss_picked_cumsum]
    @show mean(mclosses) median(mclosses) minimum(mclosses) maximum(mclosses)
    @show mean(cmlosses) median(cmlosses) minimum(cmlosses) maximum(cmlosses)
    try
        println("Median signal")
        display(lineplot(mc, vv_picked[1] , width=180, height=6))
        display(lineplot(cm, vv_picked[1] , width=180, height=6))
    catch e
        println(e, typeof(e))
    end
    mc = convert(Vector{Int}, round.(mc)) 
    writedlm(loc, mc)
    println("$loc saved")
    return
end

end #module

using .RFCatcher

#while true
#    print("Give a name for the new signal to save:")
#    name = readline()
#    pathname = "signals/$name.light"
#    mkpath(pathname)
#    while true
#        print("[ON/off]?")
#        w = lowercase(readline()) != "off" ? "on" : "off"
#        try
#            save_signal("$pathname/$w.txt")
#        catch e
#            println("failed... ", e, typeof(e))
#        end
#        print("another with name $name?[y/N]")
#        resp = readline()
#        (resp != "" && lowercase(resp[1]) == 'y') || break
#    end
#end

using LightsAPI
using DelimitedFiles

while true
    print("Give a name for the new signal to save:")
    name = readline()
    pathname = "signals/$name.light"
    mkpath(pathname)
    while true
        print("[ON/off]?")
        w = lowercase(readline()) != "off" ? "on" : "off"
        try
            loc="$pathname/$w.txt"
            while true
              println("press $loc once now!!")
              sample_duration=10_000_000
              change_times, change_vals, val_durations, n_in_a_row = sample_rfsignals_allocated(sample_duration)
              println("Catched $(length(change_times)) signals, now change cable to test, and turn light back on or off [press enter]")
              readline()
              LightsAPI.send_signal(change_times)
              println("did it work? [Y/n]")
              resp = readline()
              (resp != "" && lowercase(resp[1]) == 'y') || (println("try again"); continue)
              writedlm(loc, change_times)
              println("$loc saved")
              break
            end
        catch e
            println("failed... ", e, typeof(e))
        end
        print("another with name $name?[y/N]")
        resp = readline()
        (resp != "" && lowercase(resp[1]) == 'y') || break
    end
end
