#ifndef CONFIG_H_
#define CONFIG_H_

class Config 
{
public:
    float region_xmin;
    float region_xmax;
    float region_ymin;
    float region_ymax;
    int gaussian_data;      
    int max_bucket_len;
	int bucket_num;
    int block_analysis_num;
    int block_update_num;        
    int block_query_num;         //num of block for query
    int thread_analysis_num;       
	float query_width_rate;
	float obj_move_speed;

    int max_obj_num;    
    int max_update_num;
    int max_query_num;
    int hotspot_num;    
    int edge_cell_num;       
    int block_size_update;
	int block_size_query;
    int len_seg_cache_update;
    int len_seg_query_out;
	float query_width;
private:
    Config()
    {
    	edge_cell_num = 128;
    	gaussian_data = 1;
    	hotspot_num = 10;
    	max_bucket_len = 1000;
    	bucket_num = 22000;
        query_width_rate = 0.002;

	    region_xmin = 0;
    	region_xmax = edge_cell_num - 1;
    	region_ymin = 0;
	    region_ymax = edge_cell_num - 1;
    	max_obj_num = 10000000;
    	max_update_num = 40000000;
    	max_query_num = 4000000; 
    	block_analysis_num = 3;
    	block_update_num = 4;
    	block_query_num = 8;
    	thread_analysis_num = 1024; 
    	block_size_update = 400000;
    	block_size_query = 40000;
    	len_seg_cache_update = 100; 
    	len_seg_query_out = 100;
    	obj_move_speed = 1;
    	query_width = edge_cell_num * query_width_rate;
    }  
};

#endif 
