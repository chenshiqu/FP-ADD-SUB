module FloatAdder(clk, reset, op_a,op_b,out_z,ofw);
	
    /*ports defination*/
	input clk,reset;
	input [31:0] op_a,op_b;    //input operands
    output [31:0] out_z;       //the result
    reg [31:0] s_out_z;
    output ofw;                //overflow
	reg s_ofw;

    reg [31:0] a,b,z;
    reg [23:0] a_m, b_m;       //mantissa
    reg [23:0] z_m;
    reg [8:0] a_e,b_e;         //exponent
    reg [7:0] z_e;
    reg a_s,b_s,z_s;            //sign 

    reg [24:0] sum;

    /*define of state*/
    reg [2:0] state; 
    parameter start = 3'b000,          //extract sign, exponent,mantissa
              special_cases=3'b001,    //deal special cases
              align = 3'b010,          //shift exponent
              add_m = 3'b011,          //add mantissa
              ck_m_ofw = 3'b100,       //check overflow of mantissa
              normalise =3'b101,       //normalise the format
              pack = 3'b110,           //pack z
              put_z = 3'b111;          // set output

    /*main*/
    always @(posedge clk)
    begin
        case(state)
            start:
            begin
                a <= op_a;
                b <= op_b;
                a_s <= a[31];
                a_e <= a[30:23];
                a_m <= a[22:0];
                b_e <= b[30:23];
                b_s <= b[31];
                b_m <= b[22:0];
                state <= special_cases;
            end

            special_cases:
            begin 
                //if a is NaN or b is NaN return NaN
                if((a_e == 255 && a_m != 0)||(b_e == 255 && b_m != 0))
                begin 
                    z[31] <= 1;
                    z[30:23] <= 255;
                    z[22] <= 1;
                    z[21:0] <= 0;
                    state <= put_z;
                end 
                // if a is infinity return infinity
                else if(a_e == 255)
                begin
                    z[31] <= a_s;
                    z[30:23] <= 255;
                    z[22:0] <= 0;
                    state <=put_z;
                end
                //if b is infinity return infinity
                else if(b_e == 255)
                begin 
                    z[31] <= b_s;
                    z[30:23] <= 255;
                    z[22:0] <= 0;
                    state <= put_z;
                end
                //if a is zero return b
                else if((a_e == 0)&&(a_m == 0))
                begin 
                    z[31] <= b_s;
                    z[30:23] <= b_e;
                    z[22:0] <= b[22:0];
                    state <= put_z;
                end
                //if b is zero return a
                else if((b_e == 0) && (b_m == 0))
                begin 
                    z[31] <= a_s;
                    z[30:23] <= a_e;
                    z[22:0] <= a[22:0];
                    state <= put_z;
                end 
                else
                begin
                    // denormalised number 
                    if(a_e == 0) 
                    begin 
                        a_e <= 1;
                    end 
                    else 
                    begin 
                        a_m[23] <= 1;
                    end
                    // denormalised number
                    if(b_e == 0)
                    begin 
                        b_e <= 1;
                    end 
                    else
                    begin
                        b_m[23] <= 1;
                    end
                    state <= align;
                end
            end

            align:
            begin
                if(a_e > b_e)
                begin
                    b_e <= b_e + 1;
                    b_m <= b_m >> 1;
                end
                else if(a_e < b_e)
                begin
                    a_e <= a_e + 1;
                    a_m <= a_m >> 1;
                end
                else
                begin
                    state <= add_m;
                end
            end

            add_m:
            begin
                z_e <= a_e;
                if(a_s == b_s)
                begin
                    sum <= a_m + b_m;
                    z_s <= a_s;
                end
                else 
                begin
                    if(a_m >= b_m)
                    begin
                        sum <= a_m - b_m;
                        z_s <= a_s;
                    end
                    else
                    begin
                        sum <= b_m - a_m;
                        z_s <= b_s;
                    end
                end
                state <= ck_m_ofw;
            end

            ck_m_ofw:
            begin
                if(sum[24])
                begin
                    z_m <= sum[23:1];
                    z_e <= z_e + 1;
                end
                else 
                begin
                    z_m <= sum[22:0];
                end
                state <= normalise;
            end

            normalise:
            begin
                if(z_m[23] == 0 && z_e > 1)
                begin
                    z_e <= z_e -1;
                    z_m <= z_m << 1;
                end
                else 
                begin
                    state <= pack;
                end
            end

            pack:
            begin
                //if overflow occurs, return inf
                if(z_e > 254)
                begin
                    z[22:0] <= 0;
                    z[30:23] <= 255;
                    z[31] <= z_s;
                    s_ofw <= 1;
                end
                else
                begin
                    z[22:0] <= z_m[22:0];
                    z[30:23] <= z_e;
                    z[31] <= z_s;
                    s_ofw <= 0;
                end
                state <= put_z;
            end

            put_z:
            begin 
                s_out_z <= z;
                state <= start;
            end
			
			default:
			begin
				state <= start;
			end
        endcase

        if (reset == 1) 
        begin 
            state <= start;
        end
     end
	assign out_z = s_out_z;
	assign ofw = s_ofw;   
endmodule
