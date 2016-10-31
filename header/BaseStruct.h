#ifndef BASESTRUCT_H_
#define BASESTRUCT_H_

class Point
{
public:
	float x;
	float y;
public:
	Point(){ x = y = -1;}
};

class UpdateType
{
public:
	int oid;
    float x;
    float y;
	float vx;
	float vy;
    float ts;
public:
	UpdateType()
	{
		oid = -1;
		x = y = vx = vy = ts = -1;
	}
/*	__host__ __device__ UpdateType& operator=(UpdateType &upd)
	{
		oid = upd.oid;
		x = upd.x;
		y = upd.y;
		vx = upd.vx;
		vy = upd.vy;
		ts = upd.ts;
		return *this;
	}   */
};

class QueryType
{
public:
	int	qid;
	float minX; 
	float minY;
	float maxX;
	float maxY;
	float ts;
public:
	QueryType()
	{
		qid = -1;
		minX = minY = maxX = maxY = ts = -1;
	}
};

class ObjBox
{
public:
	int oid;
	float x;
	float y;
	float vx;
	float vy;
	float ts;
public:
	ObjBox()
	{
		oid = -1;
		x = y = vx = vy = ts = -1;
	}
};

#endif 
