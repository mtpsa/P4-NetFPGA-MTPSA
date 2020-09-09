
import logging
import cocotb
import random

from cocotb.clock import Clock
from cocotb.triggers import Timer, ReadOnly, RisingEdge, ClockCycles, FallingEdge
from cocotb.binary import BinaryValue
from cocotb.result import TestFailure

# Add include directory for python sims
import sys, os

START_DELAY = 100
PERIOD = 5000

@cocotb.coroutine
def reset_dut(dut):
    # Reset the DUT
    dut._log.debug("Resetting DUT")
    dut.axis_resetn <= 0
    yield ClockCycles(dut.axis_aclk, 10)
    dut.axis_resetn <= 1
    dut.m_timer_event_rd <= 1
    dut._log.debug("Out of reset")

@cocotb.test()
def test_timer_module(dut):
    """Test to make sure that the timer_module is working properly.
    """
    # start HW sim clock
    cocotb.fork(Clock(dut.axis_aclk, PERIOD).start())

    yield reset_dut(dut)
    yield ClockCycles(dut.axis_aclk, START_DELAY)

    dut.s_timer_period_valid <= 1
    dut.s_timer_period <= 1
    yield ClockCycles(dut.axis_aclk, 1)
    dut.s_timer_period_valid <= 0
    yield ClockCycles(dut.axis_aclk, 9)

    dut.s_timer_period_valid <= 1
    dut.s_timer_period <= 2
    yield ClockCycles(dut.axis_aclk, 1)
    dut.s_timer_period_valid <= 0
    yield ClockCycles(dut.axis_aclk, 20)

