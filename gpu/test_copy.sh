alias be=basys2_epp

function gpu_wait() {
  while [ $(be -g f) -gt 0 ]; do
    echo "waiting for GPU..."
    sleep 0.5
  done
}


function reset_registers() {
  be -p 0 0
  be -p 1 0
  be -p 2 0
  be -p 3 0
  be -p 4 0
  be -p 5 0
  be -p 6 0
  be -p 7 0
  be -p 8 0
  be -p 9 0
  be -p a 0
  be -p b 0
}

function simple_copy_test() {
  be -p 8 10
  be -p a 10
  be -p d 1

  be -p 0 10
  be -p 2 10
  be -p d 1

  be -p 4 0
  be -p 6 0
  be -p 0 40
  be -p 2 40
  be -p 8 20
  be -p a 20
  be -p c 1

  gpu_wait
}

function copy_rectangle() {
  be -p 4 32
  be -p 6 0
  be -p 0 0
  be -p 2 0
  be -p 8 ff
  be -p a ff
  be -p c 1
  gpu_wait
}

function draw_rectangle() {
  be -p 0 2
  be -p 2 2
  be -p 8 3c
  be -p 9 1
  be -p a c4
  be -p d 1
}

reset_registers
draw_rectangle

