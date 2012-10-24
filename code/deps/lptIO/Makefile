# !IMPORTANT
# Set these three variables to match your system
# MATLABROOT = "C:/Program Files (x86)/MATLAB/R2010b"
# CC = "C:/MINGW/bin/mingw32-gcc"
MATLABROOT = "d:/dev/MATLAB/R2011b"
CC = "d:/dev/MINGW/bin/mingw32-gcc"

# Determine platform
PLATFORM = $(shell $(CC) -dumpmachine)

# Flags depending on platform
ifeq "$(PLATFORM)" "mingw32"
SUFFIX = .mexw32
INPOUT_DLL = inpout32.dll
LIBPATH = -L$(MATLABROOT)/extern/lib/win32/microsoft -L$(MATLABROOT)/bin/win32

else ifeq "$(PLATFORM)" "x86_64-w64-mingw32"
SUFFIX = .mexwx64
INPOUT_DLL = inpoutx64.dll
LIBPATH = -L$(MATLABROOT)/extern/lib/winx64/microsoft -L$(MATLABROOT)/bin/winx64

else
$(error "Unknown platform")
endif

# Common flags for all platforms
INCPATH = -I$(MATLABROOT)/extern/include -I.
LIBS = -lmex -lmx 
CFLAGS = $(INCPATH) -Wunused -Wall -pedantic -O3 -g $(FLAGS)
LDFLAGS = $(LIBPATH) -shared -Wl $(LIBS)

all: lptwrite$(SUFFIX) lptread$(SUFFIX)
	
clean:
	del *.o
	del *$(SUFFIX)

lptwrite.o: lptwrite.c inpout32.h
	$(CC) -c lptwrite.c $(CFLAGS)

lptwrite$(SUFFIX): lptwrite.o $(INPOUT_DLL)
	$(CC) -o $@ $^ $(LDFLAGS) 

lptread.o: lptread.c inpout32.h
	$(CC) -c lptread.c $(CFLAGS)

lptread$(SUFFIX): lptread.o $(INPOUT_DLL)
	$(CC) -o $@ $^ $(LDFLAGS) 
