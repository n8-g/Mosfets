#include <stdlib.h>
#include <stdio.h>
#include <png.h>

#define WIDTH 32
#define HEIGHT 32
#define DEPTH 3

unsigned int image[HEIGHT*DEPTH];

int load_png_rgba(unsigned int* image, FILE* file)
{
	u_int8_t* rows[HEIGHT];
	u_int8_t data[HEIGHT][WIDTH*4];
	u_int8_t header[8];
	png_uint_32 w,h;
	int d,t,i;
	fread(header,1,8,file);
	if (png_sig_cmp(header, 0, 8)) return -1;   
	png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
    if (!png_ptr) return -2;

    png_infop info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
    {
        png_destroy_read_struct(&png_ptr, NULL, NULL);
        return -2;
    }
    png_infop end_info = png_create_info_struct(png_ptr);
    if (!end_info)
    {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        return -2;
    }
	png_init_io(png_ptr, file);
	png_set_sig_bytes(png_ptr, 8);
	png_read_info(png_ptr,info_ptr);
	png_get_IHDR(png_ptr,info_ptr,&w,&h,&d,&t,NULL,NULL,NULL);
	if (w != WIDTH || h != HEIGHT)
	{
		fprintf(stderr,"Image must be %dx%d\n",WIDTH,HEIGHT);
		exit(-1);
	}
	// Convert to RGB
	if (t == PNG_COLOR_TYPE_PALETTE)
		png_set_palette_to_rgb(png_ptr);    
	else if (t == PNG_COLOR_TYPE_GRAY || t == PNG_COLOR_TYPE_GRAY_ALPHA)
        png_set_gray_to_rgb(png_ptr);    
    // Adjust depth
    if (d < 8)
        png_set_packing(png_ptr);
	if (d == 16) png_set_strip_16(png_ptr);
	if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) png_set_tRNS_to_alpha(png_ptr);    
	else if (t == PNG_COLOR_TYPE_RGB || t == PNG_COLOR_TYPE_GRAY)
        png_set_filler(png_ptr, 0xFF, PNG_FILLER_AFTER);
	
	for(i = 0; i < HEIGHT; ++i) 
		rows[i]=data[i];
	png_read_image(png_ptr, rows);
	png_read_end(png_ptr,NULL);
	png_destroy_read_struct(&png_ptr,&info_ptr,NULL);
	
	for (i = 0 ; i < HEIGHT; ++i)
	{
		int j,k;
		for (j = 0; j < WIDTH; ++j)
		{
			unsigned char v = (data[i][j*4]+data[i][j*4+1]+data[i][j*4+2]) / 3;
			for (k = 0; k < DEPTH; ++k)
				image[i+k*HEIGHT] |= ((v>>(7-k)) & 0x1) << j;
		}
	}
	return 0;
}

int main(int argc, char* argv[])
{
	int i,j;
	FILE* in, *out;
	if (argc < 3)
	{
		printf("usage: %s inimage outimage\n",argv[0]);
		return -1;
	}
	in = fopen(argv[1],"rb");
	if (!in)
	{
		fprintf(stderr,"Failed to open '%s'\n",argv[1]);
		return -1;
	}
	load_png_rgba(image, in);
	fclose(in);
	out = fopen(argv[2],"wb");
	if (!out)
	{
		fprintf(stderr,"Failed to open '%s'\n",argv[2]);
		return -1;
	}
	for (i = 0; i < HEIGHT*DEPTH; ++i)
		for (j = 0; j < WIDTH; j += 8)
			fputc((image[i]>>j)&0xFF,out);
	fclose(out);
	return 0;
}