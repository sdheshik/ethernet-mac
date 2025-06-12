onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib vio_reset_opt

do {wave.do}

view wave
view structure
view signals

do {vio_reset.udo}

run -all

quit -force
