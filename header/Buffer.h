#ifndef BUFFER_H_
#define BUFFER_H_
#include "BaseStruct.h"

class Buffer
{
public:
	int *bkt_id;
	int front;
	int rear;
	int len;
public:
	Buffer()
	{
		bkt_id = NULL;
		front = rear = len = 0;
	}
	void push(int i)
	{
		bkt_id[rear++] = i;
	}
	void pop()
	{
		bkt_id[front++] = -1;
	}
	int getfront()
	{
		return bkt_id[front];
	}
	int getrear()
	{
		return bkt_id[rear];
	}
};

class UpdateBuffer
{
public:
	UpdateType *buffer_update;
	unsigned int len;
public:
    UpdateBuffer()
	{
		buffer_update = NULL;
		len = 0;
	}
};

class QueryBuffer
{
public:
	int len;
	QueryType *buffer_query;
public:
	QueryBuffer()
	{
		len = 0;
		buffer_query = NULL;
	}
};
#endif

