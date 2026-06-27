package cangjie_test_demo

import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MainTest {
    @TestCase
    public func test_success(): Unit {
        @Assert(true)
    }
}