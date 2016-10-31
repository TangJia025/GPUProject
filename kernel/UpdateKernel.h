#ifndef UPDATEKERNEL_H_
#define UPDATEKERNEL_H_

#include <stdio.h>
#include "../header/UpdateCacheArea.h"
#include "../header/Buffer.h"
#include "../header/Config.h"
#include "../header/SecIndex.h"
#include "../header/Grid.h"
#include "../header/Bucket.h"

__global__ void UpdateKernel(UpdateCacheArea *cache_update, Config *config, Grid *grid, SecIndex *secindex, Bktpond *bkt_pond, Buffer *free_bkt_id, int *offset1, int *offset2);

#endif
