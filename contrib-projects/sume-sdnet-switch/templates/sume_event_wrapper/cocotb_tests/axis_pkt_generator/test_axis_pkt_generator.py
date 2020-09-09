
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

INGRESS_LINK_RATE = 40 # Gbps

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
    dut.gen_packet <= 0
    dut._log.debug("Out of reset")

@cocotb.test()
def test_axis_pkt_generator(dut):
    """Test to make sure that axis_pkt_generator module is working properly.
    """
    # start HW sim clock
    cocotb.fork(Clock(dut.axis_aclk, PERIOD).start())

    yield reset_dut(dut)
    yield ClockCycles(dut.axis_aclk, START_DELAY)

    # Attach an AXI4StreamSlave to the output pkt interface
    pkt_slave = AXI4StreamSlave(dut, 'm_axis', dut.axis_aclk, tready_delay=BP_COUNT, idle_timeout=IDLE_TIMEOUT)

    # start reading for pkts
    pkt_slave_thread = cocotb.fork(pkt_slave.read_n_pkts(NUM_PKTS, log_raw=True))

    dut.gen_packet <= 1
    yield ClockCycles(dut.axis_aclk, NUM_PKTS)
    dut.gen_packet <= 0

    # Wait for the pkt_slave to finish (or timeout)
    yield pkt_slave_thread.join()

    pkts_out = pkt_slave.pkts
    meta_out = pkt_slave.metadata

    yield ClockCycles(dut.axis_aclk, 20)

    print 'len(pkts_out) = {}'.format(len(pkts_out))

