@testset "Lerp tests" begin
    num = 0
    num2 = 1
    
    @testset "Lerp tests" begin
        @testset "Lerp test halfway" begin
            @test Math.Lerp(num, num2, 0.5) == 0.5
        end

        @testset "Lerp test negative" begin
            @test Math.Lerp(num, num2, -1) == 0
        end

        @testset "Lerp test over 1" begin
            @test Math.Lerp(num, num2, 2) == 1
        end

        @testset "Lerp test 0" begin 
            @test Math.Lerp(num, num2, 0) == 0
        end

        @testset "Lerp test 1" begin 
            @test Math.Lerp(num, num2, 1) == 1
        end
    end

    @testset "SmoothLerp tests" begin
        @testset "SmoothLerp test halfway" begin
            @test Math.SmoothLerp(num, num2, 0.5) == 0.49999999999999994
        end

        @testset "SmoothLerp test negative" begin
            @test Math.SmoothLerp(num, num2, -1) == 0
        end

        @testset "SmoothLerp test over 1" begin
            @test Math.SmoothLerp(num, num2, 2) == 1
        end

        @testset "SmoothLerp test 0" begin 
            @test Math.SmoothLerp(num, num2, 0) == 0
        end

        @testset "SmoothLerp test 1" begin 
            @test Math.SmoothLerp(num, num2, 1) == 1
        end
    end
   
    @testset "overflow_lerp tests" begin
        @testset "overflow_lerp test halfway" begin
            @test Math.overflow_lerp(num, num2, 0.5) == 0.5
        end

        @testset "overflow_lerp test negative" begin
            @test Math.overflow_lerp(num, num2, -1) == -1
        end

        @testset "overflow_lerp test over 1" begin
            @test Math.overflow_lerp(num, num2, 2) == 2
        end

        @testset "overflow_lerp test 0" begin 
            @test Math.overflow_lerp(num, num2, 0) == 0
        end

        @testset "overflow_lerp test 1" begin 
            @test Math.overflow_lerp(num, num2, 1) == 1
        end
    end
end