#!/usr/bin/env python
# encoding=utf-8

import sys
import os
import os.path
import glob
import time
import itertools
import traceback


import toml
try:
    from mpi4py import MPI
    with_mpi = True
except:
    with_mpi = False

if os.getenv("HTC_PSEUDORUN"):
    pseudo_run = True
else:
    pseudo_run = False



class Jobdef:
    def __init__(self, jdfile: str):
        assert os.path.exists(jdfile), "jdfile doesn't exist"
        assert jdfile.endswith(".toml"), "jdfile is not a toml file"

        self.commands = None

        self.jdfile = jdfile
        if not with_mpi or rank == 0:
            self.resolveParams()
            self.buildCommands()
        if with_mpi and size > 1:
            self.commands = comm.bcast(self.commands, root = 0)

    def logI(msg: str):
        now = time.strftime("%Y/%m/%d %H:%M:%S")
        if with_mpi:
            print(f"-- {now} ({rank=}) | {msg}")
        else:
            print(f"-- {now} | {msg}")

    def run(self):
        if with_mpi:
            comm.barrier()
            for i in range(rank, len(self.commands), size):
                self.run_cmdset(self.commands[i])
            comm.barrier()
        else:
            for cmdset in self.commands:
                self.run_cmdset(cmdset)

    def run_cmdset(self, cmdset):
        for cmd in cmdset:
            self.logI(f"run: {cmd}")

            if pseudo_run:
                continue

            rstat: int = os.system(cmd)
            if rstat != 0:
                raise RuntimeError(f"Error in os run: {cmd}")

    def resolveParams(self):

        with open(self.jdfile, 'r') as file:
            self.defdict = toml.load(file)
        assert "params" in self.defdict

        params_solid = {}
        for k, v in self.defdict["params"].items():
            if not isinstance(v, dict):
                params_solid[k] = v
        params_product = borrowed_product_withkey(self.defdict["params"]["product"]) if "product" in self.defdict["params"] else [{}]
        params_zip = borrowed_zip_withkey(self.defdict["params"]["zip"]) if "zip" in self.defdict["params"] else [{}]
        self.params = [{**a, **b, **c} for a,b,c in itertools.product([params_solid], params_product, params_zip)]

    def buildCommands(self):
        self.commands = []
        for p in self.params:
            cmds = []
            for cmd in self.defdict["commands"]:
                cmds.append(self.update_cmd(cmd, p))
            self.commands.append(cmds)
    
    def update_cmd(self, cmd: str, p: dict):
        for k,v in p.items():
            cmd = cmd.replace(f'<{k}>', f'{v}')
        return cmd

def borrowed_zip_withkey(D: dict):
    """
    zip lists with keys, borrowed from rdee-python
    --------------------------------
    @2024-05-27
    """
    length = -1
    for k, v in D.items():
        assert hasattr(v, "__len__")
        if length == -1:
            length = len(v)
        assert length == len(v), "Different length for list in zip_withkey values"

    rst = []
    keys = list(D.keys())
    for ele in  list(zip(*list(D.values()))):
        rst.append({keys[i]:ele[i] for i in range(len(keys))})
    return rst
    
def borrowed_product_withkey(D):
    """
    product lists with keys, borrowed from rdee-python
    --------------------------------
    @2024-05-27
    """
    import itertools

    rst = []
    keys = list(D.keys())
    for ele in itertools.product(*list(D.values())):
        rst.append({keys[i]:ele[i] for i in range(len(keys))})
    return rst



def main(file):
    os.environ['INPUT'] = file

    os.system("ncl -Qn /lustre/home/gaoyang/zjx/models/modularScripts/src/modules/emis/renorm.ncl")


    return


def utest():
    if not with_mpi or rank == 0:
        with open("__utest.toml", "w") as f:
            f.write("""
commands = ["echo <ct1><ct2><ct3><ct4><ct5>"]

[params]
ct1 = 1

[params.product]
ct4 = ["x"]
ct5 = ["y", "z"]

[params.zip]
ct2 = ["a", "b"]
ct3 = ["c", "d"]     
""")

    
    if with_mpi:
        comm.barrier()
        try:
            jd = Jobdef("__utest.toml")
            jd.run()
        except Exception as e:
            print("\033[32mFailure in unittest for htc.shcmd.py\033[0m")
            # print(e)
            traceback.print_exc()
            try: os.remove("__utest.toml")
            except: pass
            comm.Abort()
        if rank == 0:
            os.remove("__utest.toml")
    else:
        try:
            jd = Jobdef("__utest.toml")
            jd.run()
        except:
            raise
        finally:
            os.remove("__utest.toml")
    
if __name__ == '__main__':

    #@ Prepare

    if with_mpi:
        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        size = comm.Get_size() 

    if len(sys.argv) > 1:
        if sys.argv[1] == 'utest':
            utest()
            sys.exit()
        elif sys.argv[1] == "help":
            if not with_mpi or rank == 0:
                print("""
[Usage]
    python .../htc.shcmd.py [infile]

    where, [infile] will be jobdef.toml if omitted

[infile grammar]
    toml file, with format like:
>>>>>>>>>>
commands = ["echo <ct1><ct2><ct3><ct4><ct5>"]

[params]
ct1 = 1

[params.product]
ct4 = ["x"]
ct5 = ["y", "z"]

[params.zip]
ct2 = ["a", "b"]
ct3 = ["c", "d"]  
>>>>>>>>>>

""")
            sys.exit()

        jobDefFile = sys.argv[1]
    else:
        jobDefFile = "jobdef.toml"


    assert os.path.exists(jobDefFile), f"Cannot find jobDefFile: {jobDefFile}"


    jd = Jobdef(jobDefFile)
    jd.run()
