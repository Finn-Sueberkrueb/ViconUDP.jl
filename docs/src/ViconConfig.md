# Vicon Tracker configuration

On the System tab, when you click on the Local Vicon System node, the following settings are available in the UDP Object Stream section of the Properties pane.
![UDP_window](./assets/UDP_window.png)


# UDP stream
    

!!! info "Vicon DataStream SDK"
    The UDP stream (used here) contains only a small subset of the data that is available via the Vicon DataStream SDK.


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





