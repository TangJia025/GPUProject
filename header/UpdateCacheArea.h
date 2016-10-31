#ifndef UPDATECACHEAREA_H_
#define UPDATECACHEAREA_H_
#include "BaseStruct.h"

class UpdateCacheArea
{
public:
	int cell_num;
	int seg;
	int len;

	int *mtx_delete;
	int *sum_d;
	UpdateType *mtx_insert;
	int *sum_i;
	UpdateType *mtx_fresh;
	int *sum_f;
public:
	UpdateCacheArea(void)
	{
		cell_num = seg = len = 0;
		mtx_delete = NULL;
		mtx_insert = mtx_fresh = NULL;
		sum_d = sum_i = sum_f = NULL;
	}
};

#endif 
