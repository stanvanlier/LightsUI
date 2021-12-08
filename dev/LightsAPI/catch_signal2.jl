#module RFCatcher

using Libdl

# read RF433 signal 

const rflib = dlopen("c/rf_receiver.so")

const Cstatus = dlsym(rflib, :status)

export rfstatus
rfstatus() = ccall(Cstatus, Cint, ())

export sample_rfsignals_allocated
function sample_rfsignals_allocated(loc, sample_size=30_000_000) # default is +- 10s
    samples = falses(sample_size) 
    times = Vector{UInt64}(undef, sample_size)
    print("3 "); sleep(1)
    print("2 "); sleep(1)
    print("1 "); sleep(1)
    print("Start pressing HARD!!!......"); sleep(0.1)
    starttime=time()
    for i in 1:sample_size
      samples[i] = rfstatus()
      times[i] = time_ns()
    end
    print(" ..... Stop. Sampled for ",time()-starttime, " seconds. ")
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
    println("Chatched $(length(change_times)) flips.")
    if change_vals[1] == 0
        change_times = change_times[2:end]
        println("!Stripped first flip 1->0")
    end
    writedlm(loc, change_times)
    println("saved: $loc")
#    return change_times, change_vals, val_durations, n_in_a_row
end

const MILLI_SECOND = UInt(1_000_000)

function check(name)
    pathname = "signals/$name.light"
    onretry_sample_duration = sample_durations["on"]
    offretry_sample_duration = sample_durations["off"]
    on_send_duration = 1000MILLI_SECOND
    off_send_duration = 1500MILLI_SECOND

    #for w in ["on", "off"]
    while true
        print("Change cable back to sending (to orange wire). [done? PRESS ENTER]"); readline()
        print("Turn light off. [PRESS ENTER]"); readline()

        onloc="$pathname/on.txt"
        onsignal = vec(readdlm(onloc, UInt)) : Vector{UInt}()
        LightsAPI.send_signal(onsignal, on_send_duration)
        print("Did the light go on? [Y/n]"); 
        resp = readline()
        if resp != "" && lowercase(resp[1]) == 'n'
            println("Going to catch $name on again")
            print("Now change cable to receive (to purple wire). [done? PRESS ENTER]"); readline()
            onretry_sample_duration += 1_000_000
            on_send_duration += 1_000_000
            sample_rfsignals_allocated(onloc, onretry_sample_duration) 
            continue
        end

        offloc="$pathname/off.txt"
        offsignal = vec(readdlm(offloc, UInt)) : Vector{UInt}()
        LightsAPI.send_signal(offsignal, off_send_duration)
        print("Did the light go off? [Y/n]"); 
        resp = readline()
        if resp != "" && lowercase(resp[1]) == 'n'
            println("Going to catch $name off again")
            print("Now change cable to receive (to purple wire). [done? PRESS ENTER]"); readline()
            offretry_sample_duration += 1_000_000
            off_send_duration += 1_000_000
            sample_rfsignals_allocated(offloc, offretry_sample_duration) 
            continue
        end
        break
    end
    
    
end

using LightsAPI
using DelimitedFiles

const sample_durations = Dict(["on" => 15_000_000, 
                               "off" => 20_000_000])

print("Change cable to receive (to purple wire). [done? PRESS ENTER]"); readline()
while true
    print("Give a name for the new signal to save:")
    name = readline()
    pathname = "signals/$name.light"
    mkpath(pathname)
    while true
        for w in ["on", "off"]
            loc="$pathname/$w.txt"
            println("Catching $name $w. [Ready? PRESS ENTER]"); readline()
            sample_rfsignals_allocated(loc, sample_durations[w]) 
        end
    end
    println("Save another? [Y/n]"); 
    resp = readline()
    if resp != "" && lowercase(resp[1]) == 'n'
        break 
    end
end

for d in readdir("signals")
    if endswith(d, ".light")
        name = split(d,'.')[1]
        print("Check if $name works? [Y/n]"); resp = readline()
        if resp != "" && lowercase(resp[1]) == 'n'
           continue 
        end
        check($name)
    end
end

