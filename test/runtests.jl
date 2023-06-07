using ViconUDP
using Test

@testset "ViconUDP.jl" begin
    
    # transformation test
    vicon_sys = ViconSystem(;port=51001);

    set_world!(vicon_sys, [0; 0; 0], [0 1 0; 1 0 0; 0 0 1]);
    R_Vicon = [1 0 0; 0 1 0; 0 0 1]

    # Z axis should not rotate
    x_Vicon = [0; 0; 1]
    test_item_Vicon = ViconUDP.ItemStruct(0, 0, "", x_Vicon, R_Vicon)
    test_item_W = transform_to_world(vicon_sys, test_item_Vicon);
    @test test_item_W.x_m == x_Vicon

    # X axis should rotate to Y axis
    x_Vicon = [1; 0; 0]
    test_item_Vicon = ViconUDP.ItemStruct(0, 0, "", x_Vicon, R_Vicon)
    test_item_W = transform_to_world(vicon_sys, test_item_Vicon);
    @test test_item_W.x_m == [0; 1; 0]
end
