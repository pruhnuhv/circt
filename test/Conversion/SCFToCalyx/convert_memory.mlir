// RUN: circt-opt %s --lower-scf-to-calyx -split-input-file | FileCheck %s

// CHECK:      module  {
// CHECK-NEXT:   calyx.program "main" {
// CHECK-NEXT:     calyx.component @main(%clk: i1 {clk}, %reset: i1 {reset}, %go: i1 {go}) -> (%done: i1 {done}) {
// CHECK-NEXT:       %true = hw.constant true
// CHECK-NEXT:       %c0_i32 = hw.constant 0 : i32
// CHECK-NEXT:       %c1_i32 = hw.constant 1 : i32
// CHECK-NEXT:       %c64_i32 = hw.constant 64 : i32
// CHECK-NEXT:       %std_slice_2.in, %std_slice_2.out = calyx.std_slice "std_slice_2" : i32, i6
// CHECK-NEXT:       %std_slice_1.in, %std_slice_1.out = calyx.std_slice "std_slice_1" : i32, i6
// CHECK-NEXT:       %std_slice_0.in, %std_slice_0.out = calyx.std_slice "std_slice_0" : i32, i6
// CHECK-NEXT:       %std_add_0.left, %std_add_0.right, %std_add_0.out = calyx.std_add "std_add_0" : i32, i32, i32
// CHECK-NEXT:       %std_lt_0.left, %std_lt_0.right, %std_lt_0.out = calyx.std_lt "std_lt_0" : i32, i32, i1
// CHECK-NEXT:       %mem_1.addr0, %mem_1.write_data, %mem_1.write_en, %mem_1.clk, %mem_1.read_data, %mem_1.done = calyx.memory "mem_1"<[64] x 32> [6] : i6, i32, i1, i1, i32, i1
// CHECK-NEXT:       %mem_0.addr0, %mem_0.write_data, %mem_0.write_en, %mem_0.clk, %mem_0.read_data, %mem_0.done = calyx.memory "mem_0"<[64] x 32> [6] : i6, i32, i1, i1, i32, i1
// CHECK-NEXT:       %while_0_arg0_reg.in, %while_0_arg0_reg.write_en, %while_0_arg0_reg.clk, %while_0_arg0_reg.reset, %while_0_arg0_reg.out, %while_0_arg0_reg.done = calyx.register "while_0_arg0_reg" : i32, i1, i1, i1, i32, i1
// CHECK-NEXT:       calyx.wires  {
// CHECK-NEXT:         calyx.group @assign_while_0_init  {
// CHECK-NEXT:           calyx.assign %while_0_arg0_reg.in = %c0_i32 : i32
// CHECK-NEXT:           calyx.assign %while_0_arg0_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.group_done %while_0_arg0_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.comb_group @bb0_0  {
// CHECK-NEXT:           calyx.assign %std_lt_0.left = %while_0_arg0_reg.out : i32
// CHECK-NEXT:           calyx.assign %std_lt_0.right = %c64_i32 : i32
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.group @bb0_2  {
// CHECK-NEXT:           calyx.assign %std_slice_1.in = %while_0_arg0_reg.out : i32
// CHECK-NEXT:           calyx.assign %std_slice_0.in = %while_0_arg0_reg.out : i32
// CHECK-NEXT:           calyx.assign %mem_1.addr0 = %std_slice_1.out : i6
// CHECK-NEXT:           calyx.assign %mem_1.write_data = %mem_0.read_data : i32
// CHECK-NEXT:           calyx.assign %mem_1.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %mem_0.addr0 = %std_slice_0.out : i6
// CHECK-NEXT:           calyx.group_done %mem_1.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.group @assign_while_0_latch  {
// CHECK-NEXT:           calyx.assign %while_0_arg0_reg.in = %std_add_0.out : i32
// CHECK-NEXT:           calyx.assign %while_0_arg0_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_add_0.left = %while_0_arg0_reg.out : i32
// CHECK-NEXT:           calyx.assign %std_add_0.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.group_done %while_0_arg0_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:       calyx.control  {
// CHECK-NEXT:         calyx.seq  {
// CHECK-NEXT:           calyx.enable @assign_while_0_init
// CHECK-NEXT:           calyx.while %std_lt_0.out with @bb0_0  {
// CHECK-NEXT:             calyx.seq  {
// CHECK-NEXT:               calyx.enable @bb0_2
// CHECK-NEXT:               calyx.enable @assign_while_0_latch
// CHECK-NEXT:             }
// CHECK-NEXT:           }
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: }
module {
  func @main() {
    %c0 = constant 0 : index
    %c1 = constant 1 : index
    %c64 = constant 64 : index
    %0 = memref.alloc() : memref<64xi32>
    %1 = memref.alloc() : memref<64xi32>
    scf.while(%arg0 = %c0) : (index) -> (index) {
      %cond = cmpi ult, %arg0, %c64 : index
      scf.condition(%cond) %arg0 : index
    } do {
    ^bb0(%arg1: index):
      %v = memref.load %0[%arg1] : memref<64xi32>
      memref.store %v, %1[%arg1] : memref<64xi32>
      %inc = addi %arg1, %c1 : index
      scf.yield %inc : index
    }
    return
  }
}

// -----

// Test combinational value used across sequential group boundary. This requires
// that any referenced combinational assignments are re-applied in each
// sequential group.

// CHECK:      module  {
// CHECK-NEXT:   calyx.program "main" {
// CHECK-NEXT:     calyx.component @main(%in0: i32, %clk: i1 {clk}, %reset: i1 {reset}, %go: i1 {go}) -> (%out0: i32, %done: i1 {done}) {
// CHECK-NEXT:       %c1_i32 = hw.constant 1 : i32
// CHECK-NEXT:       %c0_i32 = hw.constant 0 : i32
// CHECK-NEXT:       %true = hw.constant true
// CHECK-NEXT:       %std_slice_0.in, %std_slice_0.out = calyx.std_slice "std_slice_0" : i32, i6
// CHECK-NEXT:       %std_add_1.left, %std_add_1.right, %std_add_1.out = calyx.std_add "std_add_1" : i32, i32, i32
// CHECK-NEXT:       %std_add_0.left, %std_add_0.right, %std_add_0.out = calyx.std_add "std_add_0" : i32, i32, i32
// CHECK-NEXT:       %mem_0.addr0, %mem_0.write_data, %mem_0.write_en, %mem_0.clk, %mem_0.read_data, %mem_0.done = calyx.memory "mem_0"<[64] x 32> [6] : i6, i32, i1, i1, i32, i1
// CHECK-NEXT:       %ret_arg0_reg.in, %ret_arg0_reg.write_en, %ret_arg0_reg.clk, %ret_arg0_reg.reset, %ret_arg0_reg.out, %ret_arg0_reg.done = calyx.register "ret_arg0_reg" : i32, i1, i1, i1, i32, i1
// CHECK-NEXT:       calyx.wires  {
// CHECK-NEXT:         calyx.assign %out0 = %ret_arg0_reg.out : i32
// CHECK-NEXT:         calyx.group @bb0_1  {
// CHECK-NEXT:           calyx.assign %std_slice_0.in = %c0_i32 : i32
// CHECK-NEXT:           calyx.assign %mem_0.addr0 = %std_slice_0.out : i6
// CHECK-NEXT:           calyx.assign %mem_0.write_data = %std_add_0.out : i32
// CHECK-NEXT:           calyx.assign %mem_0.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_add_0.left = %in0 : i32
// CHECK-NEXT:           calyx.assign %std_add_0.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.group_done %mem_0.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.group @ret_assign_0  {
// CHECK-NEXT:           calyx.assign %ret_arg0_reg.in = %std_add_1.out : i32
// CHECK-NEXT:           calyx.assign %ret_arg0_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_add_1.left = %std_add_0.out : i32
// CHECK-NEXT:           calyx.assign %std_add_0.left = %in0 : i32
// CHECK-NEXT:           calyx.assign %std_add_0.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.assign %std_add_1.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.group_done %ret_arg0_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:       calyx.control  {
// CHECK-NEXT:         calyx.seq  {
// CHECK-NEXT:           calyx.enable @bb0_1
// CHECK-NEXT:           calyx.enable @ret_assign_0
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: }
module {
  func @main(%arg0 : i32) -> i32 {
    %0 = memref.alloc() : memref<64xi32>
    %c0 = constant 0 : index
    %c1 = constant 1 : i32
    %1 = addi %arg0, %c1 : i32
    memref.store %1, %0[%c0] : memref<64xi32>
    %3 = addi %1, %c1 : i32
    return %3 : i32
  }
}

// -----

// CHECK:      module  {
// CHECK-NEXT:   calyx.program "main" {
// CHECK-NEXT:     calyx.component @main(%in0: i32, %clk: i1 {clk}, %reset: i1 {reset}, %go: i1 {go}) -> (%out0: i32, %done: i1 {done}) {
// CHECK-NEXT:       %c1_i32 = hw.constant 1 : i32
// CHECK-NEXT:       %c0_i32 = hw.constant 0 : i32
// CHECK-NEXT:       %true = hw.constant true
// CHECK-NEXT:       %std_slice_0.in, %std_slice_0.out = calyx.std_slice "std_slice_0" : i32, i6
// CHECK-NEXT:       %std_add_2.left, %std_add_2.right, %std_add_2.out = calyx.std_add "std_add_2" : i32, i32, i32
// CHECK-NEXT:       %std_add_1.left, %std_add_1.right, %std_add_1.out = calyx.std_add "std_add_1" : i32, i32, i32
// CHECK-NEXT:       %std_add_0.left, %std_add_0.right, %std_add_0.out = calyx.std_add "std_add_0" : i32, i32, i32
// CHECK-NEXT:       %mem_0.addr0, %mem_0.write_data, %mem_0.write_en, %mem_0.clk, %mem_0.read_data, %mem_0.done = calyx.memory "mem_0"<[64] x 32> [6] : i6, i32, i1, i1, i32, i1
// CHECK-NEXT:       %ret_arg0_reg.in, %ret_arg0_reg.write_en, %ret_arg0_reg.clk, %ret_arg0_reg.reset, %ret_arg0_reg.out, %ret_arg0_reg.done = calyx.register "ret_arg0_reg" : i32, i1, i1, i1, i32, i1
// CHECK-NEXT:       calyx.wires  {
// CHECK-NEXT:         calyx.assign %out0 = %ret_arg0_reg.out : i32
// CHECK-NEXT:         calyx.group @bb0_2  {
// CHECK-NEXT:           calyx.assign %std_slice_0.in = %c0_i32 : i32
// CHECK-NEXT:           calyx.assign %mem_0.addr0 = %std_slice_0.out : i6
// CHECK-NEXT:           calyx.assign %mem_0.write_data = %std_add_0.out : i32
// CHECK-NEXT:           calyx.assign %mem_0.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_add_0.left = %in0 : i32
// CHECK-NEXT:           calyx.assign %std_add_0.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.group_done %mem_0.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.group @ret_assign_0  {
// CHECK-NEXT:           calyx.assign %ret_arg0_reg.in = %std_add_2.out : i32
// CHECK-NEXT:           calyx.assign %ret_arg0_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_add_2.left = %std_add_1.out : i32
// CHECK-NEXT:           calyx.assign %std_add_1.left = %std_add_0.out : i32
// CHECK-NEXT:           calyx.assign %std_add_0.left = %in0 : i32
// CHECK-NEXT:           calyx.assign %std_add_0.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.assign %std_add_1.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.assign %std_add_2.right = %c1_i32 : i32
// CHECK-NEXT:           calyx.group_done %ret_arg0_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:       calyx.control  {
// CHECK-NEXT:         calyx.seq  {
// CHECK-NEXT:           calyx.enable @bb0_2
// CHECK-NEXT:           calyx.enable @ret_assign_0
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: }
module {
  func @main(%arg0 : i32) -> i32 {
    %0 = memref.alloc() : memref<64xi32>
    %c0 = constant 0 : index
    %c1 = constant 1 : i32
    %1 = addi %arg0, %c1 : i32
    %2 = addi %1, %c1 : i32
    memref.store %1, %0[%c0] : memref<64xi32>
    %3 = addi %2, %c1 : i32
    return %3 : i32
  }
}

// -----
// Test multiple reads from the same memory (structural hazard).

// CHECK:      module  {
// CHECK-NEXT:   calyx.program "main"  {
// CHECK-NEXT:     calyx.component @main(%in0: i6, %clk: i1 {clk}, %reset: i1 {reset}, %go: i1 {go}) -> (%out0: i32, %done: i1 {done}) {
// CHECK-NEXT:       %c1_i32 = hw.constant 1 : i32
// CHECK-NEXT:       %true = hw.constant true
// CHECK-NEXT:       %std_slice_1.in, %std_slice_1.out = calyx.std_slice "std_slice_1" : i32, i6
// CHECK-NEXT:       %std_slice_0.in, %std_slice_0.out = calyx.std_slice "std_slice_0" : i32, i6
// CHECK-NEXT:       %std_add_0.left, %std_add_0.right, %std_add_0.out = calyx.std_add "std_add_0" : i32, i32, i32
// CHECK-NEXT:       %load_1_reg.in, %load_1_reg.write_en, %load_1_reg.clk, %load_1_reg.reset, %load_1_reg.out, %load_1_reg.done = calyx.register "load_1_reg" : i32, i1, i1, i1, i32, i1
// CHECK-NEXT:       %load_0_reg.in, %load_0_reg.write_en, %load_0_reg.clk, %load_0_reg.reset, %load_0_reg.out, %load_0_reg.done = calyx.register "load_0_reg" : i32, i1, i1, i1, i32, i1
// CHECK-NEXT:       %std_pad_0.in, %std_pad_0.out = calyx.std_pad "std_pad_0" : i6, i32
// CHECK-NEXT:       %mem_0.addr0, %mem_0.write_data, %mem_0.write_en, %mem_0.clk, %mem_0.read_data, %mem_0.done = calyx.memory "mem_0"<[64] x 32> [6] : i6, i32, i1, i1, i32, i1
// CHECK-NEXT:       %ret_arg0_reg.in, %ret_arg0_reg.write_en, %ret_arg0_reg.clk, %ret_arg0_reg.reset, %ret_arg0_reg.out, %ret_arg0_reg.done = calyx.register "ret_arg0_reg" : i32, i1, i1, i1, i32, i1
// CHECK-NEXT:       calyx.wires  {
// CHECK-NEXT:         calyx.assign %out0 = %ret_arg0_reg.out : i32
// CHECK-NEXT:         calyx.group @bb0_1  {
// CHECK-NEXT:           calyx.assign %std_slice_1.in = %std_pad_0.out : i32
// CHECK-NEXT:           calyx.assign %mem_0.addr0 = %std_slice_1.out : i6
// CHECK-NEXT:           calyx.assign %load_0_reg.in = %mem_0.read_data : i32
// CHECK-NEXT:           calyx.assign %load_0_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_pad_0.in = %in0 : i6
// CHECK-NEXT:           calyx.group_done %load_0_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.group @bb0_2  {
// CHECK-NEXT:           calyx.assign %std_slice_0.in = %c1_i32 : i32
// CHECK-NEXT:           calyx.assign %mem_0.addr0 = %std_slice_0.out : i6
// CHECK-NEXT:           calyx.assign %load_1_reg.in = %mem_0.read_data : i32
// CHECK-NEXT:           calyx.assign %load_1_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.group_done %load_1_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:         calyx.group @ret_assign_0  {
// CHECK-NEXT:           calyx.assign %ret_arg0_reg.in = %std_add_0.out : i32
// CHECK-NEXT:           calyx.assign %ret_arg0_reg.write_en = %true : i1
// CHECK-NEXT:           calyx.assign %std_add_0.left = %load_0_reg.out : i32
// CHECK-NEXT:           calyx.assign %std_add_0.right = %load_1_reg.out : i32
// CHECK-NEXT:           calyx.group_done %ret_arg0_reg.done : i1
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:       calyx.control  {
// CHECK-NEXT:         calyx.seq  {
// CHECK-NEXT:           calyx.enable @bb0_1
// CHECK-NEXT:           calyx.enable @bb0_2
// CHECK-NEXT:           calyx.enable @ret_assign_0
// CHECK-NEXT:         }
// CHECK-NEXT:       }
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: }
module {
  func @main(%arg0 : i6) -> i32 {
    %0 = memref.alloc() : memref<64xi32>
    %c1 = constant 1 : index
    %arg0_idx =  index_cast %arg0 : i6 to index
    %1 = memref.load %0[%arg0_idx] : memref<64xi32>
    %2 = memref.load %0[%c1] : memref<64xi32>
    %3 = addi %1, %2 : i32
    return %3 : i32
  }
}