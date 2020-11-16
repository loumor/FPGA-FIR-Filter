onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+mem_oled_char_lib -L xpm -L blk_mem_gen_v8_4_4 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.mem_oled_char_lib xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {mem_oled_char_lib.udo}

run -all

endsim

quit -force
