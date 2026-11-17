// ====================================================================
// VERIFICATION OF FIFO USING UVM
// ====================================================================

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

// --------------------------------------------------------------------
// 0. Interface Definition (with Parameters)
// --------------------------------------------------------------------
interface fifo_if #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input logic clk
);
    logic                  reset = 1'b1;
    logic                  push  = 1'b0;
    logic                  pop   = 1'b0;
    logic [DATA_WIDTH-1:0] wdata = '0;
    logic [DATA_WIDTH-1:0] rdata;
    logic [ADDR_WIDTH-1:0] wptr;
    logic [ADDR_WIDTH-1:0] rptr;
    logic                  full;
    logic                  empty;

    // Driver Clocking Block
    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output reset;
        output push;
        output pop;
        output wdata;
    endclocking

    // Monitor Clocking Block
    clocking mon_cb @(posedge clk);
        default input #1step;
        input reset;
        input push;
        input pop;
        input wdata;
        input rdata;
        input wptr;
        input rptr;
        input full;
        input empty;
    endclocking

    modport drv_mp(clocking drv_cb, input clk);
    modport mon_mp(clocking mon_cb, input clk);

endinterface

typedef virtual fifo_if #(4, 8) v_fifo_if;

// --------------------------------------------------------------------
// 1. Sequence Item (Transaction)
// --------------------------------------------------------------------
class fifo_seq_item extends uvm_sequence_item;

    rand logic       reset;
    rand logic       push;
    rand logic       pop;
    rand logic [7:0] wdata;

    // Observed / Status Signals
    logic      [7:0] rdata;
    logic      [3:0] wptr;
    logic      [3:0] rptr;
    logic            full;
    logic            empty;

    `uvm_object_utils_begin(fifo_seq_item)
        `uvm_field_int(reset, UVM_DEFAULT)
        `uvm_field_int(push,  UVM_DEFAULT)
        `uvm_field_int(pop,   UVM_DEFAULT)
        `uvm_field_int(wdata, UVM_DEFAULT)
        `uvm_field_int(rdata, UVM_DEFAULT)
        `uvm_field_int(wptr,  UVM_DEFAULT)
        `uvm_field_int(rptr,  UVM_DEFAULT)
        `uvm_field_int(full,  UVM_DEFAULT)
        `uvm_field_int(empty, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "fifo_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "reset=%0b push=%0b pop=%0b wdata=0x%02h rdata=0x%02h wptr=%0d rptr=%0d full=%0b empty=%0b",
            reset, push, pop, wdata, rdata, wptr, rptr, full, empty
        );
    endfunction

endclass

// --------------------------------------------------------------------
// 2. Sequences
// --------------------------------------------------------------------

// 2-1. Reset Sequence
class fifo_reset_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_reset_seq)

    function new(string name = "fifo_reset_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat (3) begin
            fifo_seq_item item = fifo_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                reset == 1'b1;
                push  == 1'b0;
                pop   == 1'b0;
                wdata == 8'h00;
            }) begin
                `uvm_error(get_type_name(), "Reset randomize failed")
            end
            finish_item(item);
        end

        // Release Reset
        begin
            fifo_seq_item item = fifo_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                reset == 1'b0;
                push  == 1'b0;
                pop   == 1'b0;
            }) begin
                `uvm_error(get_type_name(), "Reset release randomize failed")
            end
            finish_item(item);
        end
    endtask
endclass

// 2-2. Write (Push) Sequence: Writes data into FIFO until full
class fifo_write_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_write_seq)

    function new(string name = "fifo_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        // Depth is 16, push 17 times to test full and overflow condition
        repeat (17) begin
            fifo_seq_item item = fifo_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                reset == 1'b0;
                push  == 1'b1;
                pop   == 1'b0;
            }) begin
                `uvm_error(get_type_name(), "Write sequence randomize failed")
            end
            finish_item(item);
        end
    endtask
endclass

// 2-3. Read (Pop) Sequence: Reads data from FIFO until empty
class fifo_read_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_read_seq)

    function new(string name = "fifo_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        // Depth is 16, pop 17 times to test empty and underflow condition
        repeat (17) begin
            fifo_seq_item item = fifo_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                reset == 1'b0;
                push  == 1'b0;
                pop   == 1'b1;
            }) begin
                `uvm_error(get_type_name(), "Read sequence randomize failed")
            end
            finish_item(item);
        end
    endtask
endclass

// 2-4. Random Sequence: Random push and pop operations
class fifo_random_seq extends uvm_sequence #(fifo_seq_item);
    `uvm_object_utils(fifo_random_seq)

    function new(string name = "fifo_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat (1000) begin
            fifo_seq_item item = fifo_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                reset == 1'b0;
                push dist {1'b1 := 60, 1'b0 := 40};
                pop  dist {1'b1 := 60, 1'b0 := 40};
            }) begin
                `uvm_error(get_type_name(), "Random sequence randomize failed")
            end
            finish_item(item);
        end
    endtask
endclass

// --------------------------------------------------------------------
// 3. Driver
// --------------------------------------------------------------------
class fifo_driver extends uvm_driver #(fifo_seq_item);
    `uvm_component_utils(fifo_driver)

    v_fifo_if vif;

    function new(string name = "fifo_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(v_fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Cannot get virtual interface")
        end
    endfunction

    virtual task pre_set();
        vif.drv_cb.reset <= 1'b1;
        vif.drv_cb.push  <= 1'b0;
        vif.drv_cb.pop   <= 1'b0;
        vif.drv_cb.wdata <= 8'h00;
        repeat (2) @(vif.drv_cb);
        vif.drv_cb.reset <= 1'b0;
        @(vif.drv_cb);
    endtask

    task run_phase(uvm_phase phase);
        fifo_seq_item item;
        super.run_phase(phase);

//        pre_set();
        repeat (2) @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(item);

            vif.drv_cb.reset <= item.reset;
            vif.drv_cb.push  <= item.push;
            vif.drv_cb.pop   <= item.pop;
            vif.drv_cb.wdata <= item.wdata;

            `uvm_info(get_type_name(), $sformatf("Drive: reset=%0b, push=%0b, pop=%0b, wdata=0x%02h",
                item.reset, item.push, item.pop, item.wdata), UVM_HIGH)

            @(vif.drv_cb);

            seq_item_port.item_done();
        end
    endtask
endclass

// --------------------------------------------------------------------
// 4. Monitor
// --------------------------------------------------------------------
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    v_fifo_if vif;
    uvm_analysis_port #(fifo_seq_item) ap;

    function new(string name = "fifo_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(v_fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Cannot get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item item;

        forever begin
            @(vif.mon_cb);

            item = fifo_seq_item::type_id::create("item");

            item.reset = vif.mon_cb.reset;
            item.push  = vif.mon_cb.push;
            item.pop   = vif.mon_cb.pop;
            item.wdata = vif.mon_cb.wdata;
            item.rdata = vif.mon_cb.rdata;
            item.wptr  = vif.mon_cb.wptr;
            item.rptr  = vif.mon_cb.rptr;
            item.full  = vif.mon_cb.full;
            item.empty = vif.mon_cb.empty;

            ap.write(item);

            `uvm_info(get_type_name(), {"Monitor: ", item.convert2string()}, UVM_HIGH)
        end
    endtask
endclass

// --------------------------------------------------------------------
// 5. Scoreboard (Golden Model)
// --------------------------------------------------------------------
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_seq_item, fifo_scoreboard) imp;

 
    bit [7:0] expected_queue[$];
    localparam int FIFO_DEPTH = 16;

    int match_count    = 0;
    int mismatch_count = 0;

    function new(string name = "fifo_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void write(fifo_seq_item item);
        bit was_empty;
        bit was_full;

        // 1. Reset or uninitialized check
        if (item.reset === 1'b1 || item.empty === 1'bx || item.full === 1'bx) begin
            expected_queue.delete();
            `uvm_info("SCB_RST", "FIFO Reset/Init detected. Expected queue cleared.", UVM_HIGH)
            return;
        end

        was_empty = (expected_queue.size() == 0);
        was_full  = (expected_queue.size() == FIFO_DEPTH);

        // 2. Empty / Full Flag Verification
        if (item.empty !== was_empty) begin
            `uvm_error("SCB_FLAG_FAIL", $sformatf("[FAIL] EMPTY Flag Mismatch! Expected=%0b, Actual=%0b",
                was_empty, item.empty))
            mismatch_count++;
        end

        if (item.full !== was_full) begin
            `uvm_error("SCB_FLAG_FAIL", $sformatf("[FAIL] FULL Flag Mismatch! Expected=%0b, Actual=%0b",
                was_full, item.full))
            mismatch_count++;
        end

        // 3. Pop / Read Verification
        if (item.pop && !was_empty) begin
            bit [7:0] exp_rdata = expected_queue.pop_front();
            if (item.rdata !== exp_rdata) begin
                `uvm_error("SCB_DATA_CHECK", $sformatf(
                    "[FAIL] DATA MISMATCH! Expected rdata=0x%02h, Actual rdata=0x%02h",
                    exp_rdata, item.rdata
                ))
                mismatch_count++;
            end else begin
                `uvm_info("SCB_DATA_CHECK", $sformatf(
                    "[PASS] DATA MATCH: Expected=0x%02h, Actual=0x%02h",
                    exp_rdata, item.rdata), UVM_LOW)
                match_count++;
            end
        end

        // 4. Push / Write Operation
        if (item.push && !was_full) begin
            expected_queue.push_back(item.wdata);
            `uvm_info("SCB_PUSH", $sformatf(
                "[WRITE] Pushed wdata=0x%02h into expected queue (New size=%0d)",
                item.wdata, expected_queue.size()
            ), UVM_HIGH)
        end
    endfunction

//    function void check_phase(uvm_phase phase);
//        super.check_phase(phase);
//        if (expected_queue.size() != 0) begin
//            `uvm_error("SCB_QUEUE_LEAK", $sformatf("[FAIL] FIFO not completely drained! Remaining items in expected queue = %0d", expected_queue.size()))
//            mismatch_count++;
//        end
//    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "==================================================", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf(" [SCOREBOARD SUMMARY]"), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  - Total Matches    : %0d", match_count), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("  - Total Mismatches : %0d", mismatch_count), UVM_NONE)
        `uvm_info(get_type_name(), "==================================================", UVM_NONE)

        if (mismatch_count == 0 && match_count > 0) begin
            $display("\n");
            $display("  ##################################################");
            $display("  ##                                              ##");
            $display("  ##               >>> TEST PASSED <<<            ##");
            $display("  ##                                              ##");
            $display("  ##################################################\n");
        end else begin
            $display("\n");
            $display("  **************************************************");
            $display("  **                                              **");
            $display("  **               >>> TEST FAILED <<<            ##");
            $display("  **                                              **");
            $display("  **************************************************\n");
            `uvm_error(get_type_name(), "Simulation ended with failures!")
        end
    endfunction
endclass

// --------------------------------------------------------------------
// 6. Coverage Subscriber
// --------------------------------------------------------------------
class fifo_coverage extends uvm_subscriber #(fifo_seq_item);
    `uvm_component_utils(fifo_coverage)

    // Covergroup internal variables for direct sampling
    logic       push;
    logic       pop;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       full;
    logic       empty;

    covergroup fifo_cg;
        option.per_instance = 1;

        cp_push: coverpoint push {
            bins push_act = {1'b1};
            bins push_nop = {1'b0};
        }
        cp_pop: coverpoint pop {
            bins pop_act  = {1'b1};
            bins pop_nop  = {1'b0};
        }
        cp_full: coverpoint full {
            bins is_full     = {1'b1};
            bins is_not_full = {1'b0};
        }
        cp_empty: coverpoint empty {
            bins is_empty     = {1'b1};
            bins is_not_empty = {1'b0};
        }
        cp_wdata: coverpoint wdata iff (push == 1'b1) {
            bins wdata_bins[] = {[0:255]};
        }
        cp_rdata: coverpoint rdata iff (pop == 1'b1) {
            bins rdata_bins[] = {[0:255]};
        }

        // Cross Coverages
        cx_push_pop:  cross cp_push, cp_pop;
        cx_push_full: cross cp_push, cp_full;
        cx_pop_empty: cross cp_pop, cp_empty;
    endgroup

    function new(string name = "fifo_coverage", uvm_component parent = null);
        super.new(name, parent);
        fifo_cg = new();
    endfunction

    virtual function void write(fifo_seq_item t);
        if (t != null && t.reset === 1'b0) begin
            this.push  = t.push;
            this.pop   = t.pop;
            this.wdata = t.wdata;
            this.rdata = t.rdata;
            this.full  = t.full;
            this.empty = t.empty;
            fifo_cg.sample();
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "\n=================================", UVM_NONE)
        `uvm_info("COV", $sformatf("OVERALL FIFO COVERAGE = %0.2f%%", fifo_cg.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cp_push           = %0.2f%%", fifo_cg.cp_push.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cp_pop            = %0.2f%%", fifo_cg.cp_pop.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cp_full           = %0.2f%%", fifo_cg.cp_full.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cp_empty          = %0.2f%%", fifo_cg.cp_empty.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cp_wdata          = %0.2f%%", fifo_cg.cp_wdata.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cp_rdata          = %0.2f%%", fifo_cg.cp_rdata.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cx_push_pop       = %0.2f%%", fifo_cg.cx_push_pop.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cx_push_full      = %0.2f%%", fifo_cg.cx_push_full.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf(" - cx_pop_empty      = %0.2f%%", fifo_cg.cx_pop_empty.get_inst_coverage()), UVM_NONE)
        `uvm_info("COV", "=================================\n", UVM_NONE)
    endfunction
endclass

typedef fifo_coverage coverage;

// --------------------------------------------------------------------
// 7. Agent
// --------------------------------------------------------------------
class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    fifo_driver                  driver;
    fifo_monitor                 monitor;
    uvm_sequencer #(fifo_seq_item) sequencer;

    function new(string name = "fifo_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = fifo_driver::type_id::create("driver", this);
        monitor   = fifo_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(fifo_seq_item)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

// --------------------------------------------------------------------
// 8. Environment
// --------------------------------------------------------------------
class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    fifo_agent      agent;
    fifo_scoreboard scoreboard;
    fifo_coverage   cov;

    function new(string name = "fifo_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = fifo_agent::type_id::create("agent", this);
        scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
        cov        = fifo_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.imp);
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction
endclass

// --------------------------------------------------------------------
// 8. Test
// --------------------------------------------------------------------
class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)

    fifo_env env;

    function new(string name = "fifo_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_reset_seq  rst_seq;
        fifo_write_seq  wr_seq;
        fifo_read_seq   rd_seq;
        fifo_random_seq rnd_seq;

        // [Objection 시작] 테스트 진행 중임을 UVM에 알려 조기 시뮬레이션 종료 방지 (Objection 카운트 +1)
        phase.raise_objection(this);

        // 시퀀스(Sequence) 생성 후 .start(sequencer)를 통해 대상 시퀀서에 전달 및 실행
        `uvm_info(get_type_name(), "=== STEP 1: Reset Sequence ===", UVM_LOW)
        rst_seq = fifo_reset_seq::type_id::create("rst_seq");
        rst_seq.start(env.agent.sequencer); // rst_seq 시나리오를 env.agent.sequencer를 통해 구동

        `uvm_info(get_type_name(), "=== STEP 2: Write Sequence ===", UVM_LOW)
        wr_seq = fifo_write_seq::type_id::create("wr_seq");
        wr_seq.start(env.agent.sequencer); // wr_seq 시나리오를 env.agent.sequencer를 통해 구동

        `uvm_info(get_type_name(), "=== STEP 3: Read Sequence ===", UVM_LOW)
        rd_seq = fifo_read_seq::type_id::create("rd_seq");
        rd_seq.start(env.agent.sequencer); // rd_seq 시나리오를 env.agent.sequencer를 통해 구동

        `uvm_info(get_type_name(), "=== STEP 4: Random Sequence ===", UVM_LOW)
        rnd_seq = fifo_random_seq::type_id::create("rnd_seq");
        rnd_seq.start(env.agent.sequencer); // rnd_seq 시나리오를 env.agent.sequencer를 통해 구동

        // 마지막 트랜잭션이 DUT에 완전히 반영되고 모니터링될 때까지 잠시 대기
        repeat (5) @(env.agent.driver.vif.mon_cb);

        // [Objection 종료] 테스트 완료를 UVM에 알려 run_phase 종료 허용 (Objection 카운트 -1)
        phase.drop_objection(this);
    endtask
endclass

// --------------------------------------------------------------------
// 9. Top-level Testbench Module
// --------------------------------------------------------------------
module tb_fifo;

    logic clk = 1'b0;

    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // Parameterized Interface Instance
    fifo_if #(
        .ADDR_WIDTH(4),
        .DATA_WIDTH(8)
    ) f_if (clk);

    // DUT Instance
    fifo #(
        .WIDTH(4)
    ) DUT (
        .clk  (clk),
        .reset(f_if.reset),
        .push (f_if.push),
        .pop  (f_if.pop),
        .wdata(f_if.wdata),
        .rdata(f_if.rdata),
        .full (f_if.full),
        .empty(f_if.empty)
    );

    // Connect internal pointer wires to interface for monitoring
    assign f_if.wptr = DUT.w_wptr;
    assign f_if.rptr = DUT.w_rptr;
    initial begin 
        $fsdbDumpfile("./build/wave.fsdb");
        $fsdbDumpvars(0, tb_fifo);
    end
    initial begin
        // Store virtual interface handle into uvm_config_db
        uvm_config_db#(v_fifo_if)::set(null, "*", "vif", f_if);

        // Run the UVM Test
        run_test("fifo_test");
    end

endmodule