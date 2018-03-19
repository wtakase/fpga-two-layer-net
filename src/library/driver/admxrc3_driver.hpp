#ifndef _ADMXRC3_DRIVER_HPP
#define _ADMXRC3_DRIVER_HPP

#include <asm/byteorder.h>
#include <admxrc3.h>
#include <admxrc3ut.h>
#include <unistd.h>

namespace two_layer_net
{

class Admxrc3Driver
{
public:
  ADMXRC3_HANDLE hDevice;
  const uint32_t hlsBaseAddr = 0x00000;
  const uint32_t inBaseAddr = 0x00000;
  const uint32_t outBaseAddr = 0x80000;

  Admxrc3Driver();

  ~Admxrc3Driver();

  void accelWrite(void* buffer, size_t size, uint64_t address, uint32_t channel);

  void accelRead(void* buffer, size_t size, uint64_t address, uint32_t channel);

  void copyBufferHostToAccel(void* hostBuffer, size_t size);

  void copyBufferAccelToHost(void* hostBuffer, size_t size);

  void writeJamRegAddr(uint32_t address, uint32_t control);

  uint32_t readJamRegAddr(uint32_t address);
};

static Admxrc3Driver* platform;

Admxrc3Driver* initPlatform();

void deinitPlatform(Admxrc3Driver* platform);

} // namespace two_layer_net

#endif
