// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  schedNewEvent (struct dummyq_struct * I1480, EBLK  * I1475, U  I619);
void  schedNewEvent (struct dummyq_struct * I1480, EBLK  * I1475, U  I619)
{
    U  I1770;
    U  I1771;
    U  I1772;
    struct futq * I1773;
    struct dummyq_struct * pQ = I1480;
    I1770 = ((U )vcs_clocks) + I619;
    I1772 = I1770 & ((1 << fHashTableSize) - 1);
    I1475->I665 = (EBLK  *)(-1);
    I1475->I666 = I1770;
    if (0 && rmaProfEvtProp) {
        vcs_simpSetEBlkEvtID(I1475);
    }
    if (I1770 < (U )vcs_clocks) {
        I1771 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1475, I1771 + 1, I1770);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I619 == 1)) {
        I1475->I668 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I665 = I1475;
        peblkFutQ1Tail = I1475;
    }
    else if ((I1773 = pQ->I1377[I1772].I688)) {
        I1475->I668 = (struct eblk *)I1773->I686;
        I1773->I686->I665 = (RP )I1475;
        I1773->I686 = (RmaEblk  *)I1475;
    }
    else {
        sched_hsopt(pQ, I1475, I1770);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
