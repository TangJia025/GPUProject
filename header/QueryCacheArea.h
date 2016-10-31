#ifndef QUERYCACHEAREA_H_
#define QUERYCACHEAREA_H_

class QueryCacheArea
{
public:
	int que_num;
	int seg1, seg2;
	int len1, len2;

	int *total;
	int *partial;
	int *cnt1, *cnt2;
public:
	QueryCacheArea()
	{
		que_num = 0;
		seg1 = seg2 = 0;
		len1 = len2 = 0;

		total = partial = NULL;
		cnt1 = cnt2 = NULL;
	}
};

#endif
