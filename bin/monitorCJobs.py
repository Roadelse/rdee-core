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

def monitor_slurm(configdict, sendto):
    jobids = osrun("squeue | grep -Po '^\s+\d+' | grep -Po '\d+'").splitlines()
    while jobids:
        time.sleep(60)
        jobids_now = osrun("squeue | grep -Po '^\s+\d+' | grep -Po '\d+'").splitlines()
        for jid in jobids:
            if jid not in jobids_now:
                jstate = osrun(f"sacct -j {jid}  --noheader -b | head -n 1 | grep COMPLETED")
                if jstate:
                    sendmail.send_mail(sendto, f"{jid} 任务失败", "", configDict=configDict)
                else:
                    sendmail.send_mail()        

def osrun(cmd: str, logfile = ""):
    if logfile:
        robj = subprocess.run(f"{cmd} >& {logfile}", shell=True, executable="/bin/bash", text=True)
    else:
        robj = subprocess.run(cmd, shell=True, executable="/bin/bash", text=True, stdout=subprocess.PIPE)
    if robj.returncode != 0:
        raise RuntimeError(f"Error in {cmd=}, returncode={robj.returncode}")

    if not logfile:
        return robj.stdout.strip()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""send e-mail via python built-in smtp""")
    parser.add_argument("--configfile", required=True, help="use a config file rather than setting each item via command argument")
    parser.add_argument("--sendto", required=True, help="email destination")
    parser.add_argument("--system", required=True, help="pbs or slurm")

    args = parser.parse_args()
    
    if not os.path.exists(args.configfile):
        raise RuntimeError(f"configfile={args.configfile} doesn't exist!")
    try:
        with open(args.configfile, "r") as f:
            configdict = json.load(f)
            if "host" not in configdict or "user" not in configdict or "authcode" not in configdict:
                raise RuntimeError("Missing required key: user/host/authcode")
        args.__dict__.update(configdict)
    except:
        raise RuntimeError(f"Failed to load json configfile={args.configfile}")

    if args.system.lower() == "pbs":
        monitor_slurm(configdict, sendto=args.sendto)
    else:
        raise NotImplementedError()