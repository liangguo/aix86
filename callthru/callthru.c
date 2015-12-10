/* -------------------------------------------------------
 *
 * Licensed Materials - Property of IBM.
 * (C) Copyright IBM Corporation 2001, 2005
 * All Rights Reserved.
 *
 * US Government Users Restricted Rights -
 * Use, duplication or disclosure restricted by
 * GSA ADP Schedule Contract with IBM Corporation.
 *
 * Filename : callthru.c
 *
 * Purpose  :
 *
 * Callthru is an executable that performs special
 * call-through operations to the simulator
 * This executable gets run on the simulated machine
 *
 * CVS INFO:
 *
 * $Id$
 *
 * ------------------------------------------------------- */
#include <stdio.h>
#include <sys/mman.h>      /* mlock, munlock */
#include <string.h>        /* strcmp */

#include "callthru_config.h"

#define PAGE_SIZE  4096

char raw_buffer[PAGE_SIZE*2];

void usage(void);

/* --------------------------------------------------------------------------
 * CALLTHRU EXIT ROUTINES
 * -------------------------------------------------------------------------- */
static void callthru_exit (int argc, char **argv)
{
    (void) MamboStopSimulation();
    exit(0);              /* if not, just exit! */
}

/* --------------------------------------------------------------------------
 * CALLTHRU SINK & SOURCE ROUTINES
 * -------------------------------------------------------------------------- */
int callthru_sink (int argc, char *argv[])
{
    char *fname;
    char *buffer;
    int rlen, wlen, rc;

    /*
     * Make sure file name was given
     */
    if (argc < 2 || argv[1][0] == '-')
        usage();
    fname = argv[1];         /* set file name */

    /*
     * Pin one page of buffer and use that for communication with simulator
     */
    buffer = (char *) ((((unsigned long)raw_buffer)+(PAGE_SIZE-1)) & ~(PAGE_SIZE-1));
    rc = mlock(buffer, PAGE_SIZE);
    if (rc != 0)
        {
            perror("mlock failed");
            return(-1);
        }

    /*
     * Open the file on the host file system
     */
    strcpy(buffer, fname);
    rc = MamboFileOpen(buffer, 'w');
    if (rc != 0)
        {
            fprintf(stderr, "Cannot open file \"%s\"; Simulator rejected attempt (%d)\n", buffer, rc);
            goto sink_done;
        }

    /*
     * Read data from stdin, write it to a file on the host file system
     * Return code from simulator is number of chars copied from buffer to file; 0 means an error has happened.
     */
    while (rlen = fread(buffer, 1, PAGE_SIZE, stdin))
        {
            wlen = MamboFileWrite(buffer, rlen);
            if (wlen != rlen)
                {
                    fprintf(stderr, "MamboWriteWrite failed\n");
                    rc = -1;
                    break;
                }
        }

    MamboFileClose();

 sink_done:
    if (0 != munlock(buffer, PAGE_SIZE))
        perror("munlock failed");

    exit( (rc == 0) ? 0 : -1);
}


int callthru_source (int argc, char *argv[])
{
    char *fname;
    char *buffer;
    int rlen, wlen, rc;

    /*
     * Make sure file name was given
     */
    if (argc < 2 || argv[1][0] == '-')
        usage();
    fname = argv[1];         /* set file name */

    /*
     * Pin one page of buffer and use that for communication with simulator
     */
    buffer = (char *) ((((unsigned long)raw_buffer)+(PAGE_SIZE-1)) & ~(PAGE_SIZE-1));
    rc = mlock(buffer, PAGE_SIZE);
    if (rc != 0)
        {
            perror("mlock failed");
            return(-1);
        }

    /*
     * Open the file on the host file system
     */
    strcpy(buffer, fname);
    rc = MamboFileOpen(buffer, 'r');
    if (rc != 0)
        {
            fprintf(stderr, "Cannot open file \"%s\"; Simulator rejected attempt (%d)\n", buffer, rc);
            goto source_done;
        }

    /*
     * Read data from a file on the host file system, write it to stdout.
     * Return code from simulator is number of chars copied to buffer; 0 means end-of-file reached.
     */
    while (rlen = MamboFileRead(buffer))
        {
            wlen = fwrite(buffer, 1, rlen, stdout);
            if (rlen != wlen)
                {
                    fprintf(stderr, "Write to stdout failed\n");
                    rc = -1;
                    break;
                }
        }

    MamboFileClose();

 source_done:
    if (0 != munlock(buffer, PAGE_SIZE))
        perror("munlock failed");

    /* should close stdout */
    fclose(stdout);

    exit( (rc == 0) ? 0 : -1);
}

int StrCaseEqual(const char *a, const char *b)
{
    if ((a == NULL) || (b == NULL))
        return(0);
    else
        return(strcasecmp(a, b) == 0);
}

void usage(void)
{
    fprintf(stderr, "Usage : callthru [exit|sink|source] ...\n");
    fprintf(stderr, "        exit\n");
    fprintf(stderr, "            Stop the simulation.\n");
    fprintf(stderr, "        sink host-file-name\n");
    fprintf(stderr, "            Copy stdin from simulated system to host file system.\n");
    fprintf(stderr, "            Example : callthru sink /tmp/foobar<foobar\n");
    fprintf(stderr, "            will copy foobar from the simulator's current\n");
    fprintf(stderr, "            directory to /tmp/foobar on the host\n");
    fprintf(stderr, "        source host-file-name\n");
    fprintf(stderr, "            Copy file from host file system to stdout of simulated system.\n");
    fprintf(stderr, "            Example : callthru source /tmp/foobar>foobar\n");
    fprintf(stderr, "            will copy /tmp/foobar from the host\n");
    fprintf(stderr, "            to foobar in the simulator's current directory\n");

    exit(-1);
}

/* --------------------------------------------------------------------------
 * MAIN
 * -------------------------------------------------------------------------- */
int main (int argc, char *argv[])
{
    int rc = -1;

    /*
     * If an argument was given, convert it to an integer
     */
    if (argc < 2)
        usage();

    /* Exit */
    else if (StrCaseEqual(argv[1], "exit"))
        {
            callthru_exit(argc - 1, &(argv[1]));
            rc = 0;
        }
    /* Sink */
    else if (StrCaseEqual(argv[1], "sink"))
        {
            rc = callthru_sink(argc - 1, &(argv[1]));
        }
    /* Source */
    else if (StrCaseEqual(argv[1], "source"))
        {
            rc = callthru_source(argc - 1, &(argv[1]));
        }
    /* Shouldn't get here */
    else usage();

    return(rc);
}
