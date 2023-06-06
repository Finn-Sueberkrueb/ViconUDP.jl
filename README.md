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
```julia
using Vicon

# initialize Vicon
vicon = ViconSystem(;port=51001);

# Set World origin
set_world!(vicon, [0; 0; 0], [1 0 0; 0 1 0; 0 0 1]);
set_world!(vicon, "Origin_Object") # Set World origin based on a given item

# read from Vicon System
itemVector = read_vicon(vicon); # read items from Vicon System
println("Found ", length(itemVector), " items.");

ItemName = "Object1";
item1 = read_vicon(vicon, ItemName); # read "Object1" from Vicon System
println("Position of ", ItemName, ": ", item1.x_m , ", in Vicon frame.")

# transform to World
item1_W = transform_to_world(vicon, item1);
println("Position of ", ItemName, ": ", item1_W.x_m , ", in World frame.")

# measure input frequenzy
measure_input_frequenzy(vicon);


# start asyncron read from Vicon System
get_latest_item, stop_read_vicon_async = start_async_read(vicon, ItemName);

for i in 1:100
    item1 = get_latest_item() # get latest item from asyncron read
    item1_W = transform_to_world(vicon, item1)
    println("Position of ", ItemName, ": ", item1_W.x_m , ", in World frame.")
    sleep(0.012)
end

stop_read_vicon_async();

# close UDP socket
close_vicon(vicon)
```