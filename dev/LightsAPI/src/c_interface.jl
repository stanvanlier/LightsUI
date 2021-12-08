#module GPIO
using Libdl

export rfhigh, rflow, screenon, screenoff

# RF433 signal controll 

const rflib = dlopen("$(@__DIR__)/c/rf_sender.so")

const Chigh = dlsym(rflib, :high)
const Clow = dlsym(rflib, :low)

rfhigh() = ccall(Chigh, Cvoid, ())
rflow() = ccall(Clow, Cvoid, ())

# screen backlight controll 

const screenlib = dlopen("$(@__DIR__)/c/screen_backlight.so")

const Cscreenon = dlsym(screenlib, :screenon)
const Cscreenoff = dlsym(screenlib, :screenoff)

screenon() = ccall(Cscreenon, Cvoid, ())
screenoff() = ccall(Cscreenoff, Cvoid, ())

#end
