#include <iostream>
#include <stdio.h>

#include "header/Config.h"
#include "header/Bucket.h"
#include "header/Buffer.h"
#include "header/SecIndex.h"
#include "header/Grid.h"
#include "header/RandNumber.h"
#include "header/UpdateCacheArea.h"
#include "header/QueryCacheArea.h"
#include "header/QueryOut.h"

#include "kernel/Distributor.h"
#include "kernel/UpdateKernel.h"
#include "kernel/QueryKernel.h"

using namespace std;

Config *config = NULL;
Bktpond *bkt_pond = NULL;
Buffer *free_bkt_id = NULL;
Grid *grid = NULL;
SecIndex *secindex = NULL;
UpdateBuffer *orig_buffer_update = NULL;
QueryBuffer *orig_buffer_query = NULL;
UpdateCacheArea *cache_update = NULL;
QueryCacheArea *cache_query;  // 存储每个查询请求的部分 和全部 查询Cell号；
QueryOut *query_out = NULL;
FILE *fp1, *fp2;  // 分别表示 更新文件句柄、 查询文件句柄；
cudaStream_t stream1, stream2, stream3;
cudaEvent_t start1, stop1;
float elapsedTime;
int *offset1, *offset2;

void CtorConfig();
void CtorBktpond();
void CtorBuffer();
void CtorGridandSecIndex();
void CtorUpdateBuffer();
void WriteUpdateBuffer();
void CtorQueryBuffer();
void WriteQueryBuffer();
void CtorCacheUpdate();
void CtorCacheQuery();
void CtorQueryOut();
void Dtor();

int main()
{
    cudaStreamCreate(&stream1);
	cudaStreamCreate(&stream2);
	cudaStreamCreate(&stream3); 

	cudaEventCreate(&start1);
	cudaEventCreate(&stop1);  

	cout << " ****************** " << endl;
	CtorConfig(); // 创建参数文件config;
    CtorBktpond(); // 创建内存池Bktpond;
	CtorBuffer();  // 创建Bucket号环形缓冲区；
	CtorGridandSecIndex(); // 创建区域索引Grid 和 二级索引SecIndex;
	CtorUpdateBuffer();  // 创建更新请求缓冲区orig_buffer_update;
	CtorQueryBuffer();  // 创建查询请求缓冲区orig_buffer_query;
	CtorCacheUpdate();
	CtorCacheQuery();
    CtorQueryOut();  // 创建查询输出缓冲区query_out;
	cout << " ****************** " << endl;
    cudaMallocManaged(&offset1, sizeof(int));
	cudaMallocManaged(&offset2, sizeof(int));
    
	if (config->gaussian_data == 1)
	{
		cout << "Reading Gaussian Data..." << endl;
		fp1 = fopen("generator/gaussian/update.txt", "r");
		fp2 = fopen("generator/gaussian/query.txt", "r");
		if (fp1 == NULL || fp2 == NULL)
		{
			cout << "Opening Gaussian File Error..." << endl;
			return 1;
		}
	}
	else
	{
		cout << "Reading Uniform Data..." << endl;
		fp1 = fopen("generator/uniform/update.txt", "r");
		fp2 = fopen("generator/uniform/query.txt", "r");
		if (fp1 == NULL || fp2 == NULL)
		{
			cout << "Opening Uniform File Error..." << endl;
			return 1;
		}
	}
	WriteUpdateBuffer();
	WriteQueryBuffer();
    cudaEventRecord(start1, 0);
//	int Avg = config->max_obj_num * config->query_width_rate * config->query_width_rate;
	for (int i = 0; i < 25; i++)
	{
	cout << "Round " << i << endl;
/*	*offset1 = *offset2 = 0;
    Distributor<<<3, 1024, 0, stream1>>>\
         	(cache_update, orig_buffer_update->buffer_update + i * config->block_size_update, config, secindex, grid);
   	cudaStreamSynchronize(stream1);
	UpdateKernel<<<3, 1024, 0, stream1>>>\
		    (cache_update, config, grid, secindex, bkt_pond, free_bkt_id, offset1, offset2);
	cudaStreamSynchronize(stream1);    */
	QueryDispatch<<<10, 1024, 0, stream1>>>\
		    (cache_query, orig_buffer_query->buffer_query + i * config->block_size_query, config);
	cudaStreamSynchronize(stream1);
	QueryKernel<<<10, 1024, 0, stream1>>>\
			(query_out, cache_query, orig_buffer_query->buffer_query + i * config->block_size_query, config, grid);
	cudaStreamSynchronize(stream1); 
	for (int j = 0; j < query_out->query_num; j++) query_out->cnt[j] = 0; // 算是给QueryOut清空；   
	}
    cudaEventRecord(stop1);
    cudaEventSynchronize(stop1);
    cudaEventElapsedTime(&elapsedTime, start1, stop1);
    cout << "Time taken: " << elapsedTime << "ms" << endl;      

	Dtor();
	return 0;
}

void CtorConfig()
{
    cudaMallocManaged(&config, sizeof(Config));

	config->edge_cell_num = 128;
	config->gaussian_data = 1;
	config->hotspot_num = 100;
	config->max_bucket_len = 1000;
	config->bucket_num = 22000;
	config->query_width_rate = 0.02;

	config->region_xmin = 0;
	config->region_xmax = config->edge_cell_num - 1;
	config->region_ymin = 0;
	config->region_ymax = config->edge_cell_num - 1;
	config->max_obj_num = 10000000;
	config->max_update_num = 40000000;
	config->max_query_num = 4000000; 
	config->block_size_update = 400000;
	config->block_size_query = 40000;
	config->block_analysis_num = 3;
	config->block_update_num = 8;
	config->block_query_num = 8;
	config->thread_analysis_num = 1024; 
	config->len_seg_cache_update = 100; 
	config->len_seg_query_out = 100;
	config->query_width = config->edge_cell_num * config->query_width_rate;
	config->obj_move_speed = 1;
	cout << "Config Initial Completed..." << endl;
}

void CtorBktpond()
{
	cudaMallocManaged(&bkt_pond, sizeof(Bktpond));
	bkt_pond->bkt_num = config->bucket_num;
	cudaMallocManaged(&(bkt_pond->arr_bkt), bkt_pond->bkt_num * sizeof(Bucket));

	ObjBox *arr_obj;
	cudaMallocManaged(&arr_obj, config->bucket_num * config->max_bucket_len * sizeof(ObjBox));
	for (int i = 0; i < config->bucket_num * config->max_bucket_len; i++)
	{
		arr_obj[i].oid = -1;
		arr_obj[i].x = -1;
		arr_obj[i].y = -1;
		arr_obj[i].ts = -1;
	}
	
	for (int i = 0; i < bkt_pond->bkt_num; i++)
	{
		bkt_pond->arr_bkt[i].bid = i;
		bkt_pond->arr_bkt[i].nO = 0;
		bkt_pond->arr_bkt[i].nxt = NULL;
		bkt_pond->arr_bkt[i].arr_obj = arr_obj + i * config->max_bucket_len;
	}
    cout << "Bktpond Initial Completed..." << endl;
}

void CtorBuffer()
{
	cudaMallocManaged(&free_bkt_id, sizeof(Buffer));
	free_bkt_id->front = free_bkt_id->rear = 0;
	free_bkt_id->len = config->bucket_num;
	cudaMallocManaged(&(free_bkt_id->bkt_id), free_bkt_id->len * sizeof(int));
	for (int i = 0; i < free_bkt_id->len; i++)
		free_bkt_id->push(i);
	cout << "FreeBktId Initial Completed..." << endl;
}

void CtorGridandSecIndex()
{
	cudaMallocManaged(&grid, sizeof(Grid));
	grid->cell_num = config->edge_cell_num * config->edge_cell_num;
	cudaMallocManaged(&(grid->arr_cell), grid->cell_num * sizeof(Cell));
	for (int i = 0; i < grid->cell_num; i++)
	{
		grid->arr_cell[i].nB = 0;
		grid->arr_cell[i].head = NULL;
	}
	cudaMallocManaged(&secindex, sizeof(SecIndex));
	secindex->nI = config->max_obj_num;
	cudaMallocManaged(&(secindex->index), secindex->nI * sizeof(SIEntry));
	for (int i = 0; i < secindex->nI; i++)
	{
		secindex->index[i].idx_cell = -1;
		secindex->index[i].idx_bkt = -1;
		secindex->index[i].idx_obj = -1;
	}

	FILE *fp;
	if (config->gaussian_data == 1)
		fp = fopen("generator/gaussian/init.txt", "r");
	else
		fp = fopen("generator/uniform/init.txt", "r");
    if (fp == NULL) 
	{
		cout << "Opening Init.txt Error..." << endl;
		return;
	}
	int oid;
	float x, y, vx, vy, ts;
	for (int i = 0; i < config->max_obj_num; i++)
	{
		fscanf(fp, "%d %f %f %f %f %f\n", &oid, &x, &y, &vx, &vy, &ts);
		int cell_id = Grid::getCellByXY(x, y, config->edge_cell_num);
        if (grid->arr_cell[cell_id].head == NULL)
		{
			grid->arr_cell[cell_id].head = &(bkt_pond->arr_bkt[free_bkt_id->getfront()]);
		    free_bkt_id->pop();
			grid->arr_cell[cell_id].nB++;
		}
		if (grid->arr_cell[cell_id].head->nO >= config->max_bucket_len)
		{
			bkt_pond->arr_bkt[free_bkt_id->getfront()].nxt = grid->arr_cell[cell_id].head;
			grid->arr_cell[cell_id].head = &(bkt_pond->arr_bkt[free_bkt_id->getfront()]);
			free_bkt_id->pop();
			grid->arr_cell[cell_id].nB++;
		}
		grid->arr_cell[cell_id].head->writeObj(oid, x, y, vx, vy, ts);

		secindex->index[oid].idx_cell = cell_id;
		secindex->index[oid].idx_bkt = grid->arr_cell[cell_id].nB - 1;
		secindex->index[oid].idx_obj = grid->arr_cell[cell_id].head->nO - 1;
	}
	fclose(fp);   
	cout << "GridandSecIndex Initial Completed..." << endl;
}

void CtorUpdateBuffer() // 构造一个包含1000万(25段)更新请求的缓冲区; 大小：240M;
{
	cudaMallocManaged(&orig_buffer_update, sizeof(UpdateBuffer));
	orig_buffer_update->len = config->block_size_update * 25;
	cudaMallocManaged(&(orig_buffer_update->buffer_update), orig_buffer_update->len * sizeof(UpdateType));
	for (int i = 0; i < orig_buffer_update->len; i++)
	{
		orig_buffer_update->buffer_update[i].oid = -1;
		orig_buffer_update->buffer_update[i].x = -1;
		orig_buffer_update->buffer_update[i].y = -1;
		orig_buffer_update->buffer_update[i].vx = -1;
		orig_buffer_update->buffer_update[i].vy = -1;
		orig_buffer_update->buffer_update[i].ts = -1;
	}
	cout << "UpdateBuffer Initial Completed..." << endl;
}

void WriteUpdateBuffer()
{
	UpdateType upd;
	for (int i = 0; i < orig_buffer_update->len; i++)
	{
		fscanf(fp1, "%d %f %f %f %f %f\n", &upd.oid, &upd.x, &upd.y, &upd.vx, &upd.vy, &upd.ts);
		orig_buffer_update->buffer_update[i] = upd;
	}
}
	
void CtorQueryBuffer() // 构造一个包含400万(100段，全部查询请求)的缓冲区；大小：96M;
{
	cudaMallocManaged(&orig_buffer_query, sizeof(QueryBuffer));
	orig_buffer_query->len = config->block_size_query * 100;
	cudaMallocManaged(&(orig_buffer_query->buffer_query), orig_buffer_query->len * sizeof(QueryType));
    for (int i = 0; i < orig_buffer_query->len; i++)
	{
		orig_buffer_query->buffer_query[i].qid = -1;
		orig_buffer_query->buffer_query[i].minX = -1;
		orig_buffer_query->buffer_query[i].minY = -1;
		orig_buffer_query->buffer_query[i].maxX = -1;
		orig_buffer_query->buffer_query[i].maxY = -1;
		orig_buffer_query->buffer_query[i].ts = -1;
	}
	cout << "QueryBuffer Initial Completed..." << endl;
}

void WriteQueryBuffer()
{
	QueryType que;
	for (int i = 0; i < orig_buffer_query->len; i++)
	{
		fscanf(fp2, "%d %f %f %f %f %f\n", &que.qid, &que.minX, &que.minY, &que.maxX, &que.maxY, &que.ts);
		orig_buffer_query->buffer_query[i] = que;
	}
}

void CtorCacheUpdate()
{
	cudaMallocManaged(&cache_update, sizeof(UpdateCacheArea));
	cache_update->cell_num = config->edge_cell_num * config->edge_cell_num;
	cache_update->seg = config->len_seg_cache_update;
	cache_update->len = cache_update->cell_num * cache_update->seg;
	
	cudaMallocManaged(&(cache_update->mtx_delete), cache_update->len * sizeof(int));
	cudaMallocManaged(&(cache_update->mtx_insert), cache_update->len * sizeof(UpdateType));
	cudaMallocManaged(&(cache_update->mtx_fresh), cache_update->len * sizeof(UpdateType));
	for (int i = 0; i < cache_update->len; i++)
	{
		cache_update->mtx_delete[i] = -1;
		
		cache_update->mtx_insert[i].oid = -1;
		cache_update->mtx_insert[i].x = -1;
		cache_update->mtx_insert[i].y = -1;
		cache_update->mtx_insert[i].vx = -1;
		cache_update->mtx_insert[i].vy = -1;
		cache_update->mtx_insert[i].ts = -1;

		cache_update->mtx_fresh[i].oid = -1;
		cache_update->mtx_fresh[i].x = -1;
		cache_update->mtx_fresh[i].y = -1;
		cache_update->mtx_fresh[i].vx = -1;
		cache_update->mtx_fresh[i].vy = -1;
		cache_update->mtx_fresh[i].ts = -1;
	}

	cudaMallocManaged(&(cache_update->sum_d), cache_update->cell_num * sizeof(int));
	cudaMallocManaged(&(cache_update->sum_i), cache_update->cell_num * sizeof(int));
	cudaMallocManaged(&(cache_update->sum_f), cache_update->cell_num * sizeof(int));
	for (int i = 0; i < cache_update->cell_num; i++)
	{
		cache_update->sum_d[i] = 0;
		cache_update->sum_i[i] = 0;
		cache_update->sum_f[i] = 0;
	}
	cout << "CacheUpdate Initial Completed..." << endl;
}

void CtorCacheQuery()
{
	cudaMallocManaged(&cache_query, sizeof(QueryCacheArea));
	cache_query->que_num = config->block_size_query;
	int l = (int)config->query_width + 1; // l 为查询区域方形的边长 - 1；
	cache_query->seg1 = (l - 1) * (l - 1);
	cache_query->seg2 = 4 * l;
	cache_query->len1 = cache_query->que_num * cache_query->seg1;
	cache_query->len2 = cache_query->que_num * cache_query->seg2;
	cudaMallocManaged(&(cache_query->total), cache_query->len1 * sizeof(int));
	for (int i = 0; i < cache_query->len1; i++) cache_query->total[i] = -1;
	cudaMallocManaged(&(cache_query->partial), cache_query->len2 * sizeof(int));
	for (int i = 0; i < cache_query->len2; i++) cache_query->partial[i] = -1;
	cudaMallocManaged(&(cache_query->cnt1), cache_query->que_num * sizeof(int));
	for (int i = 0; i < cache_query->que_num; i++) cache_query->cnt1[i] = 0;
	cudaMallocManaged(&(cache_query->cnt2), cache_query->que_num * sizeof(int));
	for (int i = 0; i < cache_query->que_num; i++) cache_query->cnt2[i] = 0;
	cout << "CacheQuery Initial Completed..." << endl;
}

void CtorQueryOut()
{
	cudaMallocManaged(&query_out, sizeof(QueryOut));
	query_out->query_num = config->block_size_query;
	query_out->seg = config->len_seg_query_out;
	query_out->len = query_out->query_num * query_out->seg;
	cudaMallocManaged(&(query_out->obj_id), query_out->len * sizeof(int));
	for (int i = 0; i < query_out->len; i++) query_out->obj_id[i] = -1;
	cudaMallocManaged(&(query_out->cnt), query_out->query_num * sizeof(int));
	for (int i = 0; i < query_out->query_num; i++) query_out->cnt[i] = 0;
	cout << "QueryOut Initial Completed..." << endl;
}

void Dtor()
{
    cudaFree(config);
	cudaFree(bkt_pond);
	cudaFree(free_bkt_id);
	cudaFree(grid);
	cudaFree(secindex);
	cudaFree(orig_buffer_update);
	cudaFree(orig_buffer_query);
	cudaFree(cache_update);  
	cudaFree(cache_query);
	cudaFree(query_out);
    cudaStreamDestroy(stream1);
    cudaStreamDestroy(stream2);
    cudaStreamDestroy(stream3);     
	cudaEventDestroy(start1);
	cudaEventDestroy(stop1);
    fclose(fp1);
	fclose(fp2);
}


