#include "QueryKernel.h"

__global__ void QueryDispatch(QueryCacheArea *d_cache_query, QueryType *d_buffer_query, Config *d_config)
{
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	int anchor = tid;
	while (anchor < d_config->block_size_query)
	{
		QueryType que = d_buffer_query[anchor];
		int rs = que.minY;
		int re = que.maxY;
		int cs = que.minX;
		int ce = que.maxX;
		for (int i = rs; i <= re; i++)
		{
			for (int j = cs; j <= ce; j++)
			{
				int cid = i * d_config->edge_cell_num + j;
				if (i == rs || i == re || j == cs || j == ce)
				{
					d_cache_query->partial[anchor * d_cache_query->seg2 + d_cache_query->cnt2[anchor]] = cid;
					d_cache_query->cnt2[anchor]++;
				}
				else
				{
					d_cache_query->total[anchor * d_cache_query->seg1 + d_cache_query->cnt1[anchor]] = cid;
					d_cache_query->cnt1[anchor]++;
				}
			}
		}
		anchor += gridDim.x * blockDim.x;
	}
	__syncthreads();
	if (tid == 0)
		printf("Ending QueryDispatch...\n");
}

__device__ int CountObject(int rs, int re, int cs, int ce, Config *config, Grid *grid)
{
	int res = 0;
	for (int i = rs; i <= re; i++)
	{
		for (int j = cs; j <= ce; j++)
		{
			int cid = i * config->edge_cell_num + j;
			int nB = grid->arr_cell[cid].nB;
			if (nB > 0)
				res = res + grid->arr_cell[cid].head->nO + (nB - 1) * config->max_bucket_len;
		}
	}
	return res;
}

__device__ void QueryWrite(QueryOut *query_out, QueryCacheArea *cache_query, QueryType que, Grid *grid, int anchor)  // 采用一个virtual warp处理一个查询；
{
	int tid = threadIdx.x + blockDim.x * blockIdx.x;
	int woff = tid % 8;
	int k = woff;
	while (k < cache_query->cnt1[anchor])
	{
		int cid = cache_query->total[anchor * cache_query->seg1 + k];
		Bucket *cur_bkt = grid->arr_cell[cid].head;
		while (cur_bkt != NULL)
		{
			for (int j = 0; j < cur_bkt->nO; j++)
			{
				int pos;
				if (query_out->cnt[anchor] < query_out->seg)
                    pos = __iAtomicAdd(&(query_out->cnt[anchor]), 1);
				else
					pos = query_out->cnt[anchor];
				query_out->obj_id[anchor * query_out->seg + pos] = cur_bkt->arr_obj[j].oid;
			}
			cur_bkt = cur_bkt->nxt;
		}
		k += 8;
	}
	cache_query->cnt1[anchor] = 0;

	k = woff;
	while (k < cache_query->cnt2[anchor])
	{
		int cid = cache_query->partial[anchor * cache_query->seg1 + k];
		Bucket *cur_bkt = grid->arr_cell[cid].head;
		while (cur_bkt != NULL)
		{
			for (int j = 0; j < cur_bkt->nO; j++)
			{
				if (cur_bkt->arr_obj[j].x >= que.minX && cur_bkt->arr_obj[j].x < que.maxX && cur_bkt->arr_obj[j].y >= que.minY && cur_bkt->arr_obj[j].y < que.maxY)
				{
			    	int pos;
			    	if (query_out->cnt[anchor] < query_out->seg)
			    		pos = __iAtomicAdd(&(query_out->cnt[anchor]), 1);
		    		else
			    		pos = query_out->cnt[anchor];
			    	query_out->obj_id[anchor * query_out->seg + pos] = cur_bkt->arr_obj[j].oid;
		    	}
			}
			cur_bkt = cur_bkt->nxt;
		}
		k += 8;
	}
	cache_query->cnt2[anchor] = 0;
}


__global__ void QueryKernel(QueryOut *d_query_out, QueryCacheArea *d_cache_query, QueryType *d_buffer_query, Config *d_config, Grid *d_grid)
{
	int tid = threadIdx.x + blockDim.x * blockIdx.x;
	int wid = tid / 8; 
	int stride = blockDim.x * gridDim.x / 8;
	int anchor = wid;
	while (anchor < d_config->block_size_query)
	{
		QueryType que = d_buffer_query[anchor];
	//	DynamicParallelism(d_query_out, d_cache_query, que, d_config, d_grid, anchor, Avg);
        QueryWrite(d_query_out, d_cache_query, que, d_grid, anchor);
		anchor += stride;
	}
	if (tid == 0)
		printf("Ending QueryKernel...\n");
}

/*__device__ void DynamicParallelism(QueryOut *query_out, QueryCacheArea *cache_query, QueryType que, Config *config, Grid *grid, int anchor, int Avg)
{
	int tid = threadIdx.x + blockDim.x * blockIdx.x;
	int woff = tid % 4;
	int rs = que.minY;
	int re = que.maxY;
	int cs = que.minX;
	int ce = que.maxX;
	int Cur = CountObject(rs, re, cs, ce, config, grid);
	if (Cur > Avg * 2)
	{
		if (woff == 0)
			DynamicKernel<<<1, 8>>>(query_out, cache_query, que, grid, anchor);
	}
}

__global__ void DynamicKernel(QueryOut *query_out, QueryCacheArea *cache_query, QueryType que, Grid *grid, int anchor)
{
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	int k = tid;
	while (k < cache_query->cnt1[anchor])
	{
		int cid = cache_query->total[anchor * cache_query->seg1 + k];
		Bucket *cur_bkt = grid->arr_cell[cid].head;
		while (cur_bkt != NULL)
		{
			for (int j = 0; j < cur_bkt->nO; j++)
			{
				int pos;
				if (query_out->cnt[anchor] < query_out->seg)
					pos = __iAtomicAdd(&(query_out->cnt[anchor]), 1);
				else
					pos = query_out->cnt[anchor];
				query_out->obj_id[anchor * query_out->seg + pos] = cur_bkt->arr_obj[j].oid;
			}
			cur_bkt = cur_bkt->nxt;
		}
		k += gridDim.x * blockDim.x;
	}
    cache_query->cnt1[anchor] = 0;

	k = tid;
	while (k < cache_query->cnt2[anchor])
	{
		int cid = cache_query->partial[anchor * cache_query->seg2 + k];
		Bucket *cur_bkt = grid->arr_cell[cid].head;
		while (cur_bkt != NULL)
		{
	    	for (int j = 0; j < cur_bkt->nO; j++)
	    	{
	    		if (cur_bkt->arr_obj[j].x >= que.minX && cur_bkt->arr_obj[j].x < que.maxX && cur_bkt->arr_obj[j].y >= que.minY && cur_bkt->arr_obj[j].y < que.maxY)
	    		{
	    			int pos;
		    		if (query_out->cnt[anchor] < query_out->seg)
		    			pos = __iAtomicAdd(&(query_out->cnt[anchor]), 1);
		    		else
			    		pos = query_out->cnt[anchor];
			    	query_out->obj_id[anchor * query_out->seg + pos] = cur_bkt->arr_obj[j].oid;
		    	}
			}
			cur_bkt = cur_bkt->nxt;
		}
		k += gridDim.x * blockDim.x;
	}
}     */

/*__global__ void QueryKernel(QueryOut *d_query_out, QueryCacheArea *d_cache_query, QueryType * d_buffer_query, Config *d_config, Grid *d_grid, int Avg)
{
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
    int anchor = tid;
	while (anchor < d_config->block_size_query)
	{
		QueryType que = d_buffer_query[anchor];
		int rs = que.minY;
		int re = que.maxY;
		int cs = que.minX;
		int ce = que.maxX;
		int Cur = CountObject(rs, re, cs, ce, d_config, d_grid);
        if (Cur > Avg)
			DynamicParallelism<<<1, 4 >>>(d_query_out, d_cache_query, d_grid, que, anchor);
		else
		{
			for (int i = 0; i < d_cache_query->cnt1[anchor]; i++)
			{
				int cid = d_cache_query->total[anchor * d_cache_query->seg1 + i];
				Bucket *cur_bkt = d_grid->arr_cell[cid].head;
				while (cur_bkt != NULL)
				{
					for (int j = 0; j < cur_bkt->nO; j++)
					{
						d_query_out->obj_id[anchor * d_query_out->seg + d_query_out->cnt[anchor]] = cur_bkt->arr_obj[j].oid;
						if (d_query_out->cnt[anchor] < d_query_out->seg)
							 ++d_query_out->cnt[anchor];
					}
					cur_bkt = cur_bkt->nxt;
				}
			}
			d_cache_query->cnt1[anchor] = 0;

			for (int i = 0; i < d_cache_query->cnt2[anchor]; i++)
			{
				int cid = d_cache_query->partial[anchor * d_cache_query->seg2 + i];
				Bucket *cur_bkt = d_grid->arr_cell[cid].head;
				while (cur_bkt != NULL)
				{
					for (int j = 0; j < cur_bkt->nO; j++)
					{
						if (cur_bkt->arr_obj[j].x >= que.minX && cur_bkt->arr_obj[j].x < que.maxX && cur_bkt->arr_obj[j].y >= que.minY && cur_bkt->arr_obj[j].y < que.maxY)
						{
					    	d_query_out->obj_id[anchor * d_query_out->seg + d_query_out->cnt[anchor]] = cur_bkt->arr_obj[j].oid;
					    	if (d_query_out->cnt[anchor] < d_query_out->seg)
						    	 ++d_query_out->cnt[anchor];
						}
					}
					cur_bkt = cur_bkt->nxt;
				}
			}
			d_cache_query->cnt2[anchor] = 0;  
		}    
		anchor += gridDim.x * blockDim.x;
	}  
	if (tid == 0)
		printf("Ending QueryKernel...\n");
}   */

