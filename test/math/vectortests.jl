@testset "Vector tests" begin
    @testset "Vector2 tests" begin
        # set up
        vec1 = Math.Vector2(2, 2)
        vec2 = Math.Vector2(2) # 2, 2

        @testset "Vector2 subtraction" begin
            res = vec1 - vec2
            @test res == Math.Vector2(0, 0)
        end

        @testset "Vector2 addition" begin
            res = vec1 + vec2
            @test res == Math.Vector2(4, 4)
        end

        @testset "Vector2 multiplication" begin
            res = vec1 * vec2
            @test res == Math.Vector2(4, 4)
        end

        @testset "Vector2 division" begin
            res = vec1 / vec2
            @test res == Math.Vector2(1, 1)
        end

        @testset "Vector2 constructor with Int32 and Float64 arguments" begin
            v = Math.Vector2(2, 3.7)
            @test v.x == 2
            @test v.y == 4

            v = Math.Vector2(-1, -5.9)
            @test v.x == -1
            @test v.y == -6
        end

        @testset "Vector2 constructor with Float64 and Int32 arguments" begin
            v = Math.Vector2(1.5, 4)
            @test v.x == 2
            @test v.y == 4

            v = Math.Vector2(-3.2, -7)
            @test v.x == -3
            @test v.y == -7
        end

        @testset "Vector2 multiplication with Int32" begin
            vec = Math.Vector2(2, 3)
            int::Int32 = 2
            expected = Math.Vector2(4, 6)
            @test vec * int == expected
        end
        
        @testset "Vector2 multiplication with Float64" begin
            vec = Math.Vector2(2, 3)
            float::Float64 = 1.5
            expected = Math.Vector2(3.0, 4.5)
            @test vec * float == expected
        end
        
        @testset "Float64 multiplication with Vector2" begin
            float = 1.5
            vec = Math.Vector2(2, 3)
            expected = Math.Vector2(3.0, 4.5)
            @test float * vec == expected
        end
        
        @testset "Vector2 division with Float64" begin
            vec = Math.Vector2(6, 8)
            float = 2.0
            expected = Math.Vector2(3.0, 4.0)
            @test vec / float == expected
        end
    end

    @testset "Vector2f tests" begin
        @testset "Vector2f constructors" begin
            @test Math.Vector2f().x == 0.0
            @test Math.Vector2f().y == 0.0
            
            @test Math.Vector2f(1.0, 2.0).x == 1.0
            @test Math.Vector2f(1.0, 2.0).y == 2.0
            
            @test Math.Vector2f(1, 2).x == 1.0
            @test Math.Vector2f(1, 2).y == 2.0
            
            @test Math.Vector2f(1.5, 2).x == 1.5
            @test Math.Vector2f(1.5, 2).y == 2.0
            @test Math.Vector2f(1, 2.5).x == 1.0
            @test Math.Vector2f(1, 2.5).y == 2.5
        end
        
        @testset "Vector2f addition" begin
            vec1 = Math.Vector2f(1.0, 2.0)
            vec2 = Math.Vector2f(3.0, 4.0)
            
            @test vec1 + vec2 == Math.Vector2f(4.0, 6.0)
            @test vec1 + 2 == Math.Vector2f(3.0, 4.0)
        end
        
        @testset "Vector2f subtraction" begin
            vec1 = Math.Vector2f(3.0, 4.0)
            vec2 = Math.Vector2f(1.0, 2.0)
            
            @test vec1 - vec2 == Math.Vector2f(2.0, 2.0)
            @test vec1 - 2 == Math.Vector2f(1.0, 2.0)
        end
        
        @testset "Vector2f multiplication" begin
            vec1 = Math.Vector2f(2.0, 3.0)
            vec2 = Math.Vector2f(4.0, 5.0)
            int = 2
            float = 1.5
            
            @testset "Vector2f and Vector2f multiplication" begin
                @test vec1 * vec2 == Math.Vector2f(8.0, 15.0)
            end

            @testset "Vector2f and Int32 multiplication" begin
                @test vec1 * int == Math.Vector2f(4.0, 6.0)
            end

            @testset "Vector2f and Float64 multiplication" begin
                @test vec1 * float == Math.Vector2f(3.0, 4.5)
            end

            @testset "Float64 and Vector2f multiplication" begin
                @test float * vec1 == Math.Vector2f(3.0, 4.5)
            end
        end
        
        @testset "Vector2f division" begin
            vec1 = Math.Vector2f(6.0, 8.0)
            
            @test vec1 / 2 == Math.Vector2f(3.0, 4.0)
            @test vec1 / 2.0 == Math.Vector2f(3.0, 4.0)
        end
    end

    @testset "Vector3 tests" begin
        # set up
        vec1 = Math.Vector3(2, 2, 2)
        vec2 = Math.Vector3(2) # 2, 2, 2

        @testset "Vector3 subtraction" begin
            res = vec1 - vec2
            @test res == Math.Vector3(0, 0, 0)
        end

        @testset "Vector3 addition" begin
            res = vec1 + vec2
            @test res == Math.Vector3(4, 4, 4)
        end

        @testset "Vector3 multiplication" begin
            res = vec1 * vec2
            @test res == Math.Vector3(4, 4, 4)
        end

        @testset "Vector3 division" begin
            res = vec1 / vec2
            @test res == Math.Vector3(1, 1, 1)
        end

        @testset "Vector3 constructor with Int32 and Float64 arguments" begin
            v = Math.Vector3(2, 3.7, 4)
            @test v.x == 2
            @test v.y == 4
            @test v.z == 4

            v = Math.Vector3(-1, -5.9, -2)
            @test v.x == -1
            @test v.y == -6
            @test v.z == -2
        end
    end

    @testset "Vector3f tests " begin
        @testset "Vector3f constructors" begin
            @test Math.Vector3f(1.0, 2.0, 3.0).x == 1.0
            @test Math.Vector3f(1.0, 2.0, 3.0).y == 2.0
            @test Math.Vector3f(1.0, 2.0, 3.0).z == 3.0
            
            @test Math.Vector3f(1, 2, 3).x == 1.0
            @test Math.Vector3f(1, 2, 3).y == 2.0
            @test Math.Vector3f(1, 2, 3).z == 3.0
            
            @test Math.Vector3f(1.5, 2, 3).x == 1.5
            @test Math.Vector3f(1.5, 2, 3).y == 2.0
            @test Math.Vector3f(1.5, 2, 3).z == 3.0
            @test Math.Vector3f(1, 2.5, 3).x == 1.0
            @test Math.Vector3f(1, 2.5, 3).y == 2.5
            @test Math.Vector3f(1, 2.5, 3).z == 3.0
            @test Math.Vector3f(1, 2, 3.5).x == 1.0
            @test Math.Vector3f(1, 2, 3.5).y == 2.0
            @test Math.Vector3f(1, 2, 3.5).z == 3.5
        end
        
        @testset "Vector3f addition" begin
            vec1 = Math.Vector3f(1.0, 2.0, 3.0)
            vec2 = Math.Vector3f(4.0, 5.0, 6.0) 
            @test vec1 + vec2 == Math.Vector3f(5.0, 7.0, 9.0)
            @test vec1 + 2 == Math.Vector3f(3.0, 4.0, 5.0)
            @test vec1 + 2.0 == Math.Vector3f(3.0, 4.0, 5.0)
            @test 2 + vec1 == Math.Vector3f(3.0, 4.0, 5.0)
            @test 2.0 + vec1 == Math.Vector3f(3.0, 4.0, 5.0)
        end

        @testset "Vector3f subtraction" begin
            vec1 = Math.Vector3f(3.0, 4.0, 5.0)
            vec2 = Math.Vector3f(1.0, 2.0, 3.0)
            @test vec1 - vec2 == Math.Vector3f(2.0, 2.0, 2.0)
            @test vec1 - 2 == Math.Vector3f(1.0, 2.0, 3.0)
            @test vec1 - 2.0 == Math.Vector3f(1.0, 2.0, 3.0)
            @test 2 - vec1 == Math.Vector3f(-1.0, -2.0, -3.0)
            @test 2.0 - vec1 == Math.Vector3f(-1.0, -2.0, -3.0)
        end

        @testset "Vector3f multiplication" begin
            vec1 = Math.Vector3f(2.0, 3.0, 4.0)
            vec2 = Math.Vector3f(4.0, 5.0, 6.0)
            int = 2
            float = 1.5
            
            @testset "Vector3f and Vector3f multiplication" begin
                @test vec1 * vec2 == Math.Vector3f(8.0, 15.0, 24.0)
            end

            @testset "Vector3f and Int32 multiplication" begin
                @test vec1 * int == Math.Vector3f(4.0, 6.0, 8.0)
            end

            @testset "Vector3f and Float64 multiplication" begin
                @test vec1 * float == Math.Vector3f(3.0, 4.5, 6.0)
            end

            @testset "Float64 and Vector3f multiplication" begin
                @test float * vec1 == Math.Vector3f(3.0, 4.5, 6.0)
            end
        end

        @testset "Vector3f division" begin
            vec1 = Math.Vector3f(6.0, 8.0, 10.0)
            
            @test vec1 / 2 == Math.Vector3f(3.0, 4.0, 5.0)
            @test vec1 / 2.0 == Math.Vector3f(3.0, 4.0, 5.0)
        end
    end

    @testset "Vector4 tests" begin
        # set up
        vec1 = Math.Vector4(2, 2, 2, 2)
        vec2 = Math.Vector4(2) # 2, 2, 2, 2

        @testset "Vector4 subtraction" begin
            res = vec1 - vec2
            @test res == Math.Vector4(0, 0, 0, 0)
        end

        @testset "Vector4 addition" begin
            res = vec1 + vec2
            @test res == Math.Vector4(4, 4, 4, 4)
        end

        @testset "Vector4 multiplication" begin
            res = vec1 * vec2
            @test res == Math.Vector4(4, 4, 4, 4)
        end

        @testset "Vector4 division" begin
            res = vec1 / vec2
            @test res == Math.Vector4(1, 1, 1, 1)
        end

        @testset "Vector4 constructor with Int32 and Float64 arguments" begin
            v = Math.Vector4(2, 3.7, 4, 5.9)
            @test v.x == 2
            @test v.y == 4
            @test v.z == 4
            @test v.t == 6

            v = Math.Vector4(-1, -5.9, -2, -7.9)
            @test v.x == -1
            @test v.y == -6
            @test v.z == -2
            @test v.t == -8
        end

        @testset "Vector4 constructor with Float64 and Int32 arguments" begin
            v = Math.Vector4(1.5, 4, 5.9, 6)
            @test v.x == 2
            @test v.y == 4
            @test v.z == 6
            @test v.t == 6

            v = Math.Vector4(-3.2, -7, -8.9, -9)
            @test v.x == -3
            @test v.y == -7
            @test v.z == -9
            @test v.t == -9
        end

        @testset "Vector4 multiplication with Int32" begin
            vec = Math.Vector4(2, 3, 4, 5)
            int::Int32 = 2
            expected = Math.Vector4(4, 6, 8, 10)
            @test vec * int == expected
        end

        @testset "Vector4 multiplication with Float64" begin
            vec = Math.Vector4(2, 3, 4, 5)
            float::Float64 = 1.5
            expected = Math.Vector4(3.0, 4.5, 6.0, 7.5)
            @test vec * float == expected
        end

        @testset "Float64 multiplication with Vector4" begin
            float = 1.5
            vec = Math.Vector4(2, 3, 4, 5)
            expected = Math.Vector4(3.0, 4.5, 6.0, 7.5)
            @test float * vec == expected
        end

        @testset "Vector4 division with Float64" begin
            vec = Math.Vector4(6, 8, 10, 12)
            float = 2.0
            expected = Math.Vector4(3.0, 4.0, 5.0, 6.0)
            @test vec / float == expected
        end
    end

    @testset "Vector4f tests" begin
        @testset "Vector4f constructors" begin
            @test Math.Vector4f(1.0, 2.0, 3.0, 4.0) == Math.Vector4f(1.0, 2.0, 3.0, 4.0)
            @test Math.Vector4f(1, 2, 3, 4) == Math.Vector4f(1.0, 2.0, 3.0, 4.0)
            @test Math.Vector4f(1.5, 2, 3, 4) == Math.Vector4f(1.5, 2.0, 3.0, 4.0)
            @test Math.Vector4f(1, 2.5, 3, 4) == Math.Vector4f(1.0, 2.5, 3.0, 4.0)
            @test Math.Vector4f(1, 2, 3.5, 4) == Math.Vector4f(1.0, 2.0, 3.5, 4.0)
            @test Math.Vector4f(1, 2, 3, 4.5) == Math.Vector4f(1.0, 2.0, 3.0, 4.5)
        end

        @testset "Vector4f addition" begin
            vec1 = Math.Vector4f(1.0, 2.0, 3.0, 4.0)
            vec2 = Math.Vector4f(5.0, 6.0, 7.0, 8.0)
            @test vec1 + vec2 == Math.Vector4f(6.0, 8.0, 10.0, 12.0)
            @test vec1 + 2 == Math.Vector4f(3.0, 4.0, 5.0, 6.0)
            @test vec1 + 2.0 == Math.Vector4f(3.0, 4.0, 5.0, 6.0)
            @test 2 + vec1 == Math.Vector4f(3.0, 4.0, 5.0, 6.0)
            @test 2.0 + vec1 == Math.Vector4f(3.0, 4.0, 5.0, 6.0)
        end

        @testset "Vector4f subtraction" begin
            vec1 = Math.Vector4f(1.0, 2.0, 3.0, 4.0)
            vec2 = Math.Vector4f(5.0, 6.0, 7.0, 8.0)
            @test vec1 - vec2 == Math.Vector4f(-4.0, -4.0, -4.0, -4.0)
            @test vec1 - 2 == Math.Vector4f(-1.0, 0.0, 1.0, 2.0)
            @test vec1 - 2.0 == Math.Vector4f(-1.0, 0.0, 1.0, 2.0)
            @test 2 - vec1 == Math.Vector4f(1.0, 0.0, -1.0, -2.0)
            @test 2.0 - vec1 == Math.Vector4f(1.0, 0.0, -1.0, -2.0)
        end

        @testset "Vector4f multiplication" begin
            vec1 = Math.Vector4f(1.0, 2.0, 3.0, 4.0)
            vec2 = Math.Vector4f(5.0, 6.0, 7.0, 8.0)
            int = 2
            float = 1.5
            
            @testset "Vector4f and Vector4f multiplication" begin
                @test vec1 * vec2 == Math.Vector4f(5.0, 12.0, 21.0, 32.0)
            end

            @testset "Vector4f and Int32 multiplication" begin
                @test vec1 * int == Math.Vector4f(2.0, 4.0, 6.0, 8.0)
            end

            @testset "Vector4f and Float64 multiplication" begin
                @test vec1 * float == Math.Vector4f(1.5, 3.0, 4.5, 6.0)
            end

            @testset "Float64 and Vector4f multiplication" begin
                @test float * vec1 == Math.Vector4f(1.5, 3.0, 4.5, 6.0)
            end
        end

        @testset "Vector4f division" begin
            vec1 = Math.Vector4f(6.0, 8.0, 10.0, 12.0)
            float = 2.0
            @test vec1 / 2 == Math.Vector4f(3.0, 4.0, 5.0, 6.0)
            @test vec1 / 2.0 == Math.Vector4f(3.0, 4.0, 5.0, 6.0)
        end
    end
end
