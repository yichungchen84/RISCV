#include "Vtop.h"
#include "verilated.h"
#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#include <string>

#include <bitset>
// #include "verilated_vcd_c.h"

int main(int argc, char **argv, char **env)
{
  std::string output_file = "";
  Verilated::commandArgs(argc, argv);
  for (int i=0; i<argc; i++)
  {
      if (argv[i]== std::string("-o"))
      {
          i++;
          output_file = argv[i];
      }
  }

  std::stringstream tempOutput;
  
  

  std::vector<std::string> check(64*1024);

  Vtop* top = new Vtop;

  std::cout<< "message\n";

  top->clk = 0;
  int t = 0;
  top->reset = 0;
  while (!Verilated::gotFinish()) {
    if (t > 4)
    {
      top->reset = 1;
    }
    top->clk = !top->clk;
    top->eval();
    if (top->clk) // only clk == 1 count 
    {
      // std::cout << std::setfill('0') << std::setw(8) << std::hex << top->top__DOT__mem_rd_data <<" ";
      // std::cout << std::setfill('0') << std::setw(8) << std::hex << top->top__DOT__instr<<std::endl;

      // std::cout << std::setfill('0') << std::setw(8) << std::hex << top->top__DOT__pc<<"\n";
      // std::cout << std::setfill('0') << std::setw(8) << std::hex << top->top__DOT__instr<< "" << " instr" << "\n";

      if (top->top__DOT__mem_wr_en)
      {
        std::stringstream tempValue_0;
        std::stringstream tempValue_1;
        std::stringstream tempValue_2;
        std::stringstream tempValue_3;

        // tempOutput << std::setfill('0') << std::setw(8) << std::hex << top->top__DOT__mem_wr_data<<std::endl;
        // tempOutput << std::setfill('0') << std::setw(8) << std::hex << top->dump_data<<std::endl;

        std::bitset<8> bin_0(top->dump_data_0);
        std::bitset<8> bin_1(top->dump_data_1);
        std::bitset<8> bin_2(top->dump_data_2);
        std::bitset<8> bin_3(top->dump_data_3);


        // std::cout << std::hex << x.to_ulong() << std::endl;
        
        tempValue_0 << std::setfill('0') << std::setw(2) << std::hex << bin_0.to_ulong();
        tempValue_1 << std::setfill('0') << std::setw(2) << std::hex << bin_1.to_ulong();
        tempValue_2 << std::setfill('0') << std::setw(2) << std::hex << bin_2.to_ulong();
        tempValue_3 << std::setfill('0') << std::setw(2) << std::hex << bin_3.to_ulong();

        check[top->mem_addr+0] = tempValue_0.str();
        check[top->mem_addr+1] = tempValue_1.str();
        check[top->mem_addr+2] = tempValue_2.str();
        check[top->mem_addr+3] = tempValue_3.str();

      }

      if (top->flush)
      {
        check.clear();
        check.resize(64*1024);
      }
    }

    if (t>5000)
    {
      std::cout<< "break by length" <<std::endl;
      break;
    }

    t += 1;
  }
  
  // tfp->close();    
  delete top;

  for(int i=0; i<64*1024; i=i+4)
  {
    // if ((!check[i].empty()) && (i>8192))
    if (!check[i].empty())
    {
      tempOutput<< std::hex<< check[i+3] << check[i+2] << check[i+1] << check[i+0] <<std::endl;
    }
  }

  std::cout<< "message end\n";


  if(!output_file.empty())
  {
    std::ofstream tempOutputFile;
    tempOutputFile.open(output_file.c_str());
    tempOutputFile << tempOutput.str();
    tempOutputFile.close();
  }
  else
  {
    std::cout << tempOutput.str();
  }

  exit(0);
}

