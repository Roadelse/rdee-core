#!/usr/bin/env python
# coding=utf-8

import sys
import subprocess
import os
import os.path
import json
import argparse
import time

import sendmail

def monitor_slurm(configDict):
    jobids = osrun(r"squeue | grep -Po '^\s+\d+' | grep -Po '\d+'").splitlines()
    print(f"target job ids: {jobids}")
    while jobids:
        time.sleep(60)
        print(f"check slurm jobs: {jobids} @{nowStr()}")
        jobids_now = osrun(r"squeue | grep -Po '^\s+\d+' | grep -Po '\d+'").splitlines()
        for jid in jobids:
            if jid not in jobids_now:
                jstate = osrun(f"sacct -j {jid}  --noheader -b | head -n 1 | grep COMPLETED")
                if jstate:
                    print(f"job {jid} failed")
                    sendmail.send_email(configDict["sendto"], f"{jid} 任务完成", "", configDict=configDict)
                else:
                    print(f"job {jid} completed")
                    sendmail.send_email(configDict["sendto"], f"{jid} 任务失败", "", configDict=configDict)
                jobids.remove(jid)

def osrun(cmd: str, logfile = ""):
    if logfile:
        robj = subprocess.run(f"{cmd} >& {logfile}", shell=True, executable="/bin/bash", text=True)
    else:
        robj = subprocess.run(cmd, shell=True, executable="/bin/bash", text=True, stdout=subprocess.PIPE)
    if robj.returncode != 0:
        raise RuntimeError(f"Error in {cmd=}, returncode={robj.returncode}")

    if not logfile:
        return robj.stdout.strip()

def nowStr():
    return time.strftime("%Y%m%d-%H%M%S")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""send e-mail via python built-in smtp""")
    parser.add_argument("--configfile", "-c", required=True, help="use a config file rather than setting each item via command argument")
    parser.add_argument("--system", "-s", required=True, help="pbs or slurm")

    args = parser.parse_args()
    
    if not os.path.exists(args.configfile):
        raise RuntimeError(f"configfile={args.configfile} doesn't exist!")
    try:
        with open(args.configfile, "r") as f:
            configDict = json.load(f)
    except:
        raise RuntimeError(f"Failed to load json configfile={args.configfile}")

    if args.system.lower() == "slurm":
        monitor_slurm(configDict)
    else:
        raise NotImplementedError()
