#ifndef GRID_H_
#define GRID_H_
#include <math.h>
#include "Bucket.h"

class Cell
{
public:
    Bucket *head;
	int nB;
public:
    Cell(void)
	{
		nB = 0;
		head = NULL;
	}
	Cell(const Cell &cell)
	{
		nB = cell.nB;
		*head = *(cell.head);
	}
};

class Grid
{
public:
    int cell_num;              
    Cell *arr_cell;
public:
    Grid(void)
	{
		cell_num = 0;
		arr_cell = NULL;
	}
	Grid(const Grid &grid)
	{
		cell_num = grid.cell_num;
 		*arr_cell = *(grid.arr_cell);
	}
    static int getCellByXY(float x,float y, int n)
    {
		return floor(x) * n + floor(y);
    }
};

#endif 
