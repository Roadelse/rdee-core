#!/usr/bin/env python
# coding=utf-8



import argparse
import sys
import datetime



def ymd2yj(ymd: str):
    date_obj = datetime.date.fromisoformat(ymd)
    date_yj = date_obj.strftime("%Y%j")

    return date_yj

def yj2ymd(yj: str):
    date_obj = datetime.datetime.strptime(yj, "%Y%j").date()
    date_ymd = date_obj.strftime("%Y%m%d")

    return date_ymd

def all2yj(dstr: str):
    if len(dstr) == 8:
        return ymd2yj(dstr)
    if len(dstr) == 7:
        return dstr

def all2ymd(dstr: str):
    if len(dstr) == 8:
        return dstr
    if len(dstr) == 7:
        return yj2ymd(dstr)

def _get_date_obj(dstr: str):
    if len(dstr) == 8:
        date_obj = datetime.date.fromisoformat(ymd)
    if len(dstr) == 7:
        date_obj = datetime.datetime.strptime(dstr, "%Y%j").date()
    return date_obj


def nextD(dstr: str):
    today_obj = _get_date_obj(dstr)
    nextday_obj = today_obj + datetime.timedelta(days=1)
    return nextday_obj.strftime("%Y%m%d")

def prevD(dstr: str):
    today_obj = _get_date_obj(dstr)
    nextday_obj = today_obj - datetime.timedelta(days=1)
    return nextday_obj.strftime("%Y%m%d")


def nextJ(dstr: str):
    today_obj = _get_date_obj(dstr)
    nextday_obj = today_obj + datetime.timedelta(days=1)
    return nextday_obj.strftime("%Y%j")

def prevJ(dstr: str):
    today_obj = _get_date_obj(dstr)
    nextday_obj = today_obj - datetime.timedelta(days=1)
    return nextday_obj.strftime("%Y%j")

if __name__ == "__main__":
    a1 = sys.argv[1].lower()
    if a1 in ('d2j', "ymd2yj"):
        print(ymd2yj(sys.argv[2]))
    elif a1 in ("j2d", "yj2ymd"):
        print(yj2ymd(sys.argv[2]))
    elif a1 in ("2d",):
        print(all2ymd(sys.argv[2]))
    elif a1 in ("2j",):
        print(all2yj(sys.argv[2]))
    elif a1 in ("nextd",):
        print(nextD(sys.argv[2]))
    elif a1 in ("nextj",):
        print(nextJ(sys.argv[2]))
    elif a1 in ("prevd","lastd"):
        print(prevD(sys.argv[2]))
    elif a1 in ("prevj","lastj"):
        print(prevJ(sys.argv[2]))
    else:
        raise NotImplementedError(f"Unknown action: {sys.argv[2]}")

