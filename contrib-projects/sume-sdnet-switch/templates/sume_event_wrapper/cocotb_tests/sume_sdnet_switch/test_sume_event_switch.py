
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

NUM_PKTS = 5
PKT_LEN = 200 # bytes

INGRESS_LINK_RATE = 10 # Gbps

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
    dut.m_axis_0_tready <= 0
    dut.m_axis_1_tready <= 0
    dut.m_axis_2_tready <= 0
    dut.m_axis_3_tready <= 0
    dut.m_axis_4_tready <= 0
    dut.link_status <= 0b1111
    dut._log.debug("Out of reset")

def make_meta(pkts_in, dst_port):
    meta_in = []
    for p in pkts_in:
        meta = Metadata(pkt_len=len(p), dst_port=dst_port)
        tuser = BinaryValue(bits=len(meta)*8, bigEndian=False)
        tuser.set_buff(str(meta))
        meta_in.append(tuser)   
    return meta_in

def make_pkts_meta_in(dst_port):
    pkts_in = []
    for i in range(NUM_PKTS):
        pkt = Ether() / ('\x00'*(PKT_LEN-14))
        pkts_in.append(pkt)

    meta_in = make_meta(pkts_in, dst_port)

    print 'len(pkts_in) = {}'.format(len(pkts_in))
    return pkts_in, meta_in

def check_pkts(pkts_in, pkts_out):
    max_len = max([len(p) for p in pkts_in])

    max_plen = 0
    for p in pkts_out:
        if len(p) < 64:
            print "ERROR: received pkt that is too small"
        elif len(p) > max_len:
            print "ERROR: received pkt that is too large"
        max_plen = len(p) if len(p) > max_plen else max_plen
    print 'INFO: max packet length = {}'.format(max_plen)

@cocotb.test()
def test_sume_event_switch(dut):
    """Test to make sure that event_output_queues module is working properly.
    """
    # start HW sim clock
    cocotb.fork(Clock(dut.axis_aclk, PERIOD).start())

    yield reset_dut(dut)
    yield ClockCycles(dut.axis_aclk, START_DELAY)

    # read the pkts and rank values
    pkts_in_0, meta_in_0 = make_pkts_meta_in(0b00000001)
    pkts_in_1, meta_in_1 = make_pkts_meta_in(0b00000100)
    pkts_in_2, meta_in_2 = make_pkts_meta_in(0b00010000)
    pkts_in_3, meta_in_3 = make_pkts_meta_in(0b01000000)

    # Attach an AXI4Stream Master to the input pkt interface
    pkt_master_0 = AXI4StreamMaster(dut, 's_axis_0', dut.axis_aclk)
    pkt_master_1 = AXI4StreamMaster(dut, 's_axis_1', dut.axis_aclk)
    pkt_master_2 = AXI4StreamMaster(dut, 's_axis_2', dut.axis_aclk)
    pkt_master_3 = AXI4StreamMaster(dut, 's_axis_3', dut.axis_aclk)

    # Attach an AXI4StreamSlave to the output pkt interface
    pkt_slave_0 = AXI4StreamSlave(dut, 'm_axis_0', dut.axis_aclk, tready_delay=BP_COUNT, idle_timeout=IDLE_TIMEOUT)
    pkt_slave_1 = AXI4StreamSlave(dut, 'm_axis_1', dut.axis_aclk, tready_delay=BP_COUNT, idle_timeout=IDLE_TIMEOUT)
    pkt_slave_2 = AXI4StreamSlave(dut, 'm_axis_2', dut.axis_aclk, tready_delay=BP_COUNT, idle_timeout=IDLE_TIMEOUT)
    pkt_slave_3 = AXI4StreamSlave(dut, 'm_axis_3', dut.axis_aclk, tready_delay=BP_COUNT, idle_timeout=IDLE_TIMEOUT)

    # start reading for pkts
    pkt_slave_thread_0 = cocotb.fork(pkt_slave_0.read_n_pkts(len(pkts_in_0), log_raw=True))
    pkt_slave_thread_1 = cocotb.fork(pkt_slave_1.read_n_pkts(len(pkts_in_1), log_raw=True))
    pkt_slave_thread_2 = cocotb.fork(pkt_slave_2.read_n_pkts(len(pkts_in_2), log_raw=True))
    pkt_slave_thread_3 = cocotb.fork(pkt_slave_3.read_n_pkts(len(pkts_in_3), log_raw=True))

    # Send pkts and metadata in the HW sim
    rate = 1.0*INGRESS_LINK_RATE*5/8.0 # bytes/cycle
    pkt_master_thread_0 = cocotb.fork(pkt_master_0.write_pkts(pkts_in_0, meta_in_0, rate=rate))
    pkt_master_thread_1 = cocotb.fork(pkt_master_1.write_pkts(pkts_in_1, meta_in_1, rate=rate))
    pkt_master_thread_2 = cocotb.fork(pkt_master_2.write_pkts(pkts_in_2, meta_in_2, rate=rate))
    pkt_master_thread_3 = cocotb.fork(pkt_master_3.write_pkts(pkts_in_3, meta_in_3, rate=rate))

    yield pkt_master_thread_0.join()
    yield pkt_master_thread_1.join()
    yield pkt_master_thread_2.join()
    yield pkt_master_thread_3.join()

    # Wait for the pkt_slave to finish (or timeout)
    yield pkt_slave_thread_0.join()
    yield pkt_slave_thread_1.join()
    yield pkt_slave_thread_2.join()
    yield pkt_slave_thread_3.join()

#    pkts_out = pkt_slave.pkts
#    meta_out = pkt_slave.metadata

    yield ClockCycles(dut.axis_aclk, 20)

