#ifndef QUERYOUT_H_
#define QUERYOUT_H_

class QueryOut
{
public:
	int query_num;
	int seg;
    int len;
	int *obj_id;
	int *cnt;
public:
	QueryOut()
	{
		query_num = seg = len = 0;
		obj_id = cnt = 0;
	}
};

#endif
