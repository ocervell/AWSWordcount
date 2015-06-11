/**
MPI Sort
Author: Lucas Rena lrenades@hawk.iit.edu
**/
#include <stdio.h>
#include <mpi.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

/* qsort comparison function */ 
int compare_lines(const void *a, const void *b) 
{ 
    const char **ia = (const char **)a;
    const char **ib = (const char **)b;
    return strcmp(*ia, *ib);
} 

/*Merges all ordered results sent from worker nodes and stored at buf. Output final result to file.*/
void mergeResults(char *buf, int bufSize, int nprocs, int  nlines, int lineSize, char *filename){
	int p[nprocs], i, i_lowest, outSize = 0;
	char *lowest = (char*)malloc(lineSize*sizeof(char));

        FILE *pFile = fopen(filename, "w");
	
	for(i = 0; i < nprocs; i++){
		p[i] = i * (nlines/nprocs)*lineSize;
	}
	
	while(outSize < nlines) {
		for(i = 0; i < nprocs; i++) {
			if(p[i] < bufSize) {
				i_lowest = i;
				break;
			}
		}
		memcpy(lowest, &buf[p[i_lowest]], lineSize);
		lowest[lineSize] = '\0';
		for(i = 0; i < nprocs; i++){
			if(p[i] < nlines*lineSize) {
				if(strncmp(&buf[p[i]], lowest, lineSize) < 0) {
					i_lowest = i;
					memcpy(lowest, &buf[p[i]], lineSize);
				}
			}
		}
		lowest[lineSize] = '\0';
		fprintf(pFile, "%s", lowest);
		p[i_lowest]+=lineSize;
		outSize++;
	}
	fclose(pFile);	
}

/*Sorting function executed by each node on its assigned dataset*/
void sortSection(char *section, int sectionSize, int lineSize, int rank) {
	int nLines = sectionSize/lineSize;
	char **strings;
	int i;
	strings = (char **)malloc(nLines*sizeof(char *));

	for(i = 0; i < nLines; i++) {
		strings[i] = (char*)malloc(lineSize);
		memcpy(strings[i], &section[i*lineSize], lineSize);
		strings[i][lineSize] = '\0';
	}
	size_t num_strings = (size_t) nLines;
    	
	/* sort array using qsort functions */ 
    	qsort(strings, num_strings, sizeof(char *), compare_lines);
 

        for(i = 0; i < nLines; i++) {
                memcpy(&section[i*lineSize], strings[i], lineSize);
        }
}

int main(int argc, char **argv) {

    MPI_File in, out;
    MPI_Status status;
    MPI_Offset filesize;
    MPI_Datatype type_line;

    int rank, nprocs;
    int ierr;
    char *bufin, *bufout;
    int wordsize = 10, linesize = 100, bufoutsize;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

    if (argc != 3) {
        if (rank == 0) fprintf(stderr, "Usage: %s infilename outfilename\n", argv[0]);
        MPI_Finalize();
        exit(1);
    }

    ierr = MPI_File_open(MPI_COMM_WORLD, argv[1], MPI_MODE_RDONLY, MPI_INFO_NULL, &in);
    if (ierr) {
        if (rank == 0) fprintf(stderr, "%s: Couldn't open file %s\n", argv[0], argv[1]);
        MPI_Finalize();
        exit(2);
    }
 

    MPI_File_get_size(in, &filesize); 
    int nlines = filesize/linesize;
    bufoutsize = filesize*nprocs;
    bufin = (char *) malloc( filesize );
    
    MPI_File_seek(in, 0, MPI_SEEK_SET);
    MPI_File_read(in, bufin, filesize, MPI_CHAR, &status);

    if(rank == 0) {
        printf("\nRunning MPI-Sort for %d registers on %d nodes\n", nlines*nprocs, nprocs);
    }
    
    sortSection(bufin, filesize, linesize, rank);

    int i;
    if( nprocs != 1) {  
    bufout = (char *) malloc(bufoutsize);
    for(i = 0; i < bufoutsize; i++) {
  	bufout[i] = 'x';
    }
    }

    MPI_Type_contiguous(linesize, MPI_CHAR, &type_line);
    MPI_Type_commit(&type_line);

    if( nprocs == 1) {
       MPI_Gather(bufin, nlines, type_line, bufin, nlines, type_line, 0, MPI_COMM_WORLD);
    }
    else {
       MPI_Gather(bufin, nlines, type_line, bufout, nlines, type_line, 0, MPI_COMM_WORLD);
    }
    if (rank == 0) {
        printf("\nMerging results...\n");
	if(nprocs == 1) 
		mergeResults(bufin, filesize,  nprocs, nlines*nprocs, linesize, argv[2]);
	else
		mergeResults(bufout, filesize,  nprocs, nlines*nprocs, linesize, argv[2]);
    }   

    MPI_File_close(&in);
    
    if (rank == 0) {
        printf("\nFinished successfully. Sorted results at file: %s .\n", argv[2]);
    }
    MPI_Finalize();
    return 0;
}
