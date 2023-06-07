using ViconUDP

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

