#ifndef BUCKET_H_
#define BUCKET_H_
#include "BaseStruct.h"

class Bucket
{
public:
    int bid;
    Bucket *nxt;
	ObjBox *arr_obj;
	int nO;
public:
    Bucket()
	{
		bid = -1;
		nxt = NULL;
		arr_obj = NULL;
		nO = 0;
	}
    void writeObj(int id, float val_x, float val_y, float vx, float vy, float time)
    {
    	arr_obj[nO].oid = id;
    	arr_obj[nO].x = val_x;
    	arr_obj[nO].y = val_y;
    	arr_obj[nO].vx = vx;
    	arr_obj[nO].vy = vy;
    	arr_obj[nO].ts = time;
    	nO++;
    }
};

class Bktpond
{
public:
	int bkt_num;
	Bucket *arr_bkt;
public:
	Bktpond()
	{
		bkt_num = 0;
		arr_bkt = NULL;
	}
};
#endif

