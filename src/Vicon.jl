module Vicon

using Rotations
using Sockets

export init_vicon



"""
    ItemStruct_raw

Struct for the Vicon UDP data
"""
struct ItemStruct_raw
    ItemID::UInt8
    ItemDataSize::UInt16
    ItemName::String
    TransX::Float64
    TransY::Float64
    TransZ::Float64
    RotX::Float64
    RotY::Float64
    RotZ::Float64
end



"""
    reinterpret_Vicon(byte_string::Vector{UInt8})

takes the byte_string from the Vicon UDP socket and returns a Vector of ItemStructs
"""
function reinterpret_Vicon(byte_string::Vector{UInt8})
    #println("byte_string size: ", size(byte_string))
    Frame_Number = reinterpret(UInt32, byte_string[1:4])
    #println("Frame_Number: ", (Frame_Number*1)[1])
    ItemsInBlock = byte_string[5]
    #println("ItemsInBlock: ", ItemsInBlock)

    Items = []
    for i in 0:(ItemsInBlock - 1)
        start = 6+i*75
        #=
        new_item_struct = ItemStruct_euler(   byte_string[start],
                                        reinterpret(UInt16, byte_string[(start+1):(start+2)].*1)[1],
                                        String(byte_string[(start+3):(start+26)]),
                                        reinterpret(Float64, byte_string[(start+27):(start+34)])[1],
                                        reinterpret(Float64, byte_string[(start+35):(start+42)])[1],
                                        reinterpret(Float64, byte_string[(start+43):(start+50)])[1],
                                        reinterpret(Float64, byte_string[(start+51):(start+58)])[1],
                                        reinterpret(Float64, byte_string[(start+59):(start+66)])[1],
                                        reinterpret(Float64, byte_string[(start+67):(start+74)])[1]
                                )        
        =#

        x_W = [reinterpret(Float64, byte_string[(start+27):(start+34)])[1];
               reinterpret(Float64, byte_string[(start+35):(start+42)])[1];
               reinterpret(Float64, byte_string[(start+43):(start+50)])[1]]
        
        rot = Rotations.RotXYZ( reinterpret(Float64, byte_string[(start+51):(start+58)])[1],
                                reinterpret(Float64, byte_string[(start+59):(start+66)])[1],
                                reinterpret(Float64, byte_string[(start+67):(start+74)])[1])
        R_W = Matrix(rot)

        new_item_struct = ItemStruct(   String(byte_string[(start+3):(start+26)]),
                                        x_W,
                                        R_W,
                                    )        

       push!(Items, new_item_struct)
    end

    return Items
end





# TODO: add function
"""
    measure_input_frequenzy(byte_string::Vector{UInt8})

takes the byte_string from the Vicon UDP socket and returns a Vector of ItemStructs
"""



# TODO: add visualization
"""
    measure_input_frequenzy(byte_string::Vector{UInt8})

takes the byte_string from the Vicon UDP socket and returns a Vector of ItemStructs
"""







"""
    init_vicon(;ip=IPv4(0,0,0,0), port=51001)

init_vicon opens the UDP socket and binds it to the given ip and port.
Returns functions read_vicon (blocking) and close_vicon

DLR Vicon System.
IP: 192.168.222.2
"""
function init_vicon(;ip=IPv4(0,0,0,0), port=51001)
    
    vicon_UDP_socket = UDPSocket()
    bind(vicon_UDP_socket,ip,port)

    R_Vicon2World = [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0]
    x_Vicon2World = [0.0; 0.0; 0.0]

    # atomic operators for async read
    atom_pos_x_World_Meter = Threads.Atomic{Float64}(0.0);
    atom_pos_y_World_Meter = Threads.Atomic{Float64}(0.0);
    atom_pos_z_World_Meter = Threads.Atomic{Float64}(0.0);
    atom_running = Threads.Atomic{Bool}(true);


    function close_vicon()
        Threads.atomic_xchg!(atom_running, false)
        close(vicon_UDP_socket)
    end

    # TODO: add timeout
    # TODO: set Buffersize
    function read_vicon(; ItemName = "CF_V2")
        raw_recived = Sockets.recv(vicon_UDP_socket)
        Items = reinterpret_Vicon(raw_recived)
        for i in Items
            if startswith(i.ItemName, ItemName)
                return i
            end
        end
        println("No ItemName (", ItemName, ") found!")
        return 0
    end



    # Set Zerro position and orientation from Vicon System to World
    function set_zerro(;ItemName="BiggestObject")

        raw_recived = Sockets.recv(vicon_UDP_socket)
        Items = reinterpret_Vicon(raw_recived)

        for i in Items
            println("Zerro Item = ", i.ItemName, " (found and set)")
            if startswith(i.ItemName, ItemName)
                x_Vicon2World = i.x_W
                R_Vicon2World = i.R_W
                return x_Vicon2World, R_Vicon2World
            end
        end

        println("No ItemName ", ItemName, " for zerro found!")
        return x_Vicon2World, R_Vicon2World
    end


    # Get the last position from atomic operator
    function get_last_pos()
        return [atom_pos_x_World_Meter[]; atom_pos_y_World_Meter[]; atom_pos_z_World_Meter[]]
    end


    function read_vicon_async()
        while atom_running[]
            CF_Item_Vicon = read_vicon()
            if CF_Item_Vicon != 0
                
                CF_Item_W = transform_to_world(CF_Item_Vicon)
                # takes the item of the cannel if it is not read and there is a new one
                Threads.atomic_xchg!(atom_pos_x_World_Meter, CF_Item_W.x_W[1])
                Threads.atomic_xchg!(atom_pos_y_World_Meter, CF_Item_W.x_W[2])
                Threads.atomic_xchg!(atom_pos_z_World_Meter, CF_Item_W.x_W[3])
            end
        end
        println("Stoped async vicon read ")
    end;


    function start_async_read()        
        task = @async read_vicon_async()
    end;


    function transform_to_world(CF_Item_Vicon)

        x_W = transpose(R_Vicon2World) * (CF_Item_Vicon.x_W .- x_Vicon2World) / 1000.0 # in meter
        R_W = transpose(R_Vicon2World) * CF_Item_Vicon.R_W

        CF_Item_W = ItemStruct( CF_Item_Vicon.ItemName,
                                x_W,
                                R_W)    

        return CF_Item_W
    end

    return close_vicon, set_zerro, start_async_read, get_last_pos
end





end
