#include "UpdateKernel.h"

__global__ void UpdateKernel(UpdateCacheArea *d_cache_update, Config *d_config, Grid *d_grid, SecIndex *d_secindex, Bktpond *d_bkt_pond, Buffer *d_free_bkt_id, int *offset1, int *offset2)
{
	const int tid = threadIdx.x + blockDim.x * blockIdx.x;
	int anchor;

	anchor = tid;
	while (anchor < d_config->edge_cell_num * d_config->edge_cell_num)
	{
		for (int i = 0; i < d_cache_update->sum_f[anchor]; i++)
		{
			UpdateType ins_update = d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i];
            d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i].oid = -1;
            d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i].x = -1;
            d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i].y = -1;
            d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i].vx = -1;
            d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i].vy = -1;
            d_cache_update->mtx_fresh[anchor * d_config->len_seg_cache_update + i].ts = -1;
			int oid = ins_update.oid;
            int idx_bkt = d_secindex->index[oid].idx_bkt;
			int idx_obj = d_secindex->index[oid].idx_obj;
			Bucket *cur_bkt = d_grid->arr_cell[anchor].head;
			int j = 0;
			while (j++ < d_grid->arr_cell[anchor].nB - idx_bkt -1) 	cur_bkt = cur_bkt->nxt;
			ObjBox *cur_obj = &(cur_bkt->arr_obj[idx_obj]);
			cur_obj->x = ins_update.x;
			cur_obj->y = ins_update.y;
			cur_obj->vx = ins_update.vx;
			cur_obj->vy = ins_update.vy;
			cur_obj->ts = ins_update.ts;
		}
        d_cache_update->sum_f[anchor] = 0;      
		anchor += blockDim.x * gridDim.x;
	}       
	__syncthreads();
    if (threadIdx.x == 0)
	{
		__iAtomicAdd(offset1, 1);
	}
	__syncthreads();
	while (*offset1 != gridDim.x);
	if (tid == 0)
		printf("Ending Update Fresh Kernel...\n");
    
	anchor = tid;
	while (anchor < d_config->edge_cell_num * d_config->edge_cell_num)
	{
    	for (int i = 0; i < d_cache_update->sum_d[anchor]; i++)
    	{
	    	int oid = d_cache_update->mtx_delete[anchor * d_config->len_seg_cache_update + i];
	    	d_cache_update->mtx_delete[anchor * d_config->len_seg_cache_update + i] = -1;
	    	int idx_bkt = d_secindex->index[oid].idx_bkt;
	    	int idx_obj = d_secindex->index[oid].idx_obj;
            ObjBox *last_obj = &(d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO-1]);

    		Bucket *cur_bkt = d_grid->arr_cell[anchor].head;
	    	int j = 0; 
	    	while (j++ < d_grid->arr_cell[anchor].nB - idx_bkt - 1) cur_bkt = cur_bkt->nxt;
	    	ObjBox *cur_obj = &(cur_bkt->arr_obj[idx_obj]);
	    	if (cur_obj->oid == last_obj->oid)
	    	{
	        	if (d_grid->arr_cell[anchor].head->nO >= 2)
	        	{
			    	last_obj->oid = -1;
			    	last_obj->x = -1;
			    	last_obj->y = -1;
			    	last_obj->vx = -1;
			    	last_obj->vy = -1;
			    	last_obj->ts = -1;
			    	d_grid->arr_cell[anchor].head->nO--;
		    	}
		    	else
		    	{
			    	int rear = __iAtomicAdd(&(d_free_bkt_id->rear), 1);
			    	rear %= d_free_bkt_id->len;
			      	int bid = d_grid->arr_cell[anchor].head->bid;
	    	      	d_free_bkt_id->bkt_id[rear] = bid;
                    d_grid->arr_cell[anchor].head = d_bkt_pond->arr_bkt[bid].nxt;
		         	d_bkt_pond->arr_bkt[bid].nxt = NULL;
 
     			   	d_bkt_pond->arr_bkt[bid].arr_obj[0].oid = -1;
	    		   	d_bkt_pond->arr_bkt[bid].arr_obj[0].x = -1;
		    	   	d_bkt_pond->arr_bkt[bid].arr_obj[0].y = -1;
		    	   	d_bkt_pond->arr_bkt[bid].arr_obj[0].vx = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].vy = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].ts = -1;
			      	d_bkt_pond->arr_bkt[bid].nO = 0;
			     	d_grid->arr_cell[anchor].nB--;  
		    	}
	    	}
	    	else
	    	{
                cur_obj->oid = last_obj->oid;
		    	cur_obj->x = last_obj->x;
		    	cur_obj->y = last_obj->y;
		    	cur_obj->vx = last_obj->vx;
		    	cur_obj->vy = last_obj->vy;
		    	cur_obj->ts = last_obj->ts;
		    	d_secindex->index[last_obj->oid].idx_bkt = idx_bkt;
			    d_secindex->index[last_obj->oid].idx_obj = idx_obj;
		    	if (d_grid->arr_cell[anchor].head->nO >= 2)
		    	{
		    		last_obj->oid = -1;
			    	last_obj->x = -1;
			    	last_obj->y = -1;
			    	last_obj->vx = -1;
			    	last_obj->vy = -1;
			    	last_obj->ts = -1;
			    	d_grid->arr_cell[anchor].head->nO--;
		    	}
		    	else
		    	{
		    		int rear = __iAtomicAdd(&(d_free_bkt_id->rear), 1);
			    	rear %= d_free_bkt_id->len;
			      	int bid = d_grid->arr_cell[anchor].head->bid;
	    	     	d_free_bkt_id->bkt_id[rear] = bid;
                    d_grid->arr_cell[anchor].head = d_bkt_pond->arr_bkt[bid].nxt;
			     	d_bkt_pond->arr_bkt[bid].nxt = NULL;
 
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].oid = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].x = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].y = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].vx = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].vy = -1;
			      	d_bkt_pond->arr_bkt[bid].arr_obj[0].ts = -1;
			      	d_bkt_pond->arr_bkt[bid].nO = 0;
			     	d_grid->arr_cell[anchor].nB--;  
		    	}
	    	}
    	}
        d_cache_update->sum_d[anchor] = 0;    
        anchor += blockDim.x * gridDim.x;
    }    
	__syncthreads();
	if (threadIdx.x == 0)
	{
		__iAtomicAdd(offset2, 1);
	}
	__syncthreads();
    while (*offset2 != gridDim.x);
	if (tid == 0)
		printf("Ending Update Delete Kernel...\n");

	anchor = tid;
	while (anchor < d_config->edge_cell_num * d_config->edge_cell_num)
	{
		for (int i = 0; i < d_cache_update->sum_i[anchor]; i++)
		{
			UpdateType ins_update = d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i];
            d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i].oid = -1;
            d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i].x = -1;
            d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i].y = -1;
            d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i].vx = -1;
            d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i].vy = -1;
            d_cache_update->mtx_insert[anchor * d_config->len_seg_cache_update + i].ts = -1;

            if (d_grid->arr_cell[anchor].head == NULL)
			{
				int front = __iAtomicAdd(&(d_free_bkt_id->front), 1);
				front %= d_free_bkt_id->len;
				int bid = d_free_bkt_id->bkt_id[front];
				d_grid->arr_cell[anchor].head = &(d_bkt_pond->arr_bkt[bid]);
				d_grid->arr_cell[anchor].nB++;
		    }
			else if (d_grid->arr_cell[anchor].head->nO >= d_config->max_bucket_len)
			{
     			int front = __iAtomicAdd(&(d_free_bkt_id->front), 1);
				front %= d_free_bkt_id->len;
				int bid = d_free_bkt_id->bkt_id[front];
				int h_bid = d_grid->arr_cell[anchor].head->bid;
				d_grid->arr_cell[anchor].head = &(d_bkt_pond->arr_bkt[bid]);
				d_bkt_pond->arr_bkt[bid].nxt = &(d_bkt_pond->arr_bkt[h_bid]);
				d_grid->arr_cell[anchor].nB++;
			}     
			d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO].oid = ins_update.oid;
			d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO].x = ins_update.x;
			d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO].y = ins_update.y;
			d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO].vx = ins_update.x;
			d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO].vy = ins_update.y;
			d_grid->arr_cell[anchor].head->arr_obj[d_grid->arr_cell[anchor].head->nO].ts = ins_update.ts;   
			d_grid->arr_cell[anchor].head->nO++;        

            d_secindex->index[ins_update.oid].idx_cell = anchor;
			d_secindex->index[ins_update.oid].idx_bkt = d_grid->arr_cell[anchor].nB-1;   
			d_secindex->index[ins_update.oid].idx_obj = d_grid->arr_cell[anchor].head->nO-1;    
		}
        d_cache_update->sum_i[anchor] = 0;       
		anchor += gridDim.x * blockDim.x;   
	}       
	__syncthreads();
	if (tid == 0)
		printf("Ending Update Insert Kernel...\n");
} 


