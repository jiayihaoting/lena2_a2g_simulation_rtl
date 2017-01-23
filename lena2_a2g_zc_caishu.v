
module lena2_a2g_zc_caishu
        (
///input
          clk_logic               ,
          rst_logic_n             ,

	 	  i_emif_wr_en_tx         ,
	 	  i_emif_wr_ant_idx       ,   //0:ant0 ; 1:ant1
          i_rd_tx_ant_i           ,
          i_rd_tx_ant_q           ,
          
	      i_crc_vld               ,
	      i_crc_result            ,

	      i_sfr_cc                ,
	      i_ant0_i                ,
	      i_ant0_q                , 
	      i_ant1_i                ,  
	      i_ant1_q                ,  

///output
          o_ant_i_tx              ,
          o_ant_q_tx
        );

//======================================
// Register input/output
//======================================
input            clk_logic          ;
input            rst_logic_n        ;
///intput

input            i_emif_wr_en_tx    ;
inout            i_emif_wr_ant_idx  ;
input            i_rd_tx_ant_i      ;
input            i_rd_tx_ant_q      ;


input            i_sfr_cc           ;
input [11:0]	 i_ant0_i           ;
input [11:0]	 i_ant0_q           ;
input [11:0]	 i_ant1_i           ;
input [11:0]	 i_ant1_q           ;


input            i_crc_vld          ;
input            i_crc_result       ;

///output
output[15:0]     o_ant_i_tx         ;
output[15:0]     o_ant_q_tx         ;
//======================================
// wire/reg for field
//======================================
reg              ping_pang          ;
always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        ping_pang <= 1'd1;
    else if(i_sfr_cc)
        ping_pang <= !ping_pang;

reg emif_wr_en_tx_buf1 ;
reg emif_wr_en_tx_buf2 ;

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        emif_wr_en_tx_buf1 <= 1'd0;
    else
        emif_wr_en_tx_buf1 <= i_emif_wr_en_tx;

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        emif_wr_en_tx_buf2 <= 1'd0;
    else
        emif_wr_en_tx_buf2 <= emif_wr_en_tx_buf1;

reg  catch_done  ;
reg  s_emif_wr_en       ;
reg  s_emif_wr_en_buf   ;
reg  trigger_get ;
reg  crc_err_get ;

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        trigger_get <= 1'd0;
    else if(emif_wr_en_tx_buf1 &(!emif_wr_en_tx_buf2))
        trigger_get <= 1'd1;
    else if(catch_done)
        trigger_get <= 1'd0;

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        s_emif_wr_en_buf <= 1'd0;
    else if(i_sfr_cc)
        s_emif_wr_en_buf <= s_emif_wr_en;

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        crc_err_get <= 1'd0;
    else if(s_emif_wr_en_buf)
        if(i_crc_vld & (!i_crc_result))
            crc_err_get <= 1'd1;
        else
            crc_err_get <= crc_err_get ;
    else if(catch_done)
        crc_err_get <= 1'd0;

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        catch_done <= 1'd0;
    else if(i_sfr_cc)
        if(trigger_get & crc_err_get)
            catch_done <= 1'd1;
        else
            catch_done <= 1'd0 ;
    else
        catch_done <= catch_done ;

///s_emif_wr_en

always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        s_emif_wr_en <= 1'd0;
    else if(crc_err_get)
        s_emif_wr_en <= 1'd0;
    else if((ping_pang) & i_sfr_cc & trigger_get)
        s_emif_wr_en <= 1'd1;
    else if(ping_pang)
        s_emif_wr_en <= 1'd0;


reg    [16:0]    wr_addr            ;
always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        wr_addr <= 17'd0;
    else if(s_emif_wr_en)
        wr_addr <= wr_addr + 17'd1 ;
    else
        wr_addr <= 17'd0;

reg    [14:0]    rd_addr_ant_i     ;
reg    [14:0]    rd_addr_ant_q     ;

////rd_addr_ant_i
always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        rd_addr_ant_i <= 15'd0;
    else if(!s_emif_wr_en&&i_emif_wr_en_tx)
        rd_addr_ant_i <= 15'd0;
    else if(i_rd_tx_ant_i)
        rd_addr_ant_i <= rd_addr_ant_i + 15'd1;


////rd_addr_ant0_q
always @ (posedge clk_logic or negedge rst_logic_n)
    if(!rst_logic_n)
        rd_addr_ant_q <= 15'd0;
    else if(!s_emif_wr_en&&i_emif_wr_en_tx)
        rd_addr_ant_q <= 15'd0;
    else if(i_rd_tx_ant_q)
        rd_addr_ant_q <= rd_addr_ant_q + 15'd1;


//======================================
// wr30720x32_rd30720x32 IP for real
//======================================
wire [11:0] ant_i_data;
wire [11:0] ant_q_data;

assign ant_i_data = i_emif_wr_ant_idx ? i_ant1_i:i_ant0_i;
assign ant_q_data = i_emif_wr_ant_idx ? i_ant1_q:i_ant0_q;

wire [11:0] ant_i_tx;
wire [11:0] ant_q_tx;

assign o_ant_i_tx = {ant_i_tx,4'd0};
assign o_ant_q_tx = {ant_q_tx,4'd0};

wire [14:0] caishu_waddr; 

assign caishu_waddr = wr_addr[16:2];

lena2_a2g_zc_caishu_ram    lena2_a2g_zc_caishu_ram_real
(
	.clock        (clk_logic      ),
	.data         (ant_i_data     ),
	.rdaddress    (rd_addr_ant_i  ),
	.rden         (i_rd_tx_ant_i  ),
	.wraddress    (wr_addr[16:2]  ),
	.wren         (s_emif_wr_en   ),
	.q            (ant_i_tx       )
);

//======================================
// wr30720x32_rd30720x32 IP for imag
//======================================
lena2_a2g_zc_caishu_ram    lena2_a2g_zc_caishu_ram_imag
(
	.clock        (clk_logic      ),
	.data         (ant_q_data     ),
	.rdaddress    (rd_addr_ant_q  ),
	.rden         (i_rd_tx_ant_q  ),
	.wraddress    (wr_addr[16:2]  ),
	.wren         (s_emif_wr_en   ),
	.q            (ant_q_tx       )
);
endmodule