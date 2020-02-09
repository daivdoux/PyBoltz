from PyBoltz cimport PyBoltz
from libc.math cimport sin, cos, acos, asin, log, sqrt, pow, tan, atan
from libc.string cimport memset
from PyBoltz cimport drand48
from MBSorts cimport MBSortT
from libc.stdlib cimport malloc, free
import cython
from Townsend.CollisionFrequencyCalc import COLF
from Townsend.CollisionFrequencyCalc import COLFT
import numpy as np
cimport numpy as np
import sys
import sys

@cython.cdivision(True)
@cython.boundscheck(False)
@cython.wraparound(False)
cpdef run(PyBoltz Object, int ConsoleOuput):
    cdef int JPrint, K = 0
    cdef double ESST[9], VDSST[9], WSSST[9], DXSST[9], DYSST[9], WTEMP[9], DRSST[9], ALFNE[9], ALFNJ[9], ALFN[9], ZSST[9], DLSST[9], DRSS1[9], DRSS2[9], DRSS3[9], ALFEX1[9], NEPL[9]
    cdef double FREQ, FREEL, FRION, FRATT, FREIN, NTOTAL, CORF, CORERR, DXFIN, DYFIN, DLFIN, ALNGTH, ALFIN
    cdef double ANST[9]
    # Calculate total attachment and ionisation rates
    JPrint = Object.NumberOfSpaceSteps
    # calculate number of electrons at each plane
    NEPL[1] = Object.IPrimary + Object.NumberOfElectronSST[1]
    for K in range(2, JPrint + 1):
        NEPL[K] = NEPL[K - 1] + Object.NumberOfElectronSST[K]
    # Substitute NEPL for NumberOfElectronSST
    for K in range(1, JPrint + 1):
        Object.NumberOfElectronSST[K] = NEPL[K]
    for K in range(1, JPrint + 1):
        if Object.NumberOfElectronSST[K] == 0:
            JPrint = K - 1
            break

    ESST[1] = Object.SEPlanes[1] / Object.STSPlanes[1]
    ZSST[1] = Object.SZPlanes[1] / Object.STSPlanes[1]

    VDSST[1] = Object.SVZPlanes[1] / Object.STSPlanes[1]
    WTEMP[1] = Object.SpaceStepZ * Object.STSPlanes[1] / Object.TMSPL[1]
    WSSST[1] = WTEMP[1]

    DXSST[1] = ((Object.SX2Planes[1] / Object.STSPlanes[1]) - (Object.SXPlanes[1] / Object.STSPlanes[1]) ** 2) * WSSST[
        1] / (2 * Object.SpaceStepZ)

    DYSST[1] = ((Object.SY2Planes[1] / Object.STSPlanes[1]) - (Object.SYPlanes[1] / Object.STSPlanes[1]) ** 2) * WSSST[
        1] / (2 * Object.SpaceStepZ)

    DLSST[1] = ((Object.TTMSPL[1] / Object.STSPlanes[1]) - (Object.TMSPL[1] / Object.STSPlanes[1]) ** 2) * WSSST[
        1] ** 3 / (2 * Object.SpaceStepZ)

    # Get ionisation and attachment frequencies
    if Object.EnableThermalMotion:
        FREQ, FREEL, FRION, FRATT, FREIN, NTOTAL = COLFT.run(Object)
    else:
        FREQ, FREEL, FRION, FRATT, FREIN, NTOTAL = COLF.run(Object)

    # Correction for fake ionisation
    CORF = (FRION - FRATT) / (Object.FakeIonisationsEstimate + FRION - FRATT)
    Object.AttachmentOverIonisation = FRATT / FRION
    CORERR = abs((Object.FakeIonisationsEstimate + FRION - FRATT) / (FRION - FRATT))

    if Object.NumberOfElectronSST[1] != 0:
        ALFNE[1] = CORF * (log(float(Object.NumberOfElectronSST[1])) - log(Object.IPrimary)) / Object.SpaceStepZ
    ALFNJ[1] = 0.0
    ALFN[1] = 0.0
    for J in range(2, JPrint + 1):
        ESST[J] = Object.SEPlanes[J] / Object.STSPlanes[J]
        ZSST[J] = Object.SZPlanes[J] / Object.STSPlanes[J]
        VDSST[J] = Object.SVZPlanes[J] / Object.STSPlanes[J]
        WTEMP[J] = Object.SpaceStepZ * J * Object.STSPlanes[J] / Object.TMSPL[J]
        WSSST[J] = (WTEMP[J] * WTEMP[J - 1]) / (J * WTEMP[J - 1] - (J - 1) * WTEMP[J])
        DXSST[J] = ((Object.SX2Planes[J] / Object.STSPlanes[J]) - (Object.SXPlanes[J] / Object.STSPlanes[J]) ** 2 - (
                Object.SX2Planes[J - 1] / Object.STSPlanes[J - 1]) + (
                            Object.SXPlanes[J - 1] / Object.STSPlanes[J - 1]) ** 2) * WSSST[J] / (
                           2 * Object.SpaceStepZ)

        DYSST[J] = ((Object.SY2Planes[J] / Object.STSPlanes[J]) - (Object.SYPlanes[J] / Object.STSPlanes[J]) ** 2 - (
                Object.SY2Planes[J - 1] / Object.STSPlanes[J - 1]) + (
                            Object.SYPlanes[J - 1] / Object.STSPlanes[J - 1]) ** 2) * WSSST[J] / (
                           2 * Object.SpaceStepZ)

        DLSST[J] = ((Object.TTMSPL[J] / Object.STSPlanes[J]) - (Object.TMSPL[J] / Object.STSPlanes[J]) ** 2 - (
                Object.TTMSPL[J - 1] / Object.STSPlanes[J - 1]) + (
                            Object.TMSPL[J - 1] / Object.STSPlanes[J - 1]) ** 2) * WSSST[J] ** 3 / (
                           2 * Object.SpaceStepZ)

        ALFN[J] = (log(Object.STSPlanes[J]) - log(Object.STSPlanes[J - 1])) / Object.SpaceStepZ

        ALFNJ[J] = (log(Object.STSPlanes[J] * VDSST[J]) - log(Object.STSPlanes[J - 1] * VDSST[J-1])) / Object.SpaceStepZ
        ALFNE[J] = 0.0

        if Object.NumberOfElectronSST[J] != 0 or Object.NumberOfElectronSST[J - 1] != 0:
            ALFNE[J] = (log(Object.NumberOfElectronSST[J]) - log(Object.NumberOfElectronSST[J - 1])) / Object.SpaceStepZ
        ALFN[J] = CORF * ALFN[J]
        ALFNE[J] = CORF * ALFNE[J]
        ALFNJ[J] = CORF * ALFNJ[J]

    DXFIN = ((Object.SX2Planes[JPrint] / Object.STSPlanes[JPrint]) - (
                Object.SXPlanes[JPrint] / Object.STSPlanes[JPrint]) ** 2) * WSSST[JPrint] / (
                           JPrint * 2 * Object.SpaceStepZ)
    DXFIN*=1e16

    DYFIN = ((Object.SY2Planes[JPrint] / Object.STSPlanes[JPrint]) - (
                Object.SYPlanes[JPrint] / Object.STSPlanes[JPrint]) ** 2) * WSSST[JPrint] / (
                           JPrint * 2 * Object.SpaceStepZ)
    DYFIN*=1e16


    DLFIN = ((Object.TTMSPL[JPrint] / Object.STSPlanes[JPrint]) - (
                Object.TMSPL[JPrint] / Object.STSPlanes[JPrint]) ** 2) * WSSST[JPrint]**3 / (
                           JPrint * 2 * Object.SpaceStepZ)
    DLFIN*=1e16

    ALNGTH = Object.SpaceStepZ* JPrint
    ALFIN = log(Object.NumberOfElectronSST[JPrint] / Object.IPrimary) / ALNGTH
    ALFIN *= 0.01
    for J in range(1,JPrint+1):
        VDSST[J] *=1e9
        WSSST[J] *=1e9
        DXSST[J] *=1e16
        DYSST[J] *=1e16
        DLSST[J] *=1e16
        ALFN[J] *=0.01
        ALFNJ[J] *= 0.01
        ALFNE[J] *=0.01

    print ('Steady state Townsend results for {} sequential space planes'.format(JPrint))
    print('{:^10s}{:^10s}{:^7s}{:^7s}{:^7s}{:^7s}{:^7s}{:^12s}{:^12s}{:^12s}'.format("Plane #", "NEL", "VD", "WS",
                                                                         "DL","DT","EBAR","ALFN","ALFNJ","ALFNE"))

    for J in range(1,JPrint+1):
        DRSST[J] = (DXSST[J]+DYSST[J])/2.0
        print('{:^10.1f}{:^10.1f}{:^7.1f}{:^7.1f}{:^7.1f}{:^7.1f}{:^7.1f}{:^12.1f}{:^12.1f}{:^12.1f}'.format(J, Object.NumberOfElectronSST[J], VDSST[J], WSSST[J],
                                                                                                             DLSST[J], DRSST[J], ESST[J], ALFN[J], ALFNJ[J], ALFNE[J]))
    if Object.NumberOfElectronSST[1]> Object.NumberOfElectronSST[5]:
        # Net attachment therefore take results from plane 2
        Object.VelocitySvzSST = VDSST[2]
        Object.VelocitySvzSSTErr = 100.0 * abs((VDSST[2] - VDSST[3]) / (2 * VDSST[2]))
        Object.WSOUT = WSSST[2]
        Object.WSERR = 100.0 * abs((WSSST[2]-WSSST[3])/(2* WSSST[2]))
        Object.LongitudinalDiffSST = DLSST[2]
        Object.LongitudinalDiffSSTErr = 100.0 * abs((DLSST[2] - DLSST[3]) / (2 * DLSST[2]))
        Object.TransverseDiffSST = DRSST[2]
        Object.TransverseDiffSSTErr = 100.0 * abs((DRSST[2] - DRSST[3]) / (2 * DRSST[2]))
        if Object.AttachmentOverIonisation==-1:
            # No Ionisation
            Object.AlphaSST = 0.0
            Object.AlphaSSTErr = 0.0
            ANST[2] = Object.NumberOfElectronSST[2]
            ANST[3] = Object.NumberOfElectronSST[3]
            ANST[4] = ANST[3] - sqrt(ANST[3])
            ANST[5] = log(ANST[2]/ANST[3])
            ANST[6] =  log(ANST[2]/ANST[4])
            ANST[7] = ANST[6]/ANST[5]
            ANST[8] = ANST[7]-1.0
            Object.AttachmentSST = -1 * (Object.ALFN[2] + Object.ALFNJ[2] + Object.ALFNE[2]) / 3.0
            Object.AttachmentSSTErr = 100.0 * sqrt(ANST[8] ** 2 + Object.AttachmentErr ** 2)
        else:
            ANST[2] = Object.NumberOfElectronSST[2]
            ANST[3] = Object.NumberOfElectronSST[3]
            ANST[4] = ANST[3] - sqrt(ANST[3])
            ANST[5] = log(ANST[2]/ANST[3])
            ANST[6] =  log(ANST[2]/ANST[4])
            ANST[7] = ANST[6]/ANST[5]
            ANST[8] = ANST[7]-1.0
            ATMP = (ALFN[2]+ALFNJ[2]+ALFNE[2])/3.0
            Object.AlphaSST = ATMP / (1 - Object.AttachmentOverIonisation)
            Object.AlphaSSTErr = 100 * sqrt(ANST[8] ** 2 + Object.AttachmentOverIonisationErr ** 2)
            Object.AttachmentSST = Object.AttachmentOverIonisation * ATMP / (1 - Object.AttachmentOverIonisation)
            Object.AttachmentSSTErr = 100 * sqrt(ANST[8] ** 2 + Object.AttachmentErr ** 2)
    # Net Ionisation therefore take results from plane 8
    Object.VelocitySvzSST = VDSST[8]
    Object.VelocitySvzSSTErr = 100 * abs((VDSST[8] - VDSST[7]) / VDSST[8])
    Object.WSOUT= WSSST[8]
    Object.WSERR = 100*abs((WSSST[8]-WSSST[7])/WSSST[8])
    Object.LongitudinalDiffSST = DLFIN
    Object.LongitudinalDiffSSTErr = 100 * abs((Object.LongitudinalDiffSST - DLSST[8]) / Object.LongitudinalDiffSST)
    Object.TransverseDiffSST = (DXFIN + DYFIN) / 2
    Object.TransverseDiffSSTErr = 100 * abs((Object.TransverseDiffSST - DRSST[8]) / Object.TransverseDiffSST)
    ATMP = (ALFN[8]+ALFNJ[8]+ALFNE[8])/3
    ATMP2 = (ALFN[7]+ALFNJ[7]+ALFNE[7])/3.0
    ATER = abs((ATMP-ATMP2)/ATMP)
    Object.AlphaSST = ATMP / (1 - Object.AttachmentOverIonisation)
    Object.AlphaSSTErr= 100 * sqrt(ATER ** 2 + Object.AttachmentOverIonisationErr ** 2)
    Object.AttachmentSST = Object.AttachmentOverIonisation * ATMP / (1 - Object.AttachmentOverIonisation)
    if Object.AttachmentOverIonisation != 0.0:
        Object.AttachmentSSTErr = 100 * sqrt(ATER ** 2 + Object.AttachmentErr ** 2)
    else:
        Object.AttachmentSSTErr = 0.0
