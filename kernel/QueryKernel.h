#ifndef QUERYKERNEL_H_
#define QUERYKERNEL_H_

#include <stdio.h>
#include "../header/BaseStruct.h"
#include "../header/Grid.h"
#include "../header/Config.h"
#include "../header/QueryCacheArea.h"
#include "../header/QueryOut.h"

__global__ void QueryDispatch(QueryCacheArea *d_cache_query, QueryType *d_buffer_query, Config *d_config);
__device__ int CountObject(int rs, int re, int cs, int ce, Config *config, Grid *grid);
__device__ void QueryWrite(QueryOut *query_out, QueryCacheArea *cache_query, QueryType que, Grid *grid, int anchor);
__global__ void QueryKernel(QueryOut *d_query_out, QueryCacheArea *d_cache_query, QueryType *d_buffer_query, Config *d_config, Grid *d_grid);
//__device__ void DynamicParallelism(QueryOut *query_out, QueryCacheArea *cache_query, QueryType que, Config *config, Grid *grid, int anchor, int Avg);
//__global__ void DynamicKernel(QueryOut *query_out, QueryCacheArea *cache_query, QueryType que, Grid *grid, int anchor);
//__global__ void QueryKernel(QueryOut *d_query_out, QueryCacheArea *d_cache_query, QueryType *d_buffer_query, Config *d_config, Grid *d_grid, int Avg);

#endif 
