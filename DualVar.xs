/* Copyright (c) 1997-1999 Graham Barr <gbarr@pobox.com>. All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <patchlevel.h>

#if PATCHLEVEL < 5
#  define PL_op op
#  define PL_curpad curpad
#  define CALLRUNOPS runops
#endif
#if (PATCHLEVEL < 5) || (PATCHLEVEL == 5 && SUBVERSION <50)
#  define PL_tainting tainting
#  define PL_stack_base stack_base
#  define PL_stack_sp stack_sp
#  define PL_ppaddr ppaddr 
#endif


MODULE=Scalar::DualVar	PACKAGE=List::Util

void
min(...)
PROTOTYPE: @
ALIAS:
    min = 0
    max = 1
CODE:
{
    int index;
    double retval;
    SV *retsv;
    if(!items) {
	XSRETURN_UNDEF;
    }
    retsv = ST(0);
    retval = SvNV(retsv);
    for(index = 1 ; index < items ; index++) {
	SV *stacksv = ST(index);
	double val = SvNV(stacksv);
	if(val < retval ? !ix : ix) {
	    retsv = stacksv;
	    retval = val;
	}
    }
    ST(0) = retsv;
    XSRETURN(1);
}



double
sum(...)
PROTOTYPE: @
CODE:
{
    int index;
    double ret;
    if(!items) {
	XSRETURN_UNDEF;
    }
    RETVAL = SvNV(ST(0));
    for(index = 1 ; index < items ; index++) {
	RETVAL += SvNV(ST(index));
    }
}
OUTPUT:
    RETVAL


void
minstr(...)
PROTOTYPE: @
ALIAS:
    minstr = 2
    maxstr = 0
CODE:
{
    SV *left;
    int index;
    if(!items) {
	XSRETURN_UNDEF;
    }
    /*
      sv_cmp & sv_cmp_locale return 1,0,-1 for gt,eq,lt
      so we set ix to the value we are looking for
      xsubpp does not allow -ve values, so we start with 0,2 and subtract 1
    */
    ix -= 1;
    left = ST(0);
    if(MAXARG & OPpLOCALE) {
	for(index = 1 ; index < items ; index++) {
	    SV *right = ST(index);
	    if(sv_cmp_locale(left, right) == ix)
		left = right;
	}
    }
    else {
	for(index = 1 ; index < items ; index++) {
	    SV *right = ST(index);
	    if(sv_cmp(left, right) == ix)
		left = right;
	}
    }
    ST(0) = left;
    XSRETURN(1);
}



void
reduce(block,...)
    SV * block
PROTOTYPE: &@
CODE:
{
    SV *ret;
    int index;
    I32 markix;
    GV *agv,*bgv,*gv;
    HV *stash;
    CV *cv;
    OP *reducecop;
    if(items <= 1) {
	XSRETURN_UNDEF;
    }
    agv = gv_fetchpv("a", TRUE, SVt_PV);
    bgv = gv_fetchpv("b", TRUE, SVt_PV);
    SAVESPTR(GvSV(agv));
    SAVESPTR(GvSV(bgv));
    cv = sv_2cv(block, &stash, &gv, 0);
    reducecop = CvSTART(cv);
    SAVESPTR(CvROOT(cv)->op_ppaddr);
    CvROOT(cv)->op_ppaddr = PL_ppaddr[OP_NULL];
    SAVESPTR(PL_curpad);
    PL_curpad = AvARRAY((AV*)AvARRAY(CvPADLIST(cv))[1]);
    SAVETMPS;
    SAVESPTR(PL_op);
    ret = ST(1);
    markix = sp - PL_stack_base;
    for(index = 2 ; index < items ; index++) {
	GvSV(agv) = ret;
	GvSV(bgv) = ST(index);
	PL_op = reducecop;
	CALLRUNOPS();
	ret = *PL_stack_sp;
    }
    ST(0) = ret;
    XSRETURN(1);
}

MODULE=Scalar::DualVar	PACKAGE=Scalar::DualVar

void
dualvar(num,str)
    SV *	num
    SV *	str
PROTOTYPE: $$
CODE:
{
    STRLEN len;
    char *ptr = SvPV(str,len);
    ST(0) = sv_newmortal();
    SvUPGRADE(ST(0),SVt_PVNV);
    sv_setpvn(ST(0),ptr,len);
    if(SvNOKp(num) || !SvIOKp(num)) {
	SvNVX(ST(0)) = SvNV(num);
	SvNOK_on(ST(0));
    }
    else {
	SvIVX(ST(0)) = SvIV(num);
	SvIOK_on(ST(0));
    }
    if(PL_tainting && (SvTAINTED(num) || SvTAINTED(str)))
	SvTAINTED_on(ST(0));
    XSRETURN(1);
}

MODULE=Scalar::DualVar	PACKAGE=Ref::Util

char *
blessed(sv)
    SV * sv
PROTOTYPE: $
CODE:
{
    if(!sv_isobject(sv)) {
	XSRETURN_UNDEF;
    }
    RETVAL = sv_reftype(SvRV(sv),TRUE);
}
OUTPUT:
    RETVAL

char *
reftype(sv)
    SV * sv
PROTOTYPE: $
CODE:
{
    if(!SvROK(sv)) {
	XSRETURN_UNDEF;
    }
    RETVAL = sv_reftype(SvRV(sv),FALSE);
}
OUTPUT:
    RETVAL
