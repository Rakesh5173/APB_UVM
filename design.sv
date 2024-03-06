interface dut_if;
  logic pclk;
  logic prst;
  logic [31:0] paddr;
  logic pwrite;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic pready;
  logic psel;
  logic penable;

  // Master clocking block
  clocking master_clk @(posedge pclk);
    output paddr;
    output pwrite;
    output pwdata;
    output psel;
    output penable;
    input prdata;
  endclocking:master_clk
  
  // Slave Clocking Block
  clocking slave_clk@(posedge pclk);
    output prdata;
    input psel,paddr,penable,pwrite,pwdata;
  endclocking: slave_clk
  
  clocking mon_clk @(posedge pclk);
    input paddr,psel,penable,pwrite,prdata,pwdata;
  endclocking: mon_clk
  
  modport master(clocking master_clk);
  modport slave(clocking slave_clk);
    modport psv(clocking mon_clk);
  
 
endinterface


module apb_slave(dut_if dif);

  logic [31:0] mem [0:256];
  logic [1:0] apb_status; // state of the slave (setup,write,read)
  const logic [1:0] SETUP=0;
  const logic [1:0] W_ENABLE=1;
  const logic [1:0] R_ENABLE=2;
  
  always @(posedge dif.pclk or negedge dif.prst) begin
    if (dif.prst==0) begin
      apb_status <=0;
      dif.prdata <=0;
      dif.pready <=1;
      for(int i=0;i<256;i++) mem[i]=i;
    end
    else begin
      case (apb_status)
        SETUP: begin
          dif.prdata <= 0;
          if (dif.psel && !dif.penable) begin
            if (dif.pwrite) begin
              apb_status <= W_ENABLE;
            end
            else begin
              apb_status <= R_ENABLE;
              dif.prdata <= mem[dif.paddr];
            end
          end
        end
        W_ENABLE: begin
          if (dif.psel && dif.penable && dif.pwrite) begin
            mem[dif.paddr] <= dif.pwdata;
          end
          apb_status <= SETUP;
        end
        R_ENABLE: begin
          apb_status <= SETUP;
        end
      endcase
    end
  end
  
endmodule
