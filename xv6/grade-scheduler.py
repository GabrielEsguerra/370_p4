import re
import subprocess
from gradelib import *


r = Runner(save("xv6.out"))


@test(50, "ps")
def test_ps():
    r.run_qemu(shell_script(["ps"]))
    r.match("^ps test: OK", no=[".* FAIL .*"])


@test(50, "fork2test")
def test_fork2test():
    r.run_qemu(shell_script(["fork2test"]))
    r.match("^fork2test: OK", no=[".* FAIL .*"])


@test(100, "uscheduler")
def test_uscheduler():
    r.run_qemu(shell_script(["uscheduler"]))
    expected = ["process_a started", "process_b started", "process_c started"]
    expected.extend(
        ["process_%s %d" % (pid, n) for n in range(100) for pid in ("c", "a", "b")]
    )
    expected.extend(
        [
            "process_c: exit after 100",
            "process_a: exit after 100",
            "process_b: exit after 100",
        ]
    )
    expected.append("scheduler: no runnable processes")
    if not re.findall("\n".join(expected), r.qemu.output, re.M):
        raise AssertionError("Output does not match expected output")


# ONLY FOR PART A AND PART C OF PROJECT 4
@test(100, "usertests")
def test_usertests():
    r.run_qemu(shell_script(["usertests"]), timeout=300)
    r.match("^ALL TESTS PASSED$")


run_tests()