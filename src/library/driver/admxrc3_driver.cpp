#include "admxrc3_driver.hpp"

namespace two_layer_net
{

Admxrc3Driver::Admxrc3Driver() {
  ADMXRC3UT_OpenByIndex(0, false, true, 0, &hDevice);
}

Admxrc3Driver::~Admxrc3Driver() {
  ADMXRC3_Close(hDevice);
  hDevice = ADMXRC3_HANDLE_INVALID_VALUE;
}

void Admxrc3Driver::accelWrite(void* buffer, size_t size, uint64_t address, uint32_t channel) {
  ADMXRC3_BUFFER_HANDLE hBuffer;
  ADMXRC3_Lock(hDevice, buffer, size, &hBuffer);
  ADMXRC3_WriteDMALockedEx(hDevice, channel, 0, hBuffer, 0, size, address);
  ADMXRC3_Unlock(hDevice, hBuffer);
}

void Admxrc3Driver::accelRead(void* buffer, size_t size, uint64_t address, uint32_t channel) {
  ADMXRC3_BUFFER_HANDLE hBuffer;
  ADMXRC3_Lock(hDevice, buffer, size, &hBuffer);
  ADMXRC3_ReadDMALockedEx(hDevice, channel, 0, hBuffer, 0, size, address);
  ADMXRC3_Unlock(hDevice, hBuffer);
}

void Admxrc3Driver::copyBufferHostToAccel(void* hostBuffer, size_t size) {
  accelWrite(hostBuffer, size, inBaseAddr, 0);
}

void Admxrc3Driver::copyBufferAccelToHost(void* hostBuffer, size_t size) {
  accelRead(hostBuffer, size, outBaseAddr, 0);
}

void Admxrc3Driver::writeJamRegAddr(uint32_t address, uint32_t control) {
  accelWrite(&control, sizeof(uint32_t), hlsBaseAddr + address, 1);
}

uint32_t Admxrc3Driver::readJamRegAddr(uint32_t address) {
  uint32_t control;
  accelRead(&control, sizeof(uint32_t), hlsBaseAddr + address, 1);
  return control;
}

Admxrc3Driver* initPlatform() {
  if (!platform) {
    platform = new Admxrc3Driver;
  }
  return platform;
}

void deinitPlatform(Admxrc3Driver* platform) {
  delete platform;
  platform = 0;
}

} // namespace two_layer_net
