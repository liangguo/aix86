##################################################################
# Licensed Materials - Property of IBM.
# (C) Copyright IBM Corporation 2001, 2005
# All Rights Reserved.
#
# US Government Users Restricted Rights -
# Use, duplication or disclosure restricted by
# GSA ADP Schedule Contract with IBM Corporation.


CFLAGS =  -mpowerpc -g

TGTS	= callthru

all: $(TGTS)

callthru: callthru.o
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $<

tidy:
	$(RM) *.o *~

clean:
	$(RM) $(TGTS)
