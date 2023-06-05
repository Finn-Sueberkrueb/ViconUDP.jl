# Vicon

[![Build Status](https://github.com/Finn-Sueberkrueb/Vicon.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Finn-Sueberkrueb/Vicon.jl/actions/workflows/CI.yml?query=branch%3Amain)


## Vicon Tracker configuration
The UDP stream (used here) contains only a small subset of the data that is available via the Vicon DataStream SDK. The UDP stream ounly contains:

| Content         | Byte | Type | comment|
|--------------|------------|----|----|
| ItemID | 1 | UInt8| |
| ItemDataSize | 2 | UInt16 | 72 |
| ItemName | 24 | Char[] | zero padding |
| TransX | 8 | Float64 | in mm |
| TransY | 8 | Float64 | in mm |
| TransZ | 8 | Float64 | in mm |
| RotX | 8 | Float64 | |
| RotY | 8 | Float64 | |
| RotZ | 8 | Float64 | |





On the System tab, when you click on the Local Vicon System node, the following settings are available in the UDP Object Stream section of the Properties pane.
![UDP_window](docs/src/assets/UDP_window.png "UDP_window")


## Example
