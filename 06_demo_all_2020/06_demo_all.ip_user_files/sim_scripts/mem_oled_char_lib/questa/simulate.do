onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib mem_oled_char_lib_opt

do {wave.do}

view wave
view structure
view signals

do {mem_oled_char_lib.udo}

run -all

quit -force
