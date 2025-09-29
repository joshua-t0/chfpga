#!/usr/bin/env -S python3 -m pytest  -sv --forked

import pyxsi
import pytest


class AugmentedXSI(pyxsi.XSI):
    # VHDL uses 1fs timestep by default. This results in a 100 MHz clock.
    HALF_PERIOD = 5000000

    def tick(self, nticks=1):
        for t in range(nticks):
            self.set_port_value("aclk", "1")
            self.run(self.HALF_PERIOD)
            self.set_port_value("aclk", "0")
            self.run(self.HALF_PERIOD)

    def init(self):
        self.set_port_value("axis_bsb_cmd_tdata", f"{0:08b}")
        self.set_port_value("axis_bsb_cmd_tvalid", "0")
        self.set_port_value("axis_bsb_cmd_tlast", "0")

        self.set_port_value("axis_bsb_cmd_tready", "1")
        self.set_port_value("axis_bsb_rst", "1")
        self.set_port_value("cpu_reset", "1")

        self.tick(100)

        self.set_port_value("axis_bsb_rst", "0")
        self.set_port_value("cpu_reset", "0")
        self.tick(100)

    def txrx(self, xs: bytes) -> list[str]:
        """
        Direct interaction with AXI4-Stream control interface.

        Input is a byte string; output is a list of strings (required in case
        our outputs are X/U/H/L or some other non-binary type)
        """

        assert len(xs) == 3, "txrx() requires 3-byte commands"

        # Drive request
        for n, x in enumerate(xs):
            while self.get_port_value("axis_bsb_cmd_tready") != "1":
                self.tick()

            self.set_port_value("axis_bsb_cmd_tdata", f"{x:08b}")
            self.set_port_value("axis_bsb_cmd_tvalid", "1")
            self.set_port_value("axis_bsb_cmd_tlast", "1" if n == 2 else "0")
            self.tick()

        self.set_port_value("axis_bsb_cmd_tdata", f"{0:08b}")
        self.set_port_value("axis_bsb_cmd_tvalid", "0")
        self.set_port_value("axis_bsb_cmd_tlast", "0")

        response = []

        # Collect response
        while True:
            tlast = self.get_port_value("axis_bsb_rply_tlast")
            tvalid = self.get_port_value("axis_bsb_rply_tvalid")
            tdata = self.get_port_value("axis_bsb_rply_tdata")

            if tvalid == "1":
                response.append(tdata)

            if tvalid == "1" and tlast == "1":
                break

            self.tick()

        return response

    def read_status(self, addr):
        assert addr == addr & 0x7FF, "Address out of range!"

        dat = [0x40 | (addr >> 16), (addr >> 8 & 0xFF), addr & 0xFF]
        response = self.txrx(bytes(dat))

        # strip first byte (seems to be status?)
        assert len(response) == 2
        return response[1]


def test_control_interface_hello():
    xsi = AugmentedXSI("xsim.dir/chfpga_crssim/xsimk.so", tracefile="chfpga_crssim.wdb")

    xsi.init()
    y = xsi.read_status(0)
    assert int(y[1:], 2) == 0x42


if __name__ == "__main__":
    import pytest
    import sys

    pytest.main(sys.argv)
