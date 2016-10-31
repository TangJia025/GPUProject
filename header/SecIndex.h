#ifndef SECINDEX_H_
#define SECINDEX_H_

class SIEntry
{
public:
    int idx_cell;
    int idx_bkt;
    int idx_obj;
public:
    SIEntry()
	{
		idx_cell = idx_bkt = idx_obj = -1;
	}
};

class SecIndex
{
public:
    SIEntry *index;
	int nI;
public:
    SecIndex()
	{
		index = NULL;
		nI = 0;
	}
};
#endif
