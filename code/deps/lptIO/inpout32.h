#ifndef INPOUT32_H
#define INPOUT32_H

#include <windows.h>

#ifndef __cplusplus
#define BOOL	int
#define FALSE	0
#define TRUE	1
#endif

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Functions exported from DLL.
 * For easy inclusion is user projects.
 * Original InpOut32 function support
 */
void	__cdecl Out32(unsigned int PortAddress, short data);
short	__cdecl Inp32(unsigned int PortAddress);

/* My extra functions for making life easy */
BOOL	__cdecl IsInpOutDriverOpen(); /* Returns TRUE if the InpOut driver was opened successfully */
BOOL	__cdecl IsXP64Bit();          /* Returns TRUE if the OS is 64bit (x64) Windows. */

/* DLLPortIO function support */
UCHAR   __cdecl DlPortReadPortUchar (USHORT port);
void    __cdecl DlPortWritePortUchar(USHORT port, UCHAR Value);

USHORT  __cdecl DlPortReadPortUshort (USHORT port);
void    __cdecl DlPortWritePortUshort(USHORT port, USHORT Value);

ULONG	__cdecl DlPortReadPortUlong(ULONG port);
void	__cdecl DlPortWritePortUlong(ULONG port, ULONG Value);

/* WinIO function support (Untested and probably does NOT work - esp. on x64!) */
PBYTE	__cdecl MapPhysToLin(PBYTE pbPhysAddr, DWORD dwPhysSize, HANDLE *pPhysicalMemoryHandle);
BOOL	__cdecl UnmapPhysicalMemory(HANDLE PhysicalMemoryHandle, PBYTE pbLinAddr);
BOOL	__cdecl GetPhysLong(PBYTE pbPhysAddr, PDWORD pdwPhysVal);
BOOL	__cdecl SetPhysLong(PBYTE pbPhysAddr, DWORD dwPhysVal);

#ifdef __cplusplus
}
#endif

#endif
