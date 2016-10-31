#include "Distributor.h"

__global__ void Distributor(UpdateCacheArea *d_cache_update, UpdateType *d_buffer_update, Config *d_config, SecIndex *d_secindex, Grid *d_grid)
{
	const int tid = threadIdx.x + blockDim.x * blockIdx.x;
    int anchor;

	anchor = tid;
	while (anchor < d_config->block_size_update)
	{
		UpdateType ins_update = d_buffer_update[anchor];

	   	SIEntry p_sie = d_secindex->index[ins_update.oid];
	   	int old_cell_id, new_cell_id;
	   	old_cell_id = p_sie.idx_cell;

	    int i = ins_update.x;
	   	int j = ins_update.y;
	   	new_cell_id = i + j * d_config->edge_cell_num;

	   	if (new_cell_id == old_cell_id)
	   	{
	    	if (d_cache_update->sum_f[old_cell_id] < d_config->len_seg_cache_update)
	    	{
                int cnt_f = __iAtomicAdd(&(d_cache_update->sum_f[old_cell_id]), 1);      //very important
		        d_cache_update->mtx_fresh[old_cell_id * d_config->len_seg_cache_update + cnt_f] = ins_update;
	    	}
	   	}
	   	else
	   	{
	    	if (d_cache_update->sum_d[old_cell_id] < d_config->len_seg_cache_update && \
	    			d_cache_update->sum_i[new_cell_id] < d_config->len_seg_cache_update)
		   	{
                int cnt_d = __iAtomicAdd(&(d_cache_update->sum_d[old_cell_id]), 1);
		       	d_cache_update->mtx_delete[old_cell_id * d_config->len_seg_cache_update + cnt_d] = ins_update.oid;
			
                int cnt_i = __iAtomicAdd(&(d_cache_update->sum_i[new_cell_id]), 1);
		        d_cache_update->mtx_insert[new_cell_id * d_config->len_seg_cache_update + cnt_i] = ins_update;
	    	}
	   	}
		anchor += gridDim.x * blockDim.x;
	}
	__syncthreads();    

	if (tid == 0)
    	printf("Ending Distributing Update Kernel...\n");

}

