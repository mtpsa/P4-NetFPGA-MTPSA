
import logging
import cocotb
import random

from cocotb.clock import Clock
from cocotb.triggers import Timer, ReadOnly, RisingEdge, ClockCycles, FallingEdge
from cocotb.binary import BinaryValue
from cocotb.axi4stream import AXI4StreamMaster, AXI4StreamSlave, AXI4StreamStats, CycleCounter
from cocotb.result import TestFailure

from metadata import Metadata
from scapy.all import Ether, IP, TCP, hexdump, rdpcap

# Add include directory for python sims
import sys, os

NUM_PKTS = 2
PKT_LEN = 200 # bytes

INGRESS_LINK_RATE = 5 # Gbps

START_DELAY = 100
PERIOD = 5000
IDLE_TIMEOUT = PERIOD*1000

BP_COUNT = 1

@cocotb.coroutine
def reset_dut(dut):
    # Reset the DUT
    dut._log.debug("Resetting DUT")
    dut.axis_resetn <= 0
    yield ClockCycles(dut.axis_aclk, 10)
    dut.axis_resetn <= 1
    dut.m_axis_tready <= 0
    dut._log.debug("Out of reset")

def make_meta(pkts_in, src_port):
    meta_in = []
    for p in pkts_in:
        meta = Metadata(pkt_len=len(p), src_port=src_port)
        tuser = BinaryValue(bits=len(meta)*8, bigEndian=False)
        tuser.set_buff(str(meta))
        meta_in.append(tuser)   
    return meta_in

def make_pkts_meta_in(src_port):
    pkts_in = []
    for i in range(NUM_PKTS):
        pkt = Ether() / ('\x00'*(PKT_LEN-14))
        pkts_in.append(pkt)

    meta_in = make_meta(pkts_in, src_port)

    print 'len(pkts_in) = {}'.format(len(pkts_in))
    return pkts_in, meta_in

@cocotb.test()
def test_input_arbiter(dut):
    """Test to make sure that input_arbiter module is working properly.
    """
    # start HW sim clock
    cocotb.fork(Clock(dut.axis_aclk, PERIOD).start())

    yield reset_dut(dut)
    yield ClockCycles(dut.axis_aclk, START_DELAY)

    # create the pkts and metadata
    pkts_in_0, meta_in_0 = make_pkts_meta_in(0)
    pkts_in_1, meta_in_1 = make_pkts_meta_in(1)
    pkts_in_2, meta_in_2 = make_pkts_meta_in(2)

    # Attach an AXI4Stream Master to the input pkt interface
    pkt_master_0 = AXI4StreamMaster(dut, 's_axis_0', dut.axis_aclk)
    pkt_master_1 = AXI4StreamMaster(dut, 's_axis_1', dut.axis_aclk)
    pkt_master_2 = AXI4StreamMaster(dut, 's_axis_2', dut.axis_aclk)

    # Attach an AXI4StreamSlave to the output pkt interface
    pkt_slave = AXI4StreamSlave(dut, 'm_axis', dut.axis_aclk, tready_delay=BP_COUNT, idle_timeout=IDLE_TIMEOUT)

    # start reading for pkts
    pkt_slave_thread = cocotb.fork(pkt_slave.read_n_pkts(3*len(pkts_in_0), log_raw=True))

    # Send pkts and metadata in the HW sim
    rate = 1.0*INGRESS_LINK_RATE*5/8.0 # bytes/cycle
    pkt_master_thread_0 = cocotb.fork(pkt_master_0.write_pkts(pkts_in_0, meta_in_0, rate=rate))
    pkt_master_thread_1 = cocotb.fork(pkt_master_1.write_pkts(pkts_in_1, meta_in_1, rate=rate))
    pkt_master_thread_2 = cocotb.fork(pkt_master_2.write_pkts(pkts_in_2, meta_in_2, rate=rate))

    yield pkt_master_thread_0.join()
    yield pkt_master_thread_1.join()
    yield pkt_master_thread_2.join()

    # Wait for the pkt_slave to finish (or timeout)
    yield pkt_slave_thread.join()

    pkts_out = pkt_slave.pkts
    meta_out = pkt_slave.metadata

    yield ClockCycles(dut.axis_aclk, 20)

    print 'len(pkts_out) = {}'.format(len(pkts_out))

