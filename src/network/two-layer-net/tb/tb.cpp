#include <iostream>
#include <math.h>
#include <tb_define.h>
#include <tb_in.h>
#include <tb_out.h>

void BlackBoxJam(ExtMemWord *in, ExtMemWord *out);

int main(void) {
  ExtMemWord out[19885];
  BlackBoxJam(in, out);
  unsigned int i;
  unsigned int ret = 0;
  for (i = 0; i < 19885; i++) {
    if (fabsf((float)expected_out[i] - (float)out[i]) > 0.001) {
      std::cout << "[" << i << "]: expected: ";
      std::cout << expected_out[i];
      std::cout << ", out: ";
      std::cout << out[i] << std::endl;
      ret = 1;
    }
  }
  if (ret == 0) {
    std::cout << "SUCCESS: out is expected result" << std::endl;
  } else {
    std::cout << "ERROR: difference is too large" << std::endl;
  }
  return ret;
}
