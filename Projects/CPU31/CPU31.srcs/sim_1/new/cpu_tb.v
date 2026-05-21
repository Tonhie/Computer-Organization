`timescale 1ns / 1ps

module _246tb_ex9_tb;

	// Inputs
	reg clk_in;
	reg reset;
	reg flag;
	// Outputs
	wire [31:0] inst;
	wire [31:0] pc;
	// Instantiate the Unit Under Test (UUT)
	sccomp_dataflow uut (
		.clk_in(clk_in),
		.reset(reset),
		.inst(inst),
		.pc(pc)
	);

	integer file_output;
	integer test_list;
	integer test_idx;
	integer scan_ok;
	integer cycle_cnt;
	integer i;
	integer hex_lines;
	reg [255:0] base_name;
	reg [255:0] test_name;
	reg [511:0] hex_path;
	reg [31:0]  hex_val;
	integer      hex_fd;

	// ======== task: dump final register state ========
	task dump_regs;
		begin
			$fdisplay(file_output, "[%0s]", test_name);
			$fdisplay(file_output, "pc: %h", pc);
			$fdisplay(file_output, "instr: %h", inst);
			$fdisplay(file_output, "regfile0: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[0]);
			$fdisplay(file_output, "regfile1: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[1]);
			$fdisplay(file_output, "regfile2: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[2]);
			$fdisplay(file_output, "regfile3: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[3]);
			$fdisplay(file_output, "regfile4: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[4]);
			$fdisplay(file_output, "regfile5: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[5]);
			$fdisplay(file_output, "regfile6: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[6]);
			$fdisplay(file_output, "regfile7: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[7]);
			$fdisplay(file_output, "regfile8: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[8]);
			$fdisplay(file_output, "regfile9: %h",  _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[9]);
			$fdisplay(file_output, "regfile10: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[10]);
			$fdisplay(file_output, "regfile11: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[11]);
			$fdisplay(file_output, "regfile12: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[12]);
			$fdisplay(file_output, "regfile13: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[13]);
			$fdisplay(file_output, "regfile14: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[14]);
			$fdisplay(file_output, "regfile15: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[15]);
			$fdisplay(file_output, "regfile16: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[16]);
			$fdisplay(file_output, "regfile17: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[17]);
			$fdisplay(file_output, "regfile18: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[18]);
			$fdisplay(file_output, "regfile19: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[19]);
			$fdisplay(file_output, "regfile20: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[20]);
			$fdisplay(file_output, "regfile21: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[21]);
			$fdisplay(file_output, "regfile22: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[22]);
			$fdisplay(file_output, "regfile23: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[23]);
			$fdisplay(file_output, "regfile24: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[24]);
			$fdisplay(file_output, "regfile25: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[25]);
			$fdisplay(file_output, "regfile26: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[26]);
			$fdisplay(file_output, "regfile27: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[27]);
			$fdisplay(file_output, "regfile28: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[28]);
			$fdisplay(file_output, "regfile29: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[29]);
			$fdisplay(file_output, "regfile30: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[30]);
			$fdisplay(file_output, "regfile31: %h", _246tb_ex9_tb.uut.sccpu.cpu_ref.array_reg[31]);
		end
	endtask

	// ======== main test sequence ========
	initial begin
		file_output = $fopen("../../../cpu_results.txt");
		test_list   = $fopen("../../../test_list.txt", "r");

		if (test_list == 0) begin
			$display("ERROR: Cannot open ../../../test_list.txt");
			$finish;
		end

		clk_in = 0;
		reset = 1;
		flag = 0;
		test_idx = 0;

		while (!$feof(test_list)) begin
			// Read: <basename> <test_name>
			scan_ok = $fscanf(test_list, "%s %s", base_name, test_name);
			if (scan_ok < 2) begin
				// Skip empty / malformed lines
				$fgets(base_name, test_list);
			end
			else begin
				$display("=== Test %0d: %0s ===", test_idx, test_name);

				// Build hex path: ../../../hex/<basename>.hex
				hex_path = {"../../../hex/", base_name, ".hex"};

				// Count lines in hex file
				hex_lines = 0;
				hex_fd = $fopen(hex_path, "r");
				if (hex_fd != 0) begin
					while (!$feof(hex_fd)) begin
						scan_ok = $fscanf(hex_fd, "%h", hex_val);
						if (scan_ok == 1)
							hex_lines = hex_lines + 1;
					end
					$fclose(hex_fd);
				end
				$display("  Program size: %0d instructions", hex_lines);

				// Clear entire instruction memory to NOPs (0x00000000)
				for (i = 0; i < 2048; i = i + 1) begin
					_246tb_ex9_tb.uut.rom.inst.ram_data[i] = 32'h00000000;
				end

				// Reset CPU
				reset = 1;
				flag = 0;
				#100;

				// Load instruction memory
				$readmemh(hex_path, _246tb_ex9_tb.uut.rom.inst.ram_data);

				// Release reset 10ns before posedge (avoid race condition)
				#40;
				reset = 0;

				// Run for hex_lines + 2 cycles (extra NOPs are harmless)
				cycle_cnt = 0;
				while (cycle_cnt < hex_lines + 2) begin
					@(negedge clk_in);
					cycle_cnt = cycle_cnt + 1;
				end

				$display("  Done after %0d cycles", cycle_cnt);

				// Dump final register state
				dump_regs;

				test_idx = test_idx + 1;
				#100;
			end
		end

		$fclose(test_list);
		$fclose(file_output);
		$display("=== All %0d tests completed ===", test_idx);
		$finish;
	end

	// ======== clock generator ========
	always begin
		#50;
		clk_in = ~clk_in;
	end

endmodule
