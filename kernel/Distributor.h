#ifndef DISTRIBUTOR_H_
#define DISTRIBUTOR_H_

#include <stdio.h>
#include "../header/UpdateCacheArea.h"
#include "../header/Buffer.h"
#include "../header/Config.h"
#include "../header/SecIndex.h"
#include "../header/Grid.h"

__global__ void Distributor(UpdateCacheArea *d_cache_update, UpdateType *d_buffer_update, Config *d_config, SecIndex *d_secindex, Grid *d_grid);

#endif
