module ViconUDP

using Rotations
using Sockets
using Dates
using Statistics

export ViconSystem, set_world!, read_vicon, close_vicon, transform_to_world, measure_input_frequenzy, start_async_read

"""
    ItemStruct

Struct for the Vicon UDP data
"""
struct ItemStruct
    #ItemID::UInt8
    #ItemDataSize::UInt16
    FrameNumber::UInt32
    Timestamp::Int64
    ItemName::String
    #TransX::Float64
    #TransY::Float64
    #TransZ::Float64
    x_m::Vector{Float64}
    #RotX::Float64
    #RotY::Float64
    #RotZ::Float64
    R::Matrix{Float64}
end


"""
    ViconSystem

Struct for the Vicon System. 
Opens the UDP socket and binds it to the given ip and port.
"""
mutable struct ViconSystem
    socket::UDPSocket

    R_Vicon2World::Matrix{Float64}
    x_Vicon2World_m::Vector{Float64}


    function ViconSystem(;ip=IPv4(0,0,0,0), port=51001)
        socket = Sockets.UDPSocket();
        Sockets.bind(socket,ip,port);

        R_Vicon2World = [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0];
        x_Vicon2World_m = [0.0; 0.0; 0.0];

        new(socket, R_Vicon2World, x_Vicon2World_m)
    end
end



"""
    reinterpret_Vicon(byte_string::Vector{UInt8})

takes the byte_string from the Vicon UDP socket and returns a Vector of raw ItemStructs
"""
function reinterpret_Vicon(byte_string::Vector{UInt8}, timestamp::Int64)
    Frame_Number = reinterpret(UInt32, byte_string[1:4])[1] # Frame number of the UDP packet
    ItemsInBlock = byte_string[5] # Number of items in the UDP packet

    Items = []
    for i in 0:(ItemsInBlock - 1)
        start = 6+i*75

        x_Vicon_mm = [  reinterpret(Float64, byte_string[(start+27):(start+34)])[1]; # Pos X
                        reinterpret(Float64, byte_string[(start+35):(start+42)])[1]; # Pos Y
                        reinterpret(Float64, byte_string[(start+43):(start+50)])[1]] # Pos Z
        x_Vicon_m = x_Vicon_mm / 1000.0 # in meter


        R_Vicon = Matrix(Rotations.RotXYZ(  reinterpret(Float64, byte_string[(start+51):(start+58)])[1], # Rot X
                                            reinterpret(Float64, byte_string[(start+59):(start+66)])[1], # Rot Y
                                            reinterpret(Float64, byte_string[(start+67):(start+74)])[1])) # Rot Z

        # TODO: remove ending spaces
        ItemName = String(byte_string[(start+3):(start+26)])

        new_item = ItemStruct(  Frame_Number,
                                timestamp,
                                ItemName,
                                x_Vicon_m,
                                R_Vicon
                                ) 
       push!(Items, new_item)
    end

    return Items
end



"""
    close_vicon(vicon::ViconSystem)

takes the byte_string from the Vicon UDP socket and returns a Vector of ItemStructs
"""
function close_vicon(vicon::ViconSystem)
    #TODO: Threads.atomic_xchg!(atom_running, false) # stop async read
    close(vicon.socket)
end


"""
    read_vicon(vicon::ViconSystem)

reads a UDP package and returns a vector of items.
"""    
function read_vicon(vicon::ViconSystem)
    raw_recived = Sockets.recv(vicon.socket)
    timestamp = Dates.value.(now());
    Items = reinterpret_Vicon(raw_recived, timestamp)
    return Items
end


"""
    read_vicon(vicon::ViconSystem)

reads a UDP package and returns the selected item.
"""    
function read_vicon(vicon::ViconSystem, ItemName::String)
    Items = read_vicon(vicon)
    for i in Items
        if startswith(i.ItemName, ItemName)
            return i
        end
    end
    println("No ItemName (", ItemName, ") found!")
    return nothing
end


"""
    set_world!(vicon::ViconSystem, x_Vicon2World_m::Vector, R_Vicon2World::Matrix)

Set manual transformation from Vicon System to World.
"""    
function set_world!(vicon::ViconSystem, x_Vicon2World_m::Vector, R_Vicon2World::Matrix)
    vicon.x_Vicon2World_m = x_Vicon2World_m
    vicon.R_Vicon2World = R_Vicon2World
    return nothing
end


"""
    set_world!(vicon::ViconSystem, ItemName::String)

Set transformation from Vicon System to World based on a given item.
"""    
function set_world!(vicon::ViconSystem, ItemName::String)
    item_Vicon = read_vicon(vicon, ItemName)

    if item_Vicon === nothing
        println("No item (", ItemName, ") found!")
        return nothing
    else
        vicon.x_Vicon2World_m = item_Vicon.x_m
        vicon.R_Vicon2World = item_Vicon.R
        return vicon.x_Vicon2World_m, vicon.R_Vicon2World
    end
end


"""
    transform_to_world(vicon::ViconSystem, Item::ItemStruct)

Set transformation from Vicon System to World based on a given item.
"""   
function transform_to_world(vicon::ViconSystem, Item_Vicon::ItemStruct)

    x_W_m = transpose(vicon.R_Vicon2World) * (Item_Vicon.x_m .- vicon.x_Vicon2World_m)
    R_W = transpose(vicon.R_Vicon2World) * Item_Vicon.R

    Item_W = ItemStruct(    Item_Vicon.FrameNumber,
                            Item_Vicon.Timestamp,
                            Item_Vicon.ItemName,
                            x_W_m,
                            R_W)

    return Item_W
end



"""
    clear_UDP_buffer(vicon::ViconSystem)

Helper function that clears the UDP buffer.
The timestamp is set as soon as the packet is read. No timestamp is transmitted via the UDP interface.
The UDP buffer must therefore be cleard before reading starts.

TODO: Is there a better variant via the Julia socket?
"""
function clear_UDP_buffer(vicon::ViconSystem)

    items = read_vicon(vicon)
    last_timestamp = items[1].Timestamp
    current_timestamp = last_timestamp

    while (current_timestamp - last_timestamp) < 2
        last_timestamp = current_timestamp
        items = read_vicon(vicon)
        current_timestamp = items[1].Timestamp
    end
end




"""
    measure_input_frequenzy(byte_string::Vector{UInt8})

takes the byte_string from the Vicon UDP socket and returns a Vector of ItemStructs
"""
function measure_input_frequenzy(vicon::ViconSystem)
    clear_UDP_buffer(vicon)

    numer_of_samples = 101
    timestamps = []
    for i in 1:numer_of_samples
        items = read_vicon(vicon)
        push!(timestamps, items[1].Timestamp)
    end

    diff_ms = timestamps[2:end] .- timestamps[1:(end-1)]
    diff_ms_mean = mean(diff_ms)
    frequenzy = 1000/diff_ms_mean
    println("Mean time between UDP packages: ", diff_ms_mean, " ms. (", frequenzy, " Hz)")
    println("Recived ", numer_of_samples - 1, " packages in ", (timestamps[end] - timestamps[1]), "ms.")
    return frequenzy
end




"""
    start_async_read(vicon::ViconSystem, ItemName::String, buffer_size = 10)  

Starts a asyncron read from Vicon System. Returns a function that returns the latest item.
buffer_size is the size of the Channel sending data from the async task.
"""
function start_async_read(vicon::ViconSystem, ItemName::String; buffer_size = 10)

    # channel for async read
    item_channel = Channel{ItemStruct}(buffer_size);

    latest_item = ItemStruct(0, 0, "", [0.0; 0.0; 0.0], [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])

    function read_vicon_async(item_channel::Channel, vicon::ViconSystem, ItemName::String)
        while true # TODO: add stop condition
            item_Vicon = read_vicon(vicon, ItemName)
            # If the buffer is full, take one item out.
            if Base.n_avail(item_channel) >= (buffer_size-1)
                take!(item_channel)
            end
            try
                if item_Vicon !== nothing
                    put!(item_channel, item_Vicon)
                end
            catch y
                # If the put fails the channel is closed.
                # ... variant to finish the task.
                break
            end
        end
    end;


    function get_latest_item()
        # read all items from the Buffer. The last one is the newest one
        while isready(item_channel)
            latest_item = take!(item_channel)
        end
        return latest_item
    end

    function stop_read_vicon_async()
        close(item_channel)
        sleep(1)
        if istaskdone(task)
            println("async vicon read is stopped.")
            return true
        else
            println("async vicon read is still running.")
            return false
        end
    end

    task = Threads.@spawn read_vicon_async(item_channel, vicon, ItemName);
    return get_latest_item, stop_read_vicon_async
end;
         



end # module